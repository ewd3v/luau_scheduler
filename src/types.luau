export type Node = System | Group

--[=[
	@within Group

	The name of this node.

	@prop name string
]=]
--[=[
	@within System

	The name of this node.

	@prop name string
]=]

--[=[
	@within Group

	What [Group] this node belongs to. When the parent runs, this node also runs (with the proper order).

	@prop parent Group?
]=]
--[=[
	@within System

	What [Group] this node belongs to. When the parent runs, this node also runs (with the proper order).

	@prop parent Group?
]=]

--[=[
	@within Group

	If the node is enabled or not. While disabled, this node won't run itself or any of it's children.

	@prop enabled boolean
]=]
--[=[
	@within System

	If the node is enabled or not. While disabled, this node won't run itself or any of it's children.

	@prop enabled boolean
]=]

--[=[
	@within Group
	@private

	A set of [Nodes](Node) that should run before this one.

	@prop _dependencies { [Node]: true }
]=]
--[=[
	@within System
	@private

	A set of [Nodes](Node) that should run before this one.

	@prop _dependencies { [Node]: true }
]=]

--[=[
	@within Group
	@private

	A set of [Nodes](Node) that should run after this one.

	@prop _dependents { [Node]: true }
]=]
--[=[
	@within System
	@private

	A set of [Nodes](Node) that should run after this one.

	@prop _dependents { [Node]: true }
]=]

type NodeBase = {
	name: string,
	parent: Group?,
	enabled: boolean,
	_dependencies: { [Node]: true },
	_dependents: { [Node]: true },
}

export type SystemCallback = (dt: number) -> ()

export type System = setmetatable<NodeBase & {
	read kind: "System",

	read callback: SystemCallback,
}, SystemImpl>

export type SystemImpl = {
	__index: SystemImpl,

	new: (name: string, callback: SystemCallback) -> System,

	Run: (self: System, dt: number) -> (),

	-- NodeBase
	Before: (self: System, dependent: Node) -> System,
	After: (self: System, dependency: Node) -> System,
	In: (self: System, parent: Group) -> System,
	Resolve: (self: System) -> System,
	SetEnabled: (self: Node, enabled: boolean) -> (),
}

export type Group = setmetatable<NodeBase & {
	read kind: "Group",

	_children: { Node },
	_flattened: { SystemCallback },
	_childrenOrderDirty: boolean,
	_flattenedDirty: boolean,
}, GroupImpl>

export type GroupImpl = {
	__index: GroupImpl,

	new: (name: string) -> Group,

	Add: (self: Group, child: Node) -> (),
	Remove: (self: Group, child: Node) -> (),
	Run: (self: Group, dt: number) -> (),
	GetChildren: (self: Group) -> { Node },
	GetFlattened: (self: Group) -> { SystemCallback },

	-- NodeBase
	Before: (self: Group, dependency: Node) -> Group,
	After: (self: Group, dependent: Node) -> Group,
	In: (self: Group, parent: Group) -> Group,
	Resolve: (self: Group) -> Group,
	SetEnabled: (self: Node, enabled: boolean) -> (),
}

return nil
