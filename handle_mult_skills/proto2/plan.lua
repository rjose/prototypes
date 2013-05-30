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
	local result = Plan:_new{num_weeks = num_weeks, skill_distrib_override = {} }
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

-- Just a stub function for now
function Plan:get_workload()
	local result = {ios = 22.0, server = 4.0, android = 10.0}
	return result
end

-- Gets the available skill bandwidth for the team (assuming current skill
-- distribution)
function Plan:get_skill_totals()
	local result = {}
	for _, p in pairs(self.people) do
		for skill, frac in pairs(self:get_skill_distrib(p)) do
			total = result[skill] or 0
			result[skill] = total + frac * self.num_weeks
		end
	end
	return result
end

-- Based on the workload, this returns a table of skills and the amount of
-- overload (positive number)
function Plan:get_overloaded_skills()
	local result = {}
	workload = self:get_workload()
	skill_totals = self:get_skill_totals()

	-- Find where demand exceeds supply
	for skill, demand in pairs(workload) do
		supply = skill_totals[skill]
		if (supply == nil) then
			result[skill] = demand
		elseif (demand > supply) then
			result[skill] = demand - supply
		end
	end
	return result
end

-- Based on the workload, this returns a table of skills and the amount of
-- excess (positive number)
function Plan:get_excess_skills()
	local result = {}
	workload = self:get_workload()
	skill_totals = self:get_skill_totals()

	-- Find where demand exceeds supply
	for skill, supply in pairs(skill_totals) do
		demand = workload[skill]
		if (demand == nil) then
			result[skill] = supply
		elseif (supply > demand) then
			result[skill] = supply - demand
		end
	end
	return result
end

function print_skills_effort(skills_effort)
	for skill, effort in pairs(skills_effort) do
		print(string.format("%s: %f weeks-effort", skill, effort))
	end
end

-- TODO: Think about moving the reporting functions to another class
function Plan:print_available_skills()
	print("Available skills")
	print("----------------")
	print_skills_effort(self:get_skill_totals())
end

function Plan:print_workload()
	print("Workload")
	print("--------")
	print_skills_effort(self:get_workload())
end

function Plan:print_overloaded_skills()
	print("Overloaded skills")
	print("-----------------")
	print_skills_effort(self:get_overloaded_skills())
end

function Plan:print_excess_skills()
	print("Excess skills")
	print("-------------")
	print_skills_effort(self:get_excess_skills())
end


function format_skill_assignment(person, skill_distrib, skill_name)
	if mytable.table_length(person.skill_distrib) == 1 then
		return person.name
	else
		return string.format("%s-%.0f%%", person.name, skill_distrib[skill_name]*100)
	end
end

function Plan:print_skill_assignments()
	print("Skill assignments")
	print("-----------------")
	local skill_assignments = {}
	for _, p in pairs(self.people) do
		skill_distrib = self:get_skill_distrib(p)
		for skill, frac in pairs(skill_distrib) do
			skill_assignments[skill] = skill_assignments[skill] or {}
			table.insert(skill_assignments[skill],
			             format_skill_assignment(p, skill_distrib, skill))
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
