local types = require("@self/types")
export type Node = types.Node
export type System = types.System
export type SystemCallback = types.SystemCallback
export type Group = types.Group

return table.freeze({
	newGroup = require("@self/group").new,
	newSystem = require("@self/system").new,
})
