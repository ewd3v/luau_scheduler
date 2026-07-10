--[=[
	@class System
	@tag Class
]=]

local node = require("./node")
local types = require("./types")

type System = types.System
type SystemImpl = types.SystemImpl

--[=[
	@within System
	@type SystemCallback (dt: number) -> ()
]=]
type SystemCallback = types.SystemCallback

local System = {} :: SystemImpl
System.__index = System

--[=[
	Creates a new [System] with the given name and callback.
]=]
function System.new(name: string, callback: SystemCallback): System
	--[=[
		@within System
		@readonly

		@prop kind "System"
	]=]

	--[=[
		@within System
		@readonly

		The function that should be ran when this system runs.

		@prop callback SystemCallback
	]=]

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

--[=[
	@within System

	A reference to [node.insertBefore].

	@method Before
	@param self System
	@param dependent Node
	@return System
]=]
System.Before = node.insertBefore :: any

--[=[
	@within System

	A reference to [node.insertAfter].

	@method After
	@param self System
	@param dependency Node
	@return System
]=]
System.After = node.insertAfter :: any

--[=[
	@within System

	A reference to [node.insertIn].

	@method In
	@param self System
	@param parent Group
	@return System
]=]
System.In = node.insertIn :: any

--[=[
	@within System

	A reference to [node.resolve].

	@method Resolve
	@param self System
	@return System
]=]
System.Resolve = node.resolve :: any

--[=[
	@within System

	A reference to [node.setEnabled].

	@method SetEnabled
	@param self System
	@param enabled boolean
]=]
System.SetEnabled = node.setEnabled

--[=[
	@within System

	Calls [System.callback].

	@method Run
	@param dt number
]=]
function System.Run(self: System, dt: number)
	if not self.enabled then
		return
	end

	self.callback(dt)
end

return table.freeze(System)
