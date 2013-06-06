local LuaUnit = require('luaunit')
local Skill = require('skill')

TestSkillsParse = {}

function TestSkillsParse:test_singleSkill()
	local skill = "Apps:1"
	local skill_table = Skill.parse_skill_string(skill)
	assertEquals(skill_table["Apps"], 1)
end

function TestSkillsParse:test_multSkill()
	local skill = "Apps:1,Server:0"
	local skill_table = Skill.parse_skill_string(skill)
	assertEquals(skill_table["Apps"], 1)
	assertEquals(skill_table["Server"], 0)
end

LuaUnit:run()
