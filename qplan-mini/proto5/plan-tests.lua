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

function TestPlanFeasibility:test_runningSkillsAvailableTotal()
	local skills = { ["Native"] = 10, ["Web"] = 8, ["BB"] = 3 }
	local expected = {
		{ ["Native"] = 6, ["Web"] = 6, ["BB"] = 2 },
		{ ["Native"] = 2, ["Web"] = 4, ["BB"] = 1 },
		{ ["Native"] = -2, ["Web"] = 2, ["BB"] = 0 }
	}
	-- TODO: Think of a better function name
	actual = Plan.get_running_skills_available(skills, self.plan:get_work_above_cutline())
	for i = 1,#expected do
		local expected_total = expected[i]
		for skill, avail in pairs(expected_total) do
			assertEquals(actual[i][skill], avail)
		end
	end
end

function TestPlanFeasibility:test_isFeasible()
	local skills = { ["Native"] = 10, ["Web"] = 8, ["BB"] = 3 }
	
	local is_feasible, avail_skills
	is_feasible, avail_skills = self.plan:is_feasible(skills)
	assertEquals(is_feasible, false)
	assertEquals(avail_skills, { ["Native"] = -2, ["Web"] = 2, ["BB"] = 0 })
end

LuaUnit:run()
