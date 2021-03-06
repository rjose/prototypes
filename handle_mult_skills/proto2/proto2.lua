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
plan:add_people{john, tracy}
plan:override_skill_distrib(tracy, {[ios_skill.name] = 0.80,
                                    [server_skill.name] = 0.20})

-- Sample usage
print("===============================")
plan:print_available_skills()

print()
plan:print_skill_assignments()

print()
print("===============================")
plan:print_workload()


print()
print("===============================")
plan:print_overloaded_skills()

print()
plan:print_excess_skills()

plan:override_skill_distrib(tracy, {[ios_skill.name] = 0.6923,
                                    [server_skill.name] = 0.3077})
print()
print("===============================")
print("(At optimal)")
plan:print_overloaded_skills()

print()
plan:print_excess_skills()
