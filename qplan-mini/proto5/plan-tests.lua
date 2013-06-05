local LuaUnit = require('luaunit')
local Work = require("work")
local Plan = require("plan")


TestPlanFeasibility = {}

function TestPlanFeasibility:setUp()
	-- TODO: Make the work array *not* be global
	Work.work = {}
	local work_items = {}
        for i = 1, 10 do
                Work.work[i .. ""] = Work.new{id = i .. "", 
		                              name = "Task" .. i,
                                              track = "Track1",
                                              estimates = {["Native"] = "L",
                                                           ["Web"] = "M",
                                                           ["BB"] = "S"}
		}
		work_items[#work_items+1] = i .. ""
        end

	self.plan = Plan.new{name = "MobileQ3", cutline = 3,
	                     work_items = work_items
	}
end

function TestPlanFeasibility:test_workAboveCutline()
	local expected_ids = {1, 2, 3}
	local work_items = self.plan:get_work_above_cutline()

	for i = 1, #expected_ids do
		assertEquals(work_items[i].id, expected_ids[i] .. "")
	end

end

function TestPlanFeasibility:test_demandAboveCutline()
	local expected = { ["Native"] = 12, ["Web"] = 6, ["BB"] = 3 }
	local demand = self.plan:get_demand_above_cutline()

	for skill, weeks in pairs(expected) do
		assertEquals(demand[skill], expected[skill])
	end
end

LuaUnit:run()
