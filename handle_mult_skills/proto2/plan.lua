local mytable = require "mytable"

local Plan = {}

function Plan:_new(obj)
	obj = obj or {}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

--[
-- The keys into skill_distrib_override should be a person name. The value will
-- be a table of skill distributions (as what you'd find for a person)
--]
function Plan.new(num_weeks)
	result = Plan:_new{num_weeks = num_weeks, skill_distrib_override = {} }
	return result
end


function Plan:add_people(people)
	self.people = people
end

function Plan:override_skill_distrib(person, skill_distrib)
	self.skill_distrib_override[person.name] = skill_distrib
end

function Plan:get_skill_distrib(person)
	if self.skill_distrib_override[person.name] then
		return self.skill_distrib_override[person.name]
	else
		return person.skill_distrib
	end
end

function Plan:print_available_skills()
	print("Available skills")
	total_skills = {}
	-- Compute skill totals
	for _, p in pairs(self.people) do
		for skill, frac in pairs(self:get_skill_distrib(p)) do
			total = total_skills[skill] or 0
			total_skills[skill] = total + frac * self.num_weeks
		end
	end

	for skill, avail in pairs(total_skills) do
		print(string.format("%s: %f weeks-effort", skill, avail))
	end
end

function format_skill_assignment(person, skill_name)
	if mytable.table_length(person.skill_distrib) == 1 then
		return person.name
	else
		return string.format("%s (%.0f%%)", person.name, person.skill_distrib[skill_name]*100)
	end
end

function Plan:print_skill_assignments()
	print("Skill assignments")
	skill_assignments = {}
	for _, p in pairs(self.people) do
		for skill, frac in pairs(self:get_skill_distrib(p)) do
			skill_assignments[skill] = skill_assignments[skill] or {}
			table.insert(skill_assignments[skill], format_skill_assignment(p, skill))
		end
	end

	
	for skill, assignments in pairs(skill_assignments) do
		assignment_line = ""
		for i = 1, #assignments do
			assignment_line = assignment_line .. string.format("%s, ", assignments[i])
		end
		print(string.format("%s: %s", skill, string.sub(assignment_line, 1, #assignment_line-2)))
	end
end

return Plan
