local mytable = {}

function mytable.table_length(t)
	result = 0
	for _, _ in pairs(t) do
		result = result + 1
	end
	return result
end


return mytable


