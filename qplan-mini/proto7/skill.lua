require('string_utils')

local Skill = {}


function Skill.parse_skill_string(skill_str)
	local result = {}

	-- First split on multiple skills
	skills = skill_str:split(",")
	for _, str in pairs(skills) do
		local skill, value = unpack(str:split(":"))
		result[skill] = value + 0
	end

	return result
end

return Skill
