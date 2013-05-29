local Skill = require "skill"
local mytable = require "mytable"
local Person = require "person"
local Plan = require "plan"

-- Some skills
ios_skill = Skill.new("ios")
android_skill = Skill.new("android")
mobile_web_skill = Skill.new("mobile web")
server_skill = Skill.new("server")
qa_skill = Skill.new("qa")
set_skill = Skill.new("set")

-- Some people
john = Person.new("John", {ios_skill})
tracy = Person.new("Tracy", {server_skill, ios_skill})


-- A plan with some skill overrides
plan = Plan.new(13)
Plan.add_people(plan, {john, tracy})
override = {}
override[ios_skill.name] = 0.80
override[server_skill.name] = 0.20
Plan.override_skill_distrib(plan, tracy, override)


-- Sample usage
print()
Plan.print_available_skills(plan)

print()
Plan.print_skill_assignments(plan)
