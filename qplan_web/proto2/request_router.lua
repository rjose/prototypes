local RequestRouter = {}

RequestRouter.public_dir = "public"


local phrases = {}
phrases[200] = "OK"
phrases[400] = "Bad request"
phrases[404] = "Not found"

function construct_response(code, content_type, content)
        local tmp = {}
        tmp[#tmp+1] = string.format("HTTP/1.1 %d %s", code, phrases[code])
        tmp[#tmp+1] = string.format("Content-Length: %d", content:len())
        tmp[#tmp+1] = string.format("Content-Type: text/html", content_type)
        tmp[#tmp+1] = ""
        tmp[#tmp+1] = content
        return table.concat(tmp, "\r\n")
end

function static_file_router(req)
        local result
        local path = ''
        local file
        local content_type = "text/html"
        local path_pieces = req.path_pieces

        -- Look for index.html
        if (#req.path_pieces == 1 and req.path_pieces[1] == '') then
                path_pieces = {"", "index.html"}
        elseif req.path_pieces[2] == 'css' then
                content_type = "text/css"
        elseif req.path_pieces[2] == 'js' then
                content_type = "application/javascript"
        end

        path = RequestRouter.public_dir .. table.concat(path_pieces, "/")

        -- Open file
        file = io.open(path, "r")
        if file == nil then
                result = construct_response(404, "text/html", "")
        else
                result = construct_response(200, content_type, file:read("*all"))
                file:close()
        end

        return result
end

RequestRouter.routers = {static_file_router}

function RequestRouter.route_request(req)
        local result
        for _, r in ipairs(RequestRouter.routers) do
                result = r(req)
                if result then break end
        end

        if result == nil then
                result = construct_response(404, "text/html", "")
        end

        return result
end


return RequestRouter
