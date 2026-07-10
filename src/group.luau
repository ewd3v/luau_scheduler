--[=[
	@class Group
	@tag Class
]=]

local node = require("./node")
local types = require("./types")

type Node = types.Node
type Group = types.Group
type GroupImpl = types.GroupImpl
type SystemCallback = types.SystemCallback

local markChildrenOrderDirty = node.markChildrenOrderDirty

local function getStuck(children: { Node }, inDegree: { [Node]: number }): { string }
	local stuck = {}
	for _, child in children do
		if not (inDegree[child] > 0) then
			continue
		end

		table.insert(stuck, child.name)
	end

	return stuck
end

-- Kahn's algorithm
local function sortChildren(group: Group)
	local children = group._children
	local inDegree: { [Node]: number } = {}
	local queue: { Node } = {}
	local sorted: { Node } = {}

	for _, child in children do
		inDegree[child] = 0
	end

	for _, child in children do
		for depenency in child._dependencies do
			if inDegree[depenency] == nil then
				continue
			end

			inDegree[child] += 1
		end
	end

	for _, child in children do
		if inDegree[child] == 0 then
			table.insert(queue, child)
		end
	end

	local head = 1
	while head <= #queue do
		local headNode = queue[head]
		head += 1

		table.insert(sorted, headNode)

		for dependent in headNode._dependents do
			local degree = inDegree[dependent]
			if degree == nil then
				continue
			end

			degree -= 1
			inDegree[dependent] = degree
			if degree > 0 then
				continue
			end

			table.insert(queue, dependent)
		end
	end

	if #sorted ~= #children then
		local stuck = getStuck(children, inDegree)
		error(
			`cyclic dependency in group {node.getNodeDebugPathName(group)} among these children: {table.concat(
				stuck,
				", "
			)}`
		)
	end

	group._children = sorted
	group._childrenOrderDirty = false
end

local function rebuildFlattened(group: Group)
	local flattened = {}

	for _, child in group:GetChildren() do
		if not child.enabled then
			continue
		end

		if child.kind == "System" then
			table.insert(flattened, child.callback)
		elseif child.kind == "Group" then
			local childFlattened = child:GetFlattened()
			table.move(childFlattened, 1, #childFlattened, #flattened + 1, flattened)
		end
	end

	group._flattened = flattened
	group._flattenedDirty = false
end

local Group = {} :: GroupImpl
Group.__index = Group

function Group.new(name: string): Group
	--[=[
		@within Group
		@readonly

		@prop kind "Group"
	]=]

	--[=[
		@within Group
		@private

		@prop _children { Node }
	]=]

	--[=[
		@within Group
		@private

		@prop _flattened { SystemCallback }
	]=]

	--[=[
		@within Group
		@private

		While true, [_children](Group#_children) needs to be sorted.
		[Group:GetChildren] will automatically resolve this.

		@prop _childrenOrderDirty boolean
	]=]

	--[=[
		@within Group
		@private

		While true, [_flattened](Group#_flattened) is not longer accurate and needs to be rebuilt.
		[Group:GetFlattened] will automatically resolve this.

		@prop _flattenedDirty boolean
	]=]

	return setmetatable({
		kind = "Group",

		_children = {},
		_flattened = {},
		_childrenOrderDirty = false,
		_flattenedDirty = false,

		-- NodeBase
		name = name,
		parent = nil,
		enabled = true,
		_dependencies = {},
		_dependents = {},
	}, Group) :: any
end

--[=[
	@within Group

	A reference to [node.insertBefore].

	@method Before
	@param self Group
	@param dependent Node
	@return Group
]=]
Group.Before = node.insertBefore :: any

--[=[
	@within Group

	A reference to [node.insertAfter].

	@method After
	@param self Group
	@param dependency Node
	@return Group
]=]
Group.After = node.insertAfter :: any

--[=[
	@within Group

	A reference to [node.insertIn].

	@method In
	@param self Group
	@param parent Group
	@return Group
]=]
Group.In = node.insertIn :: any

--[=[
	@within Group

	A reference to [node.resolve].

	@method Resolve
	@param self Group
	@return Group
]=]
Group.Resolve = node.resolve :: any

--[=[
	@within Group

	A reference to [node.setEnabled].

	@method SetEnabled
	@param self Group
	@param enabled boolean
]=]
Group.SetEnabled = node.setEnabled

--[=[
	@within Group

	Adds the given [Node] to this group.

	@method Add
	@param child Node
]=]
function Group.Add(self: Group, child: Node)
	if not (child.parent == nil) then
		error(`{child.name} already belongs to a group ({node.getNodeDebugPathName(child.parent)}).`, 2)
	end

	child.parent = self
	table.insert(self._children, child)
	markChildrenOrderDirty(self)
end

--[=[
	@within Group

	Removes the given [Node] from this group.

	@method Remove
	@param child Node
]=]
function Group.Remove(self: Group, child: Node)
	local index = table.find(self._children, child)
	if index == nil then
		return
	end

	child.parent = nil
	table.remove(self._children, index)

	for dependent in child._dependents do
		dependent._dependencies[child] = nil
	end
	table.clear(child._dependents)

	for dependency in child._dependencies do
		dependency._dependents[child] = nil
	end
	table.clear(child._dependencies)

	markChildrenOrderDirty(self)
end

--[=[
	@within Group

	Runs all descendant [systems](System) in their sorted order.

	@method Run
	@param dt number
]=]
function Group.Run(self: Group, dt: number)
	if not self.enabled then
		return
	end

	for _, callback in self:GetFlattened() do
		callback(dt)
	end
end

--[=[
	@within Group

	Returns a sorted list of this group's children.

	@method GetChildren
	@return { Node }
]=]
function Group.GetChildren(self: Group): { Node }
	if self._childrenOrderDirty then
		sortChildren(self)
	end

	return self._children
end

--[=[
	@within Group

	Returns a sorted list of all descendant [system callbacks](System#callback).
	This is the list that [Group:Run] iterates over.

	@method GetFlattened
	@return { SystemCallback }
]=]
function Group.GetFlattened(self: Group): { SystemCallback }
	if self._flattenedDirty then
		rebuildFlattened(self)
	end

	return self._flattened
end

return table.freeze(Group)
