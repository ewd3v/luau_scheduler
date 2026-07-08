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

local function before(node: Node, dependent: Node): Node
	if not (node.parent ~= nil and node.parent == dependent.parent) then
		error(getInvalidSiblingMessage(node, dependent), 2)
	end

	dependent.dependencies[node] = true
	node.dependents[dependent] = true

	markChildrenOrderDirty(node.parent)

	return node
end

local function after(node: Node, dependency: Node): Node
	if not (node.parent ~= nil and node.parent == dependency.parent) then
		error(getInvalidSiblingMessage(node, dependency), 2)
	end

	node.dependencies[dependency] = true
	dependency.dependents[node] = true

	markChildrenOrderDirty(node.parent)

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
	before = before,
	after = after,
	setEnabled = setEnabled,
})
