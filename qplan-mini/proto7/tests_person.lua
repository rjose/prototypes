local LuaUnit = require('luaunit')
local Person = require('person')

TestPerson = {}

function TestPerson:setUp()
	self.person = Person.new{
		name = "P1",
		skills = {["Native"] = 0.8, ["Apps"] = 0.2}
	}
end

function TestPerson:test_getSkillAvailability()
	local expected = {
		["Native"] = 0.8*13, ["Apps"] = 0.2*13
	}
	local avail = self.person:get_skill_avail(13)

	for skill, val in pairs(expected) do
		assertEquals(avail[skill], val)
	end
end


LuaUnit:run()

