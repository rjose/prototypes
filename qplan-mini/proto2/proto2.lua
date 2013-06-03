-- TODO: Move this to a util module
function string:split(sSeparator, nMax, bRegexp)
	assert(sSeparator ~= '')
	assert(nMax == nil or nMax >= 1)

	local aRecord = {}

	if self:len() > 0 then
		local bPlain = not bRegexp
		nMax = nMax or -1

		local nField=1 nStart=1
		local nFirst,nLast = self:find(sSeparator, nStart, bPlain)
		while nFirst and nMax ~= 0 do
			aRecord[nField] = self:sub(nStart, nFirst-1)
			nField = nField+1
			nStart = nLast+1
			nFirst,nLast = self:find(sSeparator, nStart, bPlain)
			nMax = nMax-1
		end
		aRecord[nField] = self:sub(nStart)
	end

	return aRecord
end

-- TODO: Move this to a class
function construct_skill(id, name)
	return {id = id, name = name}
end

-- TODO: Move this to an data module
function read_skills()
	local file = io.open("skills.txt")
	if not file then
		print("Unable to read file")
		return nil
	end

	local state = "START"
	local result = {}

	for line in file:lines() do
		if state == "START" and line == "ID\tName" then
			state = "LOOK_FOR_HEADER"
		elseif state == "LOOK_FOR_HEADER" and line == "-----" then
			state = "PARSE"
		elseif state == "PARSE" then
			local id, name = unpack(line:split("\t"))
			result[id] = construct_skill(id, name)
		end
	end
	return result
end

-- List of work items in ranked order along with a cutline
work = {["1"] = {id = "1", name = "Do work item 1",
	 estimates = {["Native"] = "L", ["Web"] = "M", ["Server"] = "S", ["BB"] = "S"}},

	["2"] = {id = "2", name = "Do work item 2",
	 estimates = {["Native"] = "2L", ["Web"] = "Q", ["Server"] = "S", ["BB"] = "S"}}
}

plan = {id = "1", name = "MobileQ3", num_weeks = 13, team_id = "0",
        cutline = 1, work_items = {"2", "1"}}

function get_ranked_work_items(plan, work)
	local work_ids = plan.work_items
	local result = {}
	for _, id in pairs(work_ids) do
		result[#result+1] = work[id]
	end

	-- Add the cutline
	table.insert(result, plan.cutline+1, "CUTLINE")
	return result
end

function print_work_item(work_item)
	io.write(string.format("%3s - %s\n", work_item.id, work_item.name))
end

function print_work_items(work_items)
	for i = 1,#work_items do
		if type(work_items[i]) == "string" then
			print(work_items[i])
		else
			print_work_item(work_items[i])
		end
	end
end

ranked = get_ranked_work_items(plan, work)
print_work_items(ranked)
