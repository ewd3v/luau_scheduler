--[=[
	@class node
]=]

--[=[
	@within node
	@type Node System | Group
]=]

local types = require("./types")

type Node = types.Node
type Group = types.Group

--[=[
	@within node
	@private
]=]
local function markAncestorsFlattenedDirty(group: Group)
	local ancestor = group
	while ancestor ~= nil do
		ancestor._flattenedDirty = true
		ancestor = ancestor.parent
	end
end

--[=[
	@within node
	@private
]=]
local function markChildrenOrderDirty(group: Group)
	group._childrenOrderDirty = true
	markAncestorsFlattenedDirty(group)
end

--[=[
	@within node

	Returns a debug name for the given node that show's it's name and the name of all its ancestors.
	If the node is nil it returns "(nil)" instead.
]=]
local function getNodeDebugPathName(node: Node?): string
	if node == nil then
		return "(nil)"
	end

	local path = node.name
	local current = node.parent
	while current ~= nil do
		path = `{current.name}/{path}`
	end

	return path
end

local function getInvalidSiblingMessage(nodeA: Node, nodeB: Node): string
	return `{nodeA.name} and {nodeB.name} need to share the same parent to be ordered relative to each other. Current parents:`
		.. `\n{nodeA.name}: {getNodeDebugPathName(nodeA.parent)}`
		.. `\n{nodeB.name}: {getNodeDebugPathName(nodeB.parent)}`
end

local function resolveNodeParent(node: Node, sibling: Node): Group
	if node.parent == nil and sibling.parent ~= nil then
		sibling.parent:Add(node)
	end

	if not (node.parent ~= nil and node.parent == sibling.parent) then
		error(getInvalidSiblingMessage(node, sibling), 2)
	end

	return node.parent
end

--[=[
	@within node

	Inserts the given [Node] before another one, guaranteeing that it'll be called before the other node when their parent [Group] runs.
	If the given node doesn't have a parent, it'll implicitly set it to the other node's parent.

	Returns the given node to allow chaining.
]=]
local function insertBefore(node: Node, dependent: Node): Node
	local parent = resolveNodeParent(node, dependent)
	dependent._dependencies[node] = true
	node._dependents[dependent] = true
	markChildrenOrderDirty(parent)

	return node
end

--[=[
	@within node

	Inserts the given [Node] after another one, guaranteeing that it'll be called after the other node when their parent [Group] runs.
	If the given node doesn't have a parent, it'll implicitly set it to the other node's parent.

	Returns the given node to allow chaining.
]=]
local function insertAfter(node: Node, dependency: Node): Node
	local parent = resolveNodeParent(node, dependency)
	node._dependencies[dependency] = true
	dependency._dependents[node] = true
	markChildrenOrderDirty(parent)

	return node
end

--[=[
	@within node

	Sets the given [Node]'s parent to the given [Group].

	Returns the given node to allow chaining.
]=]
local function insertIn(node: Node, parent: Group): Node
	parent:Add(node)
	return node
end

--[=[
	@within node

	Resolves the given [Node], clearing any internal dirty flags.

	This ensures the given node won't have to do any extra work when running later.
	[Group:Run] automatically resolves any unresolved nodes.
]=]
local function resolve(node: Node): Node
	if node.kind == "Group" then
		node:GetFlattened()
	end

	return node
end

--[=[
	@within node

	Changes if the given [Node] should be enabled or not.
	When a node is disabled it and all of its descendants wont run.
]=]
local function setEnabled(node: Node, enabled: boolean)
	if node.enabled == enabled then
		return
	end

	node.enabled = enabled
	if node.parent ~= nil then
		markAncestorsFlattenedDirty(node.parent)
	end
end

return table.freeze({
	markAncestorsFlattenedDirty = markAncestorsFlattenedDirty,
	markChildrenOrderDirty = markChildrenOrderDirty,

	getNodeDebugPathName = getNodeDebugPathName,
	resolveNodeParent = resolveNodeParent,

	insertBefore = insertBefore,
	insertAfter = insertAfter,
	insertIn = insertIn,
	resolve = resolve,
	setEnabled = setEnabled,
})
