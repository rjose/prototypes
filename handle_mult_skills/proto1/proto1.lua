--[
-- Skill "class"
--]
Skill = {}

function Skill.new(name)
	return {name = name}
end

ios_skill = Skill.new("ios")
android_skill = Skill.new("android")
mobile_web_skill = Skill.new("mobile web")
server_skill = Skill.new("server")
qa_skill = Skill.new("qa")
set_skill = Skill.new("set")


--[
-- Person "class"
--]
Person = {}

-- *skills* is an array of skills
function Person.new(name, skills)
	result = {name = name}
	result.skill_distrib = {}

	-- The default skill distribution will be 100% for the first skill and
	-- 0% for the rest.
	for i = 1, #skills do
		result.skill_distrib[skills[i].name] = 0.0
	end
	result.skill_distrib[skills[1].name] = 1.0

	return result
end

function Person.print_skill_distrib(person)
	for k, v in pairs(person.skill_distrib) do
		print(string.format("%s: %f", k, v))
	end
end

john = Person.new("John", {ios_skill})
tracy = Person.new("Tracy", {server_skill, ios_skill})

--[
-- Plan "class"
--]
Plan = {}

function Plan.new(num_weeks)
	result = {num_weeks = num_weeks}
	return result
end

function Plan.add_people(plan, people)
	plan.people = people
end

-- TODO: Add skill distribution

function Plan.print_available_skills(plan)
	print("Available skills")
	total_skills = {}
	-- Compute skill totals
	for _, p in pairs(plan.people) do
		for skill, frac in pairs(p.skill_distrib) do
			total_skills[skill] = total_skills[skill] or 0
			total_skills[skill] = total_skills[skill] + frac * plan.num_weeks
		end
	end

	for skill, avail in pairs(total_skills) do
		print(string.format("%s: %f weeks-effort", skill, avail))
	end
end

plan = Plan.new(13)
Plan.add_people(plan, {john, tracy})

--[
-- Code to exercise the above
--]
Plan.print_available_skills(plan)
-- Person.print_skill_distrib(john)
-- Person.print_skill_distrib(tracy)
