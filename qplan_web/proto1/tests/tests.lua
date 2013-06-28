package.path = package.path .. ";../?.lua"

local LuaUnit = require('luaunit')

require('test_parse_request')

LuaUnit:run()
