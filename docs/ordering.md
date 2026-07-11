---
sidebar_position: 4
---

# Ordering

This library makes no ordering guarantee by default. When a group is ran, its children may run in any arbitrary order.

The library does however provide methods so you can guarantee that a node will run before or after another node.

## Before & After

You can use [Node:Before()](/api/node#insertBefore) to make a node run before another node.

```lua
local scheduler = require(path.to.scheduler)
local function wrapPrint(msg)
    return function()
        print(msg)
    end
end

local root = scheduler.newGroup("root")
local node1 = scheduler.newSystem("node1", wrapPrint("node1 ran!")):In(root)
local node2 = scheduler.newSystem("node2", wrapPrint("node2 ran!")):In(root)

node2:Before(node1)
root:Run(0)
--> node2 ran!
--> node1 ran!
```

And likewise, you can use [Node:After()](/api/node#insertAfter) to make a node run after another one.

```lua
local root = scheduler.newGroup("root")
local node1 = scheduler.newSystem("node1", wrapPrint("node1 ran!")):In(root)
local node2 = scheduler.newSystem("node2", wrapPrint("node2 ran!")):In(root)

node2:After(node1)
root:Run(0)
--> node1 ran!
--> node2 ran!
```

:::tip

You can chain :Before() & :After() with :In():

```lua
local node2 = scheduler.newSystem(...):In(root):Before(node1)
local node3 = scheduler.newSystem(...):In(root):After(node1)
```

:::

:::danger

:Before() & :After() require the two nodes to share the same parent.

:::

## Implicit parenting

As stated above, in order to use :Before() & :After() between two nodes, they need to be assigned to the same group.
However you may find yourself making a system where you don't really care what group it's in, and just want it to run before or after another system.

When you use :Before() or :After() on a node that's missing a parent, it will automatically get assigned to the other node's parent.

```lua
local heartbeat = scheduler.newGroup("Heartbeat")

local updatePosition = scheduler.newSystem("updatePosition", ...):In(heartbeat)
local updateVelocity = scheduler.newSystem("updateVelocity", ...):Before(updatePosition)
-- updateVelocity will automatically be assigned to the heartbeat group
```

:::warning

In order for implicit parenting to work, the targeted node in :Before() / :After() needs to already have a parent set.

Support for assigning parent at a later point will be explored in a future version.

:::
