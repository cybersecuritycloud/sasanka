local common = require "kong.plugins.ssk-core.common"
local util = require "kong.plugins.ssk-core.lib.utils"
local ssk = require "kong.plugins.ssk-core.lib.ssk"
local decoder = require "kong.plugins.ssk-core.decoder"


local function preserve_exit(s, b, h)
        kong.ctx.shared.cap.preserve_exit = {
                status = s,
                body = b,
                headers = h,
        }
end

local function call_preserved_exit()
        local preserved = kong.ctx.shared.cap.preserve_exit
        if preserved then
                kong.response.exit( preserved.status, preserved.body, preserved.headers )
        end
end

local function parse_body_cb( bodyparam, body, body_mime)
        local params = require "kong.plugins.ssk-core.params"
        local handlers = kong.ctx.plugin.handlers

        --- run body param
        if bodyparam and  util.get_safe(handlers, "param_req_body") then
                if body_mime and string.find(body_mime, "urlencoded") ~= nil then
                        params.detect_param_urlencoded( "param_req_body", bodyparam )
                else
                        params.detect_param_main( "param_req_body", bodyparam )
                end

        end

        --- run body raw
        local req_body_n = #util.get_safe_d({}, handlers, "req_body" )
        if req_body_n > 0 then
                local v = body
                local v_list = decoder.build_decoded_list( v, kong.ctx.shared.cap.options["req_body"])
                for i = 1, #util.get_safe_d({}, handlers, "req_body" ) do
                        local handler_info = handlers.req_body[i]
                        local err = handler_info.h( v, v_list, unpack( handler_info.args ) )
                        common.store_detected( err )
                end
        end
end

local function get_body_by_memory()
        -- CAUTION : DO NOT CALL get_raw_body several time!
        -- NOTE : In kong, phase_access will called once.
        return kong.request.get_raw_body()
end

local function parse_body( h_req_body, h_param_req_body)

        -- NOTE: In Kong, access phase will be called end of request body
        -- if body is nil, it means need to read file
        -- if body is "", it means no body
        local body = get_body_by_memory()
        if body ~= nil then
                -- by memory
                -- use native kong parser
                local body_param, _, reqbody_mimetype = kong.request.get_body()

                parse_body_cb( body_param, body, reqbody_mimetype )

        else
                local parsers = util.get_safe_d({}, kong.ctx.shared.cap.handlers, "parse_req_body" )
                for i = 1, #parsers do
                        local handler_info = parsers[i]
                        handler_info.h( "parse_req_body", parse_body_cb, unpack(handler_info.args) )
                end
        end
end

local function detect_request_body( handlers )

        if not util.get_safe(kong.ctx.shared.cap, "req_body") and
                (util.get_safe(handlers, "req_body") or
                util.get_safe(handlers, "param_req_body")) then

                parse_body( util.get_safe(handlers, "req_body") , util.get_safe(handlers, "param_req_body") )
        end

end

