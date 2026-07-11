---
sidebar_position: 3
---

# Hierarchy

## Groups

You can assign a system to a group via group:Add(), and when that group runs, so does all systems assigned to it.
```lua
local scheduler = require(path.to.scheduler)

local mySystem = scheduler.newSystem("system", function()
    print("Hello from mySystem!")
end)

local myGroup = scheduler.newGroup("group")
myGroup:Add(mySystem)
myGroup:Run(0) --> Hello from mySystem!
```

However most of the time you'll probably want a system assigning itself to a group, instead of what we did above.
This is trivial with the [Node:In()](/api/node#insertIn) method.

```lua
local myGroup = scheduler.newGroup("group")

local function step()
    print("Hello from mySystem")
end
scheduler.newSystem("system", step):In(myGroup)

myGroup:Run(0) --> Hello from mySystem!
```

You can even assign groups to other groups.

```lua
local group1 = scheduler.newGroup("group1")
local group2 = scheduler.newGroup("group2"):In(group1)

local function step()
    print("Hello from mySystem")
end
scheduler.newSystem("system", step):In(group2)

group1:Run(0) --> Hello from mySystem!
```

:::tip

Node:In() returns the node on which :In() was called on, which makes chaining possible.

:::
