RequestParser = require('request_parser')
require('string_utils')

TestParseRequest = {}

-- SETUP ----------------------------------------------------------------------
--
function TestParseRequest:setUp()
        local tmp = {}
        tmp[#tmp+1] = "GET / HTTP/1.1"
        tmp[#tmp+1] = "Host: localhost:8888"
        tmp[#tmp+1] = "Connection: keep-alive"
        tmp[#tmp+1] = "Cache-Control: max-age=0"
        tmp[#tmp+1] = "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" 
        tmp[#tmp+1] = "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.93 Safari/537.36"
        tmp[#tmp+1] = "Accept-Encoding: gzip,deflate,sdch"
        tmp[#tmp+1] = "Accept-Language: en-US,en;q=0.8"
        tmp[#tmp+1] = 'Cookie: visit="v=1&G"'

        -- Set up valid request
        self.request_string = table.concat(tmp, "\r\n")

        -- Set up request with a route
        tmp = {}
        tmp[#tmp+1] = "GET /app/web/rrt HTTP/1.1"
        tmp[#tmp+1] = "Host: localhost:8888"
        tmp[#tmp+1] = "Accept: text/json"
        self.request_string_w_route = table.concat(tmp, "\r\n")

        -- Set up request with a query string
        tmp = {}
        tmp[#tmp+1] = "GET /app/web/rbt?triage=1&track=sop HTTP/1.1"
        tmp[#tmp+1] = "Host: localhost:8888"
        tmp[#tmp+1] = "Accept: text/json"
        self.request_string_w_query = table.concat(tmp, "\r\n")

        -- Set up request with multiple cookies
        tmp = {}
        tmp[#tmp+1] = "GET / HTTP/1.1"
        tmp[#tmp+1] = "Host: localhost:8888"
        tmp[#tmp+1] = 'Cookie: name="Borvo"; auth="123"'
        self.request_string_w_route = table.concat(tmp, "\r\n")
end


function TestParseRequest:test_parse_simple_request()
        local req = RequestParser.parse_request(self.request_string)
        assertEquals(req.method, "GET")
        assertEquals(req.request_target, "/")
end

