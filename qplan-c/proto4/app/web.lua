local Web = {}

function Web.handle_request(req_str)
        print(req_str)
        -- Write some unit tests to parse this:
        --
        -- GET / HTTP/1.1
        -- Host: localhost:8888
        -- Connection: keep-alive
        -- Cache-Control: max-age=0
        -- Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
        -- User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.93 Safari/537.36
        -- Accept-Encoding: gzip,deflate,sdch
        -- Accept-Language: en-US,en;q=0.8
        -- Cookie: visit="v=1&G"

        content = string.format("<html><body>Cutline: %d</body></html>\r\n", pl.cutline)
        result = string.format("HTTP/1.1 200 OK\r\nContent-Length: %d\r\nContent-Type: text/html\r\n\r\n%s",
                content:len(), content)
        return result
end

return Web