local function detect_request( handlers, req_params )
        local params = require "kong.plugins.ssk-core.params"

        -- run handler
        --- run path
        local req_path_n = #util.get_safe_d({}, handlers, "req_path" )
        if req_path_n > 0 then
                local v = ssk.get_raw_path()
                local v_list = decoder.build_decoded_list( v, kong.ctx.shared.cap.options["req_path"])
                for i = 1, #util.get_safe_d({}, handlers, "req_path" ) do
                        local handler_info = handlers.req_path[i]
                        local err = handler_info.h( v, v_list, unpack( handler_info.args ) )
                        common.store_detected( err )
                end
        end

        --- run query
        local req_path_n = #util.get_safe_d({}, handlers, "req_query" )
        if req_path_n > 0 then
                local v = kong.request.get_raw_query()
                local v_list = decoder.build_decoded_list( v, kong.ctx.shared.cap.options["req_query"])
                for i = 1, #util.get_safe_d({}, handlers, "req_query" ) do
                        local handler_info = handlers.req_query[i]
                        local err = handler_info.h( v, v_list, unpack( handler_info.args ) )
                        common.store_detected( err )
                end
        end
        --- run header
        for i = 1, #util.get_safe_d({}, handlers, "req_header" ) do
                local handler_info = handlers.req_header[i]
                local err = handler_info.h( req_params.header, unpack( handler_info.args ) )
                common.store_detected( err )
        end


        --- run params
        if util.get_safe(handlers, "param_req_query") then
                params.detect_param_urlencoded( "param_req_query", req_params.queryparam )
        end
        if util.get_safe(handlers, "param_req_path") then
                params.detect_param_main( "param_req_path", req_params.pathparam )
        end
        if util.get_safe(handlers, "param_req_cookie") then
                params.detect_param_main( "param_req_cookie", req_params.cookieparam )
        end
        if util.get_safe(handlers, "param_req_header") then
                params.detect_param_main( "param_req_header", req_params.header )
        end

        detect_request_body( handlers )


        --- run after access
        for i = 1, #util.get_safe_d({}, handlers, "after_access" ) do
                local handler_info = handlers.after_access[i]
                local err = handler_info.h( params.header, unpack( handler_info.args ) )
                common.store_detected( err )
        end

        local ret = kong.ctx.shared.detected_info
        kong.ctx.shared.detected_info = nil
        return ret
end

local function parse_cookie()
        local ck = require "resty.cookie"
        local cookie, err = ck:new()
        if err then return {} end
        local fields, err = cookie:get_all()
        if err then return {} end
        return fields
end

local function make_path_param( pathsplit, matcher)
                local ret = {}
                if #pathsplit < #matcher then return nil end

                for ii = 1, #matcher do
                        local frag = util.get_safe( matcher, ii )
                        local key = util.get_safe( frag, "key" )

                        if key then
                                ret[key] = pathsplit[ii]
			elseif util.get_safe( frag, "splited" ) ~= pathsplit[ii] then
				return nil
			--elseif util.get_safe( frag, "splited" ) == pathsplit[ii]
                        --        continue
                        end
                end
                return ret
end

local function match_path_param( pathsplit, matchlist )
        if not matchlist then return {} end
        for i = 1, #matchlist do
                local ret = make_path_param( pathsplit, matchlist[i] )
                if ret ~= nil then
                        return ret
                end
        end
        return {}
end

local function phase_access( handlers )
        if not kong.ctx.shared.cap.req_params then kong.ctx.shared.cap.req_params = {} end
        local params = kong.ctx.shared.cap.req_params

        if not util.get_safe(params, "pathparam") and
                util.get_safe(handlers, "param_req_path") then

                local pathsplit = util.split( ssk.get_raw_path(),  "/")
                params["pathparam"] = match_path_param( pathsplit, kong.ctx.shared.cap.options["path_split"])
	end

        if not util.get_safe(params, "queryparam")  and
                (util.get_safe(handlers, "req_query") or
                util.get_safe(handlers, "param_req_query")) then

                params["queryparam"] = ssk.get_query()
        end

        if not util.get_safe(params, "cookieparam")  and
                util.get_safe(handlers, "param_req_cookie") then
                params["cookieparam"] = parse_cookie()
        end

        if not util.get_safe(params, "header")  and
                ( util.get_safe(handlers, "req_header") or
                util.get_safe(handlers, "param_req_header"))then
                params["header"] = kong.request.get_headers()
        end

        return true
end

local function run_access_handler()
        local handlers = kong.ctx.plugin.handlers
        local params = kong.ctx.shared.cap.req_params

        --- run params
        local detected = detect_request( handlers, params )
        if detected then
                local blocked = common.on_detect_list( detected )
                if blocked then return end
        end

        --- if have preserved exit
        call_preserved_exit()

        return
end

return {
        preserve_exit = preserve_exit,
        run_access_handler = run_access_handler,
        phase_access = phase_access,
}
