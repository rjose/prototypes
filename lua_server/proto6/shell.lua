proto6 = require('proto6')

proto6.start_listening()

function get_home()
	local file = assert(io.open("home.html", "r"))
	local result = file:read("*all")
	file:close()
	return result
end
