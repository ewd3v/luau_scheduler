local test = require("@std/test")
local testTypes = require("@std/test/types")

local scheduler = require("../src")

local function testNewNode(assert: testTypes.Asserts, node: scheduler.Node)
	assert.that(next(node.dependencies) == nil)
	assert.that(next(node.dependents) == nil)
end

local systemName, systemCallback = "test", function() end
local groupName = "test"

local function newSystem(name: string?, callback: scheduler.SystemCallback?): scheduler.System
	return scheduler.newSystem(name or systemName, callback or systemCallback)
end

local function newGroup(name: string?): scheduler.Group
	return scheduler.newGroup(name or groupName)
end

test.suite("system", function(suite)
	suite:case("new", function(assert)
		local system = newSystem()
		assert.that(system ~= nil)
		assert.eq(system.callback, systemCallback)
		assert.eq(system.enabled, true)
		assert.eq(system.name, systemName)
		assert.eq(system.parent, nil)
		testNewNode(assert, system)
	end)

	suite:case("runs", function(assert)
		local ran = false
		local system = newSystem(nil, function()
			ran = true
		end)

		system:Run(0)
		assert.eq(ran, true)
	end)
end)

test.suite("group", function(suite)
	suite:case("new", function(assert)
		local group = newGroup()
		assert.that(group ~= nil)
		assert.eq(#group.children, 0)
		assert.eq(#group.flattened, 0)
		assert.eq(group.childrenOrderDirty, false)
		assert.eq(group.flattenedDirty, false)
		assert.eq(group.enabled, true)
		assert.eq(group.name, groupName)
		assert.eq(group.parent, nil)
		testNewNode(assert, group)
	end)
end)

test.suite("hierarchy", function(suite)
	suite:case("parent (parent:Add())", function(assert)
		local parent = newGroup()
		local node = newSystem()
		parent:Add(node)
		assert.eq(node.parent, parent)
	end)

	suite:case("parent (child:In())", function(assert)
		local parent = newGroup()
		local node = newSystem():In(parent)
		assert.eq(node.parent, parent)
	end)

	suite:case("parenting adds to children", function(assert)
		local parent = newGroup()
		newSystem():In(parent)
		assert.eq(#parent.children, 1)
	end)

	suite:case("can't parent already parented", function(assert)
		assert.throws(function()
			newSystem():In(newGroup()):In(newGroup())
		end)
	end)

	suite:case("implicit parent (child:Before())", function(assert)
		local parent = newGroup()
		local dependent = newSystem():In(parent)
		local node = newSystem():Before(dependent)
		assert.eq(node.parent, dependent.parent)
	end)

	suite:case("implicit parent (child:After())", function(assert)
		local parent = newGroup()
		local dependency = newSystem():In(parent)
		local node = newSystem():After(dependency)
		assert.eq(node.parent, dependency.parent)
	end)

	suite:case("can't implicitly parent orphans", function(assert)
		assert.throws(function()
			newSystem():Before(newSystem())
		end)
	end)

	suite:case("runs children", function(assert)
		local ran = 0
		local function counter()
			ran += 1
		end

		local parent = newGroup()
		newSystem(nil, counter):In(parent)
		newSystem(nil, counter):In(parent)
		newSystem(nil, counter):In(parent)

		parent:Run(0)
		assert.eq(ran, 3)
	end)

	suite:case("runs descendants", function(assert)
		local ran = 0
		local function counter()
			ran += 1
		end

		local parent = newGroup()
		newSystem(nil, counter):In(parent)

		local child1 = newGroup():In(parent)
		newSystem(nil, counter):In(child1)

		local child1_1 = newGroup():In(child1)
		newSystem(nil, counter):In(child1_1)

		local child2 = newGroup():In(parent)
		newSystem(nil, counter):In(child1)

		local child2_1 = newGroup():In(child2)
		newSystem(nil, counter):In(child2_1)

		parent:Run(0)
		assert.eq(ran, 5)
	end)
end)

test.suite("order", function(suite)
	suite:case("detects cyclic dependencies", function(assert)
		local root = newGroup()
		local node1 = newSystem():In(root)
		local node2 = newSystem():In(root)

		node1:After(node2)
		node2:After(node1)

		assert.throws(function()
			root:Run(0)
		end)
	end)

	local function wrapInsert(str: string, list: { string })
		return function()
			table.insert(list, str)
		end
	end

	suite:case("before", function(assert)
		local order = {}

		local group = newGroup()
		local node1 = newSystem(nil, wrapInsert("node1", order)):In(group)
		newSystem(nil, wrapInsert("node2", order)):In(group):Before(node1)

		group:Run(0)

		assert.eq(order[1], "node2")
		assert.eq(order[2], "node1")
	end)

	suite:case("after", function(assert)
		local order = {}

		local group = newGroup()
		local node1 = newSystem(nil, wrapInsert("node1", order)):In(group)
		newSystem(nil, wrapInsert("node2", order)):In(group):After(node1)

		group:Run(0)

		assert.eq(order[1], "node1")
		assert.eq(order[2], "node2")
	end)

	suite:case("before & after", function(assert)
		local order = {}

		local group = newGroup()
		local node1 = newSystem(nil, wrapInsert("node1", order)):In(group)
		local node2 = newSystem(nil, wrapInsert("node2", order)):In(group)
		newSystem(nil, wrapInsert("node3", order)):In(group):After(node1):Before(node2)

		group:Run(0)

		assert.eq(order[1], "node1")
		assert.eq(order[2], "node3")
		assert.eq(order[3], "node2")
	end)

	suite:case("complex", function(assert)
		local order = {}

		local group = newGroup()
		local node1 = newSystem(nil, wrapInsert("node1", order)):In(group)
		local node2 = newSystem(nil, wrapInsert("node2", order)):In(group)
		local node3 = newSystem(nil, wrapInsert("node3", order)):In(group):After(node1):Before(node2)
		local node4 = newSystem(nil, wrapInsert("node4", order)):In(group):After(node1):Before(node2)
		newSystem(nil, wrapInsert("node5", order)):In(group):After(node3):Before(node4)

		group:Run(0)

		assert.eq(order[1], "node1")
		assert.eq(order[2], "node3")
		assert.eq(order[3], "node5")
		assert.eq(order[4], "node4")
		assert.eq(order[5], "node2")
	end)

	suite:case("node before group", function(assert)
		local order = {}

		local root = newGroup()
		local group1 = newGroup():In(root)
		newSystem(nil, wrapInsert("node1", order)):In(group1)
		newSystem(nil, wrapInsert("node2", order)):In(root):Before(group1)

		root:Run(0)

		assert.eq(order[1], "node2")
		assert.eq(order[2], "node1")
	end)

	suite:case("node after group", function(assert)
		local order = {}

		local root = newGroup()
		local group1 = newGroup():In(root)
		newSystem(nil, wrapInsert("node1", order)):In(group1)
		newSystem(nil, wrapInsert("node2", order)):In(root):After(group1)

		root:Run(0)

		assert.eq(order[1], "node1")
		assert.eq(order[2], "node2")
	end)

	suite:case("group before group", function(assert)
		local order = {}

		local root = newGroup()
		local group1 = newGroup():In(root)
		newSystem(nil, wrapInsert("node1", order)):In(group1)
		local group2 = newGroup():In(root):Before(group1)
		newSystem(nil, wrapInsert("node2", order)):In(group2)

		root:Run(0)

		assert.eq(order[1], "node2")
		assert.eq(order[2], "node1")
	end)

	suite:case("group after group", function(assert)
		local order = {}
		local root = newGroup()
		local group1 = newGroup():In(root)
		newSystem(nil, wrapInsert("node1", order)):In(group1)
		local group2 = newGroup():In(root):After(group1)
		newSystem(nil, wrapInsert("node2", order)):In(group2)

		root:Run(0)

		assert.eq(order[1], "node1")
		assert.eq(order[2], "node2")
	end)
end)
