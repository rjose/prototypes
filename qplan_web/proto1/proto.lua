require 'string_utils'

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

local request_string = table.concat(tmp, "\r\n")

function parse_request(req_str)
        local result = {}
        local pieces = req_str:split("\r\n")

        -- Parse out request line
        local request_line_parts = pieces[1]:split(" ")
        result.method = request_line_parts[1]
        result.request_target = request_line_parts[2]

        -- Parse headers
        local headers = {}
        for i = 2,#pieces do
                local header_parts = pieces[i]:split(": ")
                headers[header_parts[1]:lower()] = header_parts[2]
        end
        result.headers = headers

        return result
end

-- TODO: Test bad request lines

local req = parse_request(request_string)
print(req.method)
print(req.request_target)
for k, v in pairs(req.headers) do
        print(string.format("%s: %s", k, v))
end
