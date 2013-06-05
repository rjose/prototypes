local LuaUnit = require('luaunit')
local Work = require("work")
local Plan = require("plan")

tmp_plan = Plan.new("MobileQ3", 13, 1, {})
for i = 1, 10 do
        tmp_plan:add_work_item("Item #" .. i, "Track1")
end

--
-- Work estimate parsing
--
TestWorkEstimateParse = {}
function TestWorkEstimateParse:setUp()
        self.work = {}
        self.work[1] = Work.new{name = "Do work item 1",
                                track = "Track1",
                                estimates = {["Native"] = "2L",
                                           ["Web"] = "M",
                                           ["Server"] = "Q",
                                           ["BB"] = "S"}}

        -- Add a few more work items
        for i = 2, 4 do
                self.work[i] = Work.new{name = "Task" .. i,
                                track = "Track1",
                                estimates = {["Native"] = "L",
                                           ["Web"] = i .. "M",
                                           ["Server"] = "Q",
                                           ["BB"] = "S"}}
        end

end

function TestWorkEstimateParse:test_estimateString()
        assertEquals(self.work[1].estimates["Native"], "2L")
end

function TestWorkEstimateParse:test_weekEstimates()
        local week_estimates = self.work[1]:week_estimates()
        local expected = {["Native"] = 8, ["Web"] = 2,
                          ["Server"] = 13, ["BB"] = 1}
        for skill, estimate in pairs(expected) do
                assertEquals(week_estimates[skill], expected[skill])
        end
end

function TestWorkEstimateParse:test_estimateParsing()
        assertEquals(Work.estimate_to_weeks("S"), 1)
        assertEquals(Work.estimate_to_weeks("M"), 2)
        assertEquals(Work.estimate_to_weeks("L"), 4)
        assertEquals(Work.estimate_to_weeks("Q"), 13)
        assertEquals(Work.estimate_to_weeks("3L"), 12)
        assertEquals(Work.estimate_to_weeks("2Q"), 26)
end

function TestWorkEstimateParse:test_sumWorkEstimates()
        -- Try just a single item
        local sum1 = Work.sum_estimates({self.work[1]})
        local expected1 = {["Native"] = 8, ["Web"] = 2,
                          ["Server"] = 13, ["BB"] = 1}
        for skill, estimate in pairs(expected1) do
                assertEquals(sum1[skill], expected1[skill])
        end

        -- Try a bunch of items
        local expected2 = {["Native"] = 8+12, ["Web"] = 2+4+6+8,
                          ["Server"] = 13+39, ["BB"] = 1+3}
        local sum2 = Work.sum_estimates(self.work)
        for skill, estimate in pairs(expected1) do
                assertEquals(sum2[skill], expected2[skill])
        end

end

LuaUnit:run()
