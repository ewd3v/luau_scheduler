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

local group = {} :: GroupImpl
group.__index = group

group.Before = node.insertBefore :: any
group.After = node.insertAfter :: any
group.In = node.insertIn :: any
group.Resolve = node.resolve :: any
group.SetEnabled = node.setEnabled

function group.Add(self: Group, child: Node)
	if not (child.parent == nil) then
		error(`{child.name} already belongs to a group ({node.getNodeDebugPathName(child.parent)}).`, 2)
	end

	child.parent = self
	table.insert(self._children, child)
	markChildrenOrderDirty(self)
end

function group.Remove(self: Group, child: Node)
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

function group.Run(self: Group, dt: number)
	if not self.enabled then
		return
	end

	for _, callback in self:GetFlattened() do
		callback(dt)
	end
end

function group.GetChildren(self: Group): { Node }
	if self._childrenOrderDirty then
		sortChildren(self)
	end

	return self._children
end

function group.GetFlattened(self: Group): { SystemCallback }
	if self._flattenedDirty then
		rebuildFlattened(self)
	end

	return self._flattened
end

local function newGroup(name: string): Group
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
	}, group) :: any
end

return table.freeze({
	new = newGroup,
})
