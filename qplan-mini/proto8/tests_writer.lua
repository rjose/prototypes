local LuaUnit = require('luaunit')

local Work = require("work")
local Plan = require("plan")
local Reader = require("reader")

local Writer = require('writer')

TestWriter = {}

function TestWriter:setUp()
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

	self.plan = Plan.new{id = "4", name = "MobileQ3", cutline = 3,
	                     work_items = work_items
	}
end

function TestWriter:test_writePlan()
	Writer.write_plans({self.plan}, "plan_tmp.txt")

	-- Use Reader to test
	local plans = Reader.read_plans("plan_tmp.txt")
	local expected_work_items = {"1", "2", "3", "4", "5",
				     "6", "7", "8", "9", "10"
        }

	assertEquals(#plans, 1)
	for i = 1,#expected_work_items do
		assertEquals(plans[1].work_items[i], expected_work_items[i])
	end
end

LuaUnit:run()

