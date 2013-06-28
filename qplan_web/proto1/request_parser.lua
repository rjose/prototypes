local RequestParser = {}

function RequestParser.parse_request(req_str)
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

return RequestParser
