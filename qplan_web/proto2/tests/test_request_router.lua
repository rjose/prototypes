RequestRouter = require('request_router')
require('string_utils')

TestRouteRequest = {}

-- SETUP ----------------------------------------------------------------------
--

function TestRouteRequest:test_root_file_request()
        local req = {}
        req.method = "GET"
        req.request_target = "/"
        req.path_pieces = {""}

        local response = RequestRouter.route_request(req)
        assert(string.match(response, "HTML file!"))
end


function TestRouteRequest:test_css_file_request()
        local req = {}
        req.method = "GET"
        req.request_target = "/css/qplan.css"
        req.path_pieces = {"", "css", "qplan.css"}

        local response = RequestRouter.route_request(req)
        assert(string.match(response, "Styles!"))
end

function TestRouteRequest:test_js_file_request()
        local req = {}
        req.method = "GET"
        req.request_target = "/js/qplan.js"
        req.path_pieces = {"", "js", "qplan.js"}

        local response = RequestRouter.route_request(req)
        assert(string.match(response, "Javascript!"))
end

function TestRouteRequest:test_generic_file_request()
        local req = {}
        req.method = "GET"
        req.request_target = "/meeting.html"
        req.path_pieces = {"", "meeting.html"}

        local response = RequestRouter.route_request(req)
        assert(string.match(response, "Meeting!"))
end
