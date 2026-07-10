local types = require("./types")

type Node = types.Node
type Group = types.Group

local function markAncestorsFlattenedDirty(group: Group)
	local ancestor = group
	while ancestor ~= nil do
		ancestor.flattenedDirty = true
		ancestor = ancestor.parent
	end
end

local function markChildrenOrderDirty(group: Group)
	group.childrenOrderDirty = true
	markAncestorsFlattenedDirty(group)
end

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

local function insertBefore(node: Node, dependent: Node): Node
	local parent = resolveNodeParent(node, dependent)
	dependent.dependencies[node] = true
	node.dependents[dependent] = true
	markChildrenOrderDirty(parent)

	return node
end

local function insertAfter(node: Node, dependency: Node): Node
	local parent = resolveNodeParent(node, dependency)
	node.dependencies[dependency] = true
	dependency.dependents[node] = true
	markChildrenOrderDirty(parent)

	return node
end

local function insertIn(node: Node, parent: Group): Node
	parent:Add(node)
	return node
end

local function resolve(node: Node): Node
	if node.kind == "Group" then
		node:GetFlattened()
	end

	return node
end

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
