require 'string_utils'

local Plan = require 'plan'
local Work = require 'work'
local Person = require 'person'

local Reader = {}

function construct_objects_from_file(filename, constructor)
	local result = {}
	local file = assert(io.open(filename, "r"))
	local cur_line = 1

	for line in file:lines() do
		-- Skipping first two header lines
		if cur_line > 2 then
			result[#result+1] = constructor(line)
		end
		cur_line = cur_line + 1
	end
	file:close()
	return result
end

function construct_plan(str)
	local id, name, num_weeks, team_id, cutline, work_items_str = 
		unpack(str:split("\t"))

	local work_items = {}
	for _, w in pairs(work_items_str:split(",")) do
		work_items[#work_items+1] = w .. ""
	end
	local result = Plan.new{
		id = id,
		name = name,
		num_weeks = num_weeks,
		team_id = team_id,
		work_items = work_items,
		cutline = cutline
	}
	return result
end


function Reader.read_plans(filename)
	return construct_objects_from_file(filename, construct_plan)
end

function construct_work(str)
	local id, name, track, estimate_str = unpack(str:split("\t"))

	local estimates = {}
	for _, s in pairs(estimate_str:split(", ")) do
		-- At this point, s will be something like "Native:L"
		local skill, est = unpack(s:split(":"))
		estimates[skill] = est
	end

	local result = Work.new{
		id = id,
		name = name,
		track = track,
		estimates = estimates
	}
	return result
end

function Reader.read_work(filename)
	return construct_objects_from_file(filename, construct_work)
end

function construct_person(str)
	local id, name, skills_str = unpack(str:split("\t"))

	local skills = {}
	for _, s in pairs(skills_str:split(", ")) do
		-- At this point, s will be something like "Native:1"
		local skill, frac = unpack(s:split(":"))
		skills[skill] = frac + 0
	end

	local result = Person.new{
		id = id,
		name = name,
		skills = skills
	}
	return result
end

function Reader.read_people(filename)
	return construct_objects_from_file(filename, construct_person)
end
return Reader
