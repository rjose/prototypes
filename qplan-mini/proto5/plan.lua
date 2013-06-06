Work = require("work")

local Plan = {}

-- TODO: Handle reading plans from file

function Plan:_new(obj)
        obj = obj or {}
        setmetatable(obj, self)
        self.__index = self
        return obj
end

function Plan.new(options)
	id = options.id or ""
	name = options.name or ""
	num_weeks = num_weeks or 13 	-- Default to a quarter
	team_id = options.team_id or ""
	work_items = options.work_items or {}
	cutline = options.cutline or 1

	return Plan:_new{id = id .. "", name = name, num_weeks = num_weeks,
	                 cutline = cutline, work_items = work_items,
			 team_id = team_id .. ""}
end

-- TODO: I think this should only take a real Work item. It shouldn't create one
function Plan:add_work_item(name, track)
	new_item = Work.new(name, track)
	Work.add_work(new_item)

	-- Add new work item to self
	self.work_items[#self.work_items+1] = new_item.id
end

-- TODO: We'll also need to write this info back out to file
function Plan:delete_work_item(id)
	local new_work_ids = {}
	-- First, we'll have to delete id from the self's work items. We'll
	-- have to do this a little carefully since we want this to remain a
	-- compact array.
	for i = 1, #self.work_items do
		if self.work_items[i] ~= id then
			new_work_ids[#new_work_ids+1] = self.work_items[i]
		end
	end
	self.work_items = new_work_ids

	-- Delete work item from table
	Work.delete_work(id)
end

function Plan:get_ranked_work_items()
	local work_ids = self.work_items or {}
	local result = {}
	for _, id in pairs(work_ids) do
		result[#result+1] = Work.get_work(id)
	end

	-- Insert the cutline
	table.insert(result, self.cutline+1, "CUTLINE")
	return result
end

function Plan:get_work_above_cutline()
	local result = {}
	for i, id in pairs(self.work_items) do
		local work = Work.get_work(id)
		result[#result+1] = Work.get_work(id)
		if i == self.cutline then break end
	end
	return result
end

function Plan:set_cutline(cutline)
	if type(cutline) ~= "number" then
		io.stderr:write("Cutline wasn't a number!")
		return
	end
	self.cutline = cutline
end

function position_from_options(items, options)
	local result = 1
	if options == nil then
		return result
	end

	if type(options.at) == "number" then
		result = options.at
	end

	return result
end

-- We'll use this to move items around the list
function Plan:rank(items, options)
	-- Normalize ids in items
	local items_map = {}
	for i = 1,#items do
		items[i] = items[i] .. ""
		items_map[items[i]] = true
	end

	local position = position_from_options(items, options)

	local unchanged_items = {}
	local changed_map = {}

	local insert_position = nil 

	-- Separate work items into unchaged and changed items
	for rank, id in pairs(self.work_items) do
		if items_map[id] then
			-- Need to treat separately because these need to be ordered
			changed_map[id] = true
			if rank == position then
				insert_position = rank
			end
		else
			unchanged_items[#unchanged_items+1] = id
			if rank == position then
				insert_position = #unchanged_items
			end
		end
	end

	-- Put changed items back into order (filtering out garbage)
	local changed_items = {}
        for _, id in pairs(items) do
		if changed_map[id] then
			changed_items[#changed_items+1] = id
		end
	end

	-- Put changed items into position
	local new_work_items = {}
	if insert_position == nil then
		for i = 1,#unchanged_items do
			new_work_items[#new_work_items+1] = unchanged_items[i]
		end
		for i = 1,#changed_items do
			new_work_items[#new_work_items+1] = changed_items[i]
		end
	else
		for i = 1,#unchanged_items do
			if i == insert_position then
				for j = 1,#changed_items do
					new_work_items[#new_work_items+1] = changed_items[j]
				end
				
				-- Don't forget the current unchanged item!
				new_work_items[#new_work_items+1] = unchanged_items[i]
			else
				new_work_items[#new_work_items+1] = unchanged_items[i]
			end
		end

	end

	self.work_items = new_work_items
end

function Plan:get_demand_above_cutline()
	local work_items = self:get_work_above_cutline()
	local running_totals = Work.running_estimate_totals(work_items)
	return running_totals[#running_totals]
end

-- This takes a table of available skills and returns a running total of the
-- skill availability by week. This also takes an array of work items.
function Plan.get_running_skills_available(skills, work_items)
	local result = {}

	-- Get the running demand
	local running_demand_totals = Work.running_estimate_totals(work_items)

	-- Compute the running availability
	for i = 1,#running_demand_totals do
		result[#result+1]= Work.subtract_estimates(skills, running_demand_totals[i])
	end
	return result
end

return Plan
