local Web = {}

function Web.handle_request(req_str)
        print(string.format("Got this string: %s", req_str))

        content = "<html><body>This will be customized</body></html>\r\n"
        result = string.format("HTTP/1.1 200 OK\r\nContent-Length: %d\r\nContent-Type: text/html\r\n\r\n%s",
                content:len(), content)
        return result
end

return Web
