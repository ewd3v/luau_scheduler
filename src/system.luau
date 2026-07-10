local node = require("./node")
local types = require("./types")

type System = types.System
type SystemImpl = types.SystemImpl
type SystemCallback = types.SystemCallback

local System = {} :: SystemImpl
System.__index = System

function System.new(name: string, callback: SystemCallback): System
	return setmetatable({
		kind = "System",

		callback = callback,

		-- NodeBase
		name = name,
		parent = nil,
		enabled = true,
		_dependencies = {},
		_dependents = {},
	}, System) :: any
end

System.Before = node.insertBefore :: any
System.After = node.insertAfter :: any
System.In = node.insertIn :: any
System.Resolve = node.resolve :: any
System.SetEnabled = node.setEnabled

function System.Run(self: System, dt: number)
	if not self.enabled then
		return
	end

	self.callback(dt)
end

return table.freeze(System)
