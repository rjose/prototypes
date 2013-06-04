Work = require("work")

local plan = {}


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


function get_ranked_work_items(plan)
	local work_ids = plan.work_items
	local result = {}
	for _, id in pairs(work_ids) do
		result[#result+1] = Work.get_work(id)
	end

	-- Add the cutline
	table.insert(result, plan.cutline+1, "CUTLINE")
	return result
end


function print_work_item(work_item)
	io.write(string.format("%3s - %-40s %s\n", work_item.id,
	                       work_item.name, work_item:get_estimate_string()))
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


-- By default, adding a work item should add it to the bottom of the list (TODO:
-- Need to Specify this)
function add_work_item(name, plan)
	new_item = Work.new(name, "Track2")
	Work.add_work(new_item)

	-- Add new work item to plan
	plan.work_items[#plan.work_items+1] = new_item.id
end

-- TODO: We'll also need to write this info back out to file
function delete_work_item(id, work, plan)
	local new_work_ids = {}
	-- First, we'll have to delete id from the plan's work items. We'll
	-- have to do this a little carefully since we want this to remain a
	-- compact array.
	for i = 1, #plan.work_items do
		if plan.work_items[i] ~= id then
			new_work_ids[#new_work_ids+1] = plan.work_items[i]
		end
	end
	plan.work_items = new_work_ids
	

	-- Delete work item from table
	Work.delete_work(id)
end

--[
-- Sample function calls
--]
work1 = Work.new("Do work item 1", "Track1", {["Native"] = "L",
                 ["Web"] = "M", ["Server"] = "S", ["BB"] = "S"})
Work.add_work(work1)
work2 = Work.new("Do work item 2", "Track1", {["Native"] = "2L",
                 ["Web"] = "Q", ["Server"] = "S", ["BB"] = "S"})
Work.add_work(work2)

plan = {id = "1", name = "MobileQ3", num_weeks = 13, team_id = "0",
        cutline = 1, work_items = {"2", "1"}}

print("Add a new item")
add_work_item("Item #3", plan)
ranked = get_ranked_work_items(plan)
print_work_items(ranked)

print("\nDelete the top item")
delete_work_item("2", work, plan)
ranked = get_ranked_work_items(plan)
print_work_items(ranked)

print("\nAdd estimate to work item")
Work.work["3"]:add_estimate("Native", "2L")
Work.work["3"]:add_estimate("Server", "M")
ranked = get_ranked_work_items(plan)
print_work_items(ranked)
