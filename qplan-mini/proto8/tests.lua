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


LuaUnit:run()
