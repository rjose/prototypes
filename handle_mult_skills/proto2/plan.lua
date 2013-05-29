local mytable = require "mytable"

local Plan = {}

--[
-- The keys into skill_distrib_override should be a person name. The value will
-- be a table of skill distributions (as what you'd find for a person)
--]
function Plan.new(num_weeks)
	result = {num_weeks = num_weeks, skill_distrib_override = {} }
	return result
end

function Plan.add_people(plan, people)
	plan.people = people
end

function Plan.override_skill_distrib(plan, person, skill_distrib)
	plan.skill_distrib_override[person.name] = skill_distrib
end

function Plan.get_skill_distrib(plan, person)
	if plan.skill_distrib_override[person.name] then
		return plan.skill_distrib_override[person.name]
	else
		return person.skill_distrib
	end
end

function Plan.print_available_skills(plan)
	print("Available skills")
	total_skills = {}
	-- Compute skill totals
	for _, p in pairs(plan.people) do
		for skill, frac in pairs(Plan.get_skill_distrib(plan, p)) do
			total = total_skills[skill] or 0
			total_skills[skill] = total + frac * plan.num_weeks
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

function Plan.print_skill_assignments(plan)
	print("Skill assignments")
	skill_assignments = {}
	for _, p in pairs(plan.people) do
		for skill, frac in pairs(Plan.get_skill_distrib(plan, p)) do
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
