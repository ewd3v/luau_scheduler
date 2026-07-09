local node = require("./node")
local types = require("./types")

type System = types.System
type SystemImpl = types.SystemImpl
type SystemCallback = types.SystemCallback

local system = {} :: SystemImpl
system.__index = system

system.Before = node.before :: any
system.After = node.after :: any
system.SetEnabled = node.setEnabled

function system.Run(self: System, dt: number)
	if not self.enabled then
		return
	end

	self.callback(dt)
end

local function newSystem(name: string, callback: SystemCallback): System
	return setmetatable({
		kind = "System",

		callback = callback,

		-- NodeBase
		name = name,
		parent = nil,
		enabled = true,
		dependencies = {},
		dependents = {},
	}, system) :: any
end

return table.freeze({
	new = newSystem,
})
