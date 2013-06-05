local LuaUnit = require('luaunit')
local Work = require("work")
local Plan = require("plan")


TestPlanFeasibility = {}

function TestPlanFeasibility:setUp()
	-- TODO: Make the work array *not* be global
	Work.work = {}
	self.plan = Plan.new{name = "MobileQ3", cutline = 3}
	for i = 1, 10 do
		self.plan:add_work_item("Item #" .. i, "Track1")
	end
end

function TestPlanFeasibility:test_workAboveCutline()
	local expected_ids = {1, 2, 3}
	local work_items = self.plan:get_work_above_cutline()

	for i, w in pairs(work_items) do
		assertEquals(expected_ids[i] .. "", w.id)
	end
end

LuaUnit:run()
