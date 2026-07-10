--[=[
	@class Scheduler
]=]

local types = require("@self/types")
export type Node = types.Node
export type System = types.System
export type SystemCallback = types.SystemCallback
export type Group = types.Group

--[=[
	@within Scheduler

	A reference to [Group.new].

	@function newGroup
	@param name string
	@return Group
]=]

--[=[
	@within Scheduler

	A reference to [System.new].

	@function newSystem
	@param name string
	@param callback (dt: number) -> ()
	@return System
]=]

--[=[
	@within Scheduler

	A reference to [node].

	@prop node node
]=]

return table.freeze({
	newGroup = require("@self/group").new,
	newSystem = require("@self/system").new,
	_node = require("@self/node"),
})
