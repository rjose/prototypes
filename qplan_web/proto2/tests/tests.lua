package.path = package.path .. ";../?.lua"

local LuaUnit = require('luaunit')

require('test_request_router')

LuaUnit:run()
