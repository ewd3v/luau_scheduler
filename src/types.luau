export type Node = System | Group

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

	callback: SystemCallback,
}, SystemImpl>

export type SystemImpl = {
	__index: SystemImpl,

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
