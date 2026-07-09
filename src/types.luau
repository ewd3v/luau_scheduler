export type Node = System | Group

type NodeBase = {
	name: string,
	parent: Group?,
	enabled: boolean,
	dependencies: { [Node]: true },
	dependents: { [Node]: true },
}

export type SystemCallback = (dt: number) -> ()

export type System = setmetatable<NodeBase & {
	kind: "System",

	callback: SystemCallback,
}, SystemImpl>

export type SystemImpl = {
	__index: SystemImpl,

	Run: (self: System, dt: number) -> (),

	-- NodeBase
	Before: (self: System, dependent: Node) -> System,
	After: (self: System, dependency: Node) -> System,
	SetEnabled: (self: Node, enabled: boolean) -> (),
}

export type Group = setmetatable<NodeBase & {
	kind: "Group",

	children: { Node },
	flattened: { SystemCallback },
	childrenOrderDirty: boolean,
	flattenedDirty: boolean,
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
	SetEnabled: (self: Node, enabled: boolean) -> (),
}

return nil
