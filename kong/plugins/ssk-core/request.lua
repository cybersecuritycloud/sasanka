local common = require "kong.plugins.ssk-core.common"
local util = require "kong.plugins.ssk-core.lib.utils"

local function bodyparam_cb( bodyparam )
	local params = require "kong.plugins.ssk-core.params"
	local err = params.detect_param_main( "param_req_body", bodyparam )
	if err then return err end
end

local function get_body_by_memory()
	-- CAUTION : DO NOT CALL get_raw_body several time!
	-- NOTE : In kong, phase_access will called once.
	return kong.request.get_raw_body()
end


local function detect_request( handlers, req_params )
	local params = require "kong.plugins.ssk-core.params"

	if util.get_safe(handlers, "param_req_query") then
		local err = params.detect_param_main( "param_req_query", req_params.queryparam )
		if err then return err end
	end
	if util.get_safe(handlers, "param_req_path") then
		local err = params.detect_param_path( "param_req_path", req_params.pathsplit )	
		if err then return err end
	end
	if util.get_safe(handlers, "param_req_cookie") then
		local err = params.detect_param_main( "param_req_cookie", req_params.cookieparam )	
		if err then return err end
	end
	if util.get_safe(handlers, "param_req_header") then
		local err = params.detect_param_main( "param_req_header", req_params.header )	
		if err then return err end
	end
	if util.get_safe(handlers, "param_req_body") then
		if kong.ctx.shared.cap.body_in_file then
			local parsers = util.get_safe_d({}, kong.ctx.shared.cap.handlers, "parse_req_body" )
			for i = 1, #parsers do
				local handler_info = parsers[i]
				local err = handler_info.h( "param_req_body", bodyparam_cb, unpack(handler_info.args) )
				if err then return err end
			end
		else
			local err = params.detect_param_main( "param_req_body", req_params.bodyparam )	
			if err then return err end	
		end
	end


	return nil
end

local function parse_cookie()
	local ck = require "resty.cookie"
	local cookie, err = ck:new()
	if err then return {} end
	local fields, err = cookie:get_all()
	if err then return {} end
	return fields
end

local function decode( dict )
	for k in pairs(dict) do
		dict[k] = ngx.unescape_uri(dict[k])
	end
	return dict
end

local function phase_access( handlers )
	if not kong.ctx.shared.cap.req_params then kong.ctx.shared.cap.req_params = {} end
	local params = kong.ctx.shared.cap.req_params

	if not util.get_safe(params, "pathsplit") and
		( util.get_safe(handlers, "req_path") or
		util.get_safe(handlers, "param_req_path") )then
		local pathsplit = util.split(kong.request.get_path(),  "/")
		params["pathsplit"] = decode( pathsplit )
	end

	if not util.get_safe(params, "queryparam")  and
		( util.get_safe(handlers, "req_query") or
		util.get_safe(handlers, "param_req_query") )then
		params["queryparam"] = decode( kong.request.get_query() )
	end

	if not util.get_safe(params, "cookieparam")  and
		util.get_safe(handlers, "param_req_cookie") then
		params["cookieparam"] = decode( parse_cookie() )
	end

	if not util.get_safe(params, "bodyparam") and
		util.get_safe(handlers, "param_req_body") then
		params["bodyparam"] = {}

		-- NOTE: In Kong, access phase will be called end of request body
		-- if body is nil, it means need to read file
		-- if body is "", it means no body
		local body = get_body_by_memory()
		if body ~= nil then
			-- by memory
			-- use native kong parser
			local body_param, reqbody_err, reqbody_mimetype = nil, nil, nil
			body_param, reqbody_err, reqbody_mimetype = kong.request.get_body()
			params["bodyparam"] = body_param
		else
			kong.ctx.shared.cap.body_in_file = true
		end
	end
	
	if not util.get_safe(params, "header")  and
		( util.get_safe(handlers, "req_header") or 
		util.get_safe(handlers, "param_req_header"))then
		params["header"] = decode( kong.request.get_headers() )
	end

	return true
end

local function run_access_handler()
	local handlers = kong.ctx.plugin.handlers
	local params = kong.ctx.shared.cap.req_params

	-- run handler
	for i = 1, #util.get_safe_d({}, handlers, "req_header" ) do
		local handler_info = handlers.req_header[i]
		local err = handler_info.h( params.header, unpack( handler_info.args ) )
		if err then
			local blocked = common.on_detect( err )
			if blocked then return end
		end
	end

	local err = detect_request( handlers, params )
	if err then
		local blocked = common.on_detect( err )
		if blocked then return end
	end

	for i = 1, #util.get_safe_d({}, handlers, "after_access" ) do
		local handler_info = handlers.after_access[i]
		local err = handler_info.h( params.header, unpack( handler_info.args ) )
		if err then
			local blocked = common.on_detect( err )
			if blocked then return end
		end
	
	end	
	return
end

return {
	run_access_handler = run_access_handler,
	phase_access = phase_access,
}
