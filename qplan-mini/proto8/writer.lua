local Writer = {}

function join(items, sep)
	local result = ""

	for _, item in pairs(items) do
		result = result .. item .. sep
	end

	-- Remove trailing sep
	result = result:sub(1, -sep:len()-1)

	return result
end

function Writer.write_plans(plans, filename)
	local file = assert(io.open(filename, "w"))

	-- Write headers first
	file:write("ID\tName\tNumWeeks\tTeamID\tCutline\tWorkItems\n")
	file:write("-----\n")

	-- Write plans next
	for _, plan in pairs(plans) do
		file:write(string.format("%s\t%s\t%d\t%s\t%d\t%s\n", 
			plan.id, plan.name, plan.num_weeks, plan.team_id,
			plan.cutline, join(plan.work_items, ",")
		))
	end
	file:close()
end

return Writer
