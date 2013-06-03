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

skills = read_skills()
