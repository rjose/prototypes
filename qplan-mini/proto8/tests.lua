local LuaUnit = require('luaunit')
local Reader = require('reader')

TestReader = {}

function TestReader:test_readPlan()
	local plans = Reader.read_plans("plan.txt")
	local expected_work_items = {"2", "1"}

	assertEquals(#plans, 1)
	for i = 1,#expected_work_items do
		assertEquals(plans[1].work_items[i], expected_work_items[i])
	end
end

function TestReader:test_readWork()
	local expected_names = {"Do work item 1", "Do work item 2"}
	local work = Reader.read_work("work.txt")

	assertEquals(#work, 2)
	for i = 1,#expected_names do
		assertEquals(work[i].name, expected_names[i])
	end

	local estimates = work[1]:week_estimates()
	assertEquals(estimates["Web"], 2)
end


LuaUnit:run()
