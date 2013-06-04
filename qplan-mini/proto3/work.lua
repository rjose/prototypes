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

function Work.get_work(id)
	return Work.work[id]
end

function Work:print_name()
	print("Howdy")
end

return Work
