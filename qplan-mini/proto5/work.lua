local Work = {}

-- TODO: Read these from file using an init function
Work.work = {}
local max_work_item_id = 0

function Work:_new(obj)
        obj = obj or {}
        setmetatable(obj, self)
        self.__index = self
        return obj
end

function Work.new(name, track, estimates, id)
	id = id or ""
	estimates = estimates or {}
	return Work:_new{id = id .. "", name = name, track = track,
	                 estimates = estimates}
end

function Work.new(options)
	id = options.id or ""
	estimates = options.estimates or {}
        name = options.name or ""
        track = options.track or ""

	return Work:_new{id = id .. "", name = name, track = track,
	                 estimates = estimates}
end

function Work:get_estimate_string()
	local result = ""
	estimates = self.estimates or {}
	for skill, estimate in pairs(estimates) do
		result = result .. string.format("%s: %s, ", skill, estimate)
	end

	-- Strip trailing comma
	return result:sub(1, -3)
end

-- This is used to add a new work item to the system. This should be written to
-- disk
function Work.add_work(work_item)
	local new_id = max_work_item_id + 1
	max_work_item_id = new_id
	work_item.id = new_id .. ""

	-- Add to global work list
	Work.work[work_item.id] = work_item
end

-- TODO: We'll also need to write this info back out to file
function Work.delete_work(id)
	-- Delete work item from table
	Work.work[id] = nil
end

function Work:add_estimate(skill_name, estimate_string)
	self.estimates[skill_name] = estimate_string
end

function Work:clear_estimate()
	self.estimates = {}
end

-- Converts the work estimates from string values to weeks
function Work:week_estimates()
        local result = {}
        for skill, est_str in pairs(self.estimates) do
                result[skill] = Work.estimate_to_weeks(est_str)
        end
        return result
end

function Work.estimate_to_weeks(est_string)
        local scalar = 1
        local unit
        local units = {["S"] = 1, ["M"] = 2, ["L"] = 4, ["Q"] = 13}

        -- Look for something like "4L"
        for u, _ in pairs(units) do
                scalar, unit = string.match(est_string, "^(%d*)(" .. u .. ")")
                if unit then break end
        end

        -- If couldn't find a unit, then return 0
        if unit == nil then
                io.stderr:write("Unable to parse: ", est_string)
                return 0
        end

        -- If couldn't find a scalar, it's 1
        if scalar == "" then scalar = 1 end

        return scalar * units[unit]
end

function Work.add_estimates(est1, est2)
        local result = est1
        for skill, num_weeks in pairs(est2) do
                if result[skill] then
                        result[skill] = result[skill] + num_weeks
                else
                        result[skill] = num_weeks
                end
        end
        return result
end

function Work.sum_estimates(work_items)
        local result = {}
        for i = 1,#work_items do
                result = Work.add_estimates(result,
                                            work_items[i]:week_estimates())
        end
        return result
end

function Work.running_estimate_totals(work_items)
        -- Get an array of estimates
        local estimates = {}
        for _, w in pairs(work_items) do
                estimates[#estimates+1] = w:week_estimates()
        end

        -- Compute running totals
        local result = {}
        local cur_total = {}
        for _, est in pairs(estimates) do
                cur_total = Work.add_estimates(cur_total, est)
                result[#result+1] = cur_total
        end

        return result
end

-- TODO: Make this not a module thing
function Work.get_work(id)
	return Work.work[id]
end



--[
-- Functions for printing reports
--]
function Work.print_work_item(work_item)
	io.write(string.format("%3s - %-40s %s\n", work_item.id,
	                       work_item.name, work_item:get_estimate_string()))
end

function Work.print_work_items(work_items)
	for i = 1,#work_items do
		if type(work_items[i]) == "string" then
			print(work_items[i])
		else
			Work.print_work_item(work_items[i])
		end
	end
end

return Work
