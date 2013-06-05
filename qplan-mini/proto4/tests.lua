local Work = require("work")
local Plan = require("plan")
local LuaUnit = require('luaunit')

tmp_plan = Plan.new("MobileQ3", 13, 1, {})
for i = 1, 10 do
        tmp_plan:add_work_item("Item #" .. i, "Track1")
end

--
-- Plan Ranking tests
--
TestPlanRanking = {}
function TestPlanRanking:setUp()
        self.plan = Plan.new("Plan Ranking", 13, 5, {'1', '2', '3', '4', '5',
                                                     '6', '7', '8', '9', '10'})

end

function TestPlanRanking.check_rankings(ranked_items, expected_rankings)
        local ranked_string = ""
        local found_cutline = false
        for i = 1,#ranked_items do
                if ranked_items[i] == "CUTLINE" then
                        found_cutline = true
                else
                        ranked_string = ranked_string .. ranked_items[i].id
                end
        end

        local expected_string = ""
        for i = 1,#expected_rankings do
                expected_string = expected_string .. expected_rankings[i]
        end

        assertEquals(ranked_string, expected_string)
end

function TestPlanRanking:test_initialRankings()
        local expected_rankings = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
        local ranked_items = self.plan:get_ranked_work_items()
        TestPlanRanking.check_rankings(ranked_items, expected_rankings)
end

function TestPlanRanking:test_applyRanking1()
        local expected_rankings = {7, 8, 9, 1, 2, 3, 4, 5, 6, 10}
        self.plan:rank({7, 8, 9})
        local ranked_items = self.plan:get_ranked_work_items()
        TestPlanRanking.check_rankings(ranked_items, expected_rankings)
end

function TestPlanRanking:test_applyRanking2()
        local expected_rankings = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
        self.plan:rank({1, 2, 3})
        local ranked_items = self.plan:get_ranked_work_items()
        TestPlanRanking.check_rankings(ranked_items, expected_rankings)
end

function TestPlanRanking:test_applyRanking3()
        local expected_rankings = {7, 8, 9, 1, 2, 3, 4, 5, 6, 10}
        self.plan:rank({7, 8, 9})
        self.plan:rank({7, 8, 9})
        local ranked_items = self.plan:get_ranked_work_items()
        TestPlanRanking.check_rankings(ranked_items, expected_rankings)
end

function TestPlanRanking:test_applyRanking4()
        local expected_rankings = {1, 2, 3, 7, 8, 9, 4, 5, 6, 10}
        self.plan:rank({7, 8, 9}, {at = 4})
        local ranked_items = self.plan:get_ranked_work_items()
        TestPlanRanking.check_rankings(ranked_items, expected_rankings)
end

function TestPlanRanking:test_applyRanking5()
        local expected_rankings = {1, 3, 2, 7, 8, 9, 4, 5, 6, 10}
        self.plan:rank({7, 8, 9}, {at = 4})
        self.plan:rank({3, 2}, {at = 2})
        local ranked_items = self.plan:get_ranked_work_items()
        TestPlanRanking.check_rankings(ranked_items, expected_rankings)
end


LuaUnit:run('TestPlanRanking')
