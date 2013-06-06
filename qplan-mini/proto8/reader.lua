require 'string_utils'

local Plan = require 'plan'

local Reader = {}

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
	local result = {}
	local file = assert(io.open(filename, "r"))
	local cur_line = 1

	for line in file:lines() do
		-- Skipping first two header lines
		if cur_line > 2 then
			result[#result+1] = construct_plan(line)
		end
		cur_line = cur_line + 1
	end
	return result
end

return Reader
