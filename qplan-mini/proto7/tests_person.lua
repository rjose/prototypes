local LuaUnit = require('luaunit')
local Person = require('person')

TestPerson = {}

function TestPerson:setUp()
	self.person = Person.new{
		name = "P1",
		skills = {["Native"] = 0.8, ["Apps"] = 0.2}
	}
end

function check_skill_avail(actual, expected)
	for skill, val in pairs(expected) do
		assertEquals(actual[skill], val)
	end
end

function TestPerson:test_getSkillAvailability()
	local expected = {
		["Native"] = 0.8*13, ["Apps"] = 0.2*13
	}
	local avail = self.person:get_skill_avail(13)
	check_skill_avail(avail, expected)
end

function TestPerson:test_sumSkillAvail1()
	local expected = {
		["Native"] = 0.8*13, ["Apps"] = 0.2*13
	}
	local avail = Person.sum_skill_avail({self.person}, 13)
	check_skill_avail(avail, expected)
end

function TestPerson:test_sumSkillAvail2()
	local expected = {
		["Native"] = 2*0.8*13, ["Apps"] = 2*0.2*13
	}
	local avail = Person.sum_skill_avail({self.person, self.person}, 13)
	check_skill_avail(avail, expected)
end

LuaUnit:run()

