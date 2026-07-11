---
sidebar_position: 1
---

# Introduction

This is a scheduler library for [Luau](https://luau.org/), which can help you organize systems (functions) an easily define in what order you'd like to run them in. If you're using an [ECS](https://devforum.roblox.com/t/all-about-entity-component-system/1664447) you may find this useful for ordering your systems.

It's hierarchical, meaning you work with nodes, which have one parent, and can have multiple children. So called tree structures.
And it's dependency-sorted, meaning you can assign dependencies to nodes to easily define the order you'd like them to run in.

There's two types of nodes that you can work with, [Groups](/api/Group) and [Systems](/api/System):
- Groups act as organizational containers and can contain multiple other groups or systems.
- Systems store a reference to a function that should be called whenever the node runs. Systems are always leaf nodes and can't contain any children.

While it is possible to combine the two into a single node class, this design avoids working around the issue whether a group's callback should run before or after it's children. If you want logic to run before or after the group, just make a system and insert it before / after the group instead. Having two types is also more legible. A group is a pure ordering scope, without any behavior of its own. And a system is a unit of behaviour with no children.
