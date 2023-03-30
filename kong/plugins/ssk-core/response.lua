local common = require "kong.plugins.ssk-core.common"
local util = require "kong.plugins.ssk-core.lib.utils"

local function run_header_handler()
	local handlers = kong.ctx.plugin.handlers
	local params = kong.response.get_headers()
	-- run handler
	for i = 1, #util.get_safe_d({}, handlers, "res_header" ) do
		local handler_info = handlers.res_header[i]
		local err = handler_info.h( params, unpack( handler_info.args ) )
		if err then		
			local blocked = common.on_detect( err )
			if blocked then return end
		end
	end

	-- run body param
	if util.get_safe(handlers, "param_res_header") then
		local err = params.detect_param_main( "param_res_header", params )
		if err then return err end
	end
end


local BUFFERING_LIMIT = 8192
local BODYDETECT_LIMIT = 81920


--      WARNING : if once get_raw_body called, upstream response will be buffered.
--              so need to be controled on nessesary
--              true : need to run detection
--              false : ignore
local function get_body()
        local cl = ngx.header.content_length
	if kong.ctx.plugin.body_acc == nil then kong.ctx.plugin.body_acc = "" end
	if kong.ctx.plugin.body_len == nil then kong.ctx.plugin.body_len = 0 end


        if cl ~= nil then
                local cl_n = tonumber(cl)
                if cl_n <= BUFFERING_LIMIT then
                        local body = kong.response.get_raw_body()
                        if body == nil then
                                return nil, false
                        end
                        return body, true
                elseif cl_n <= BODYDETECT_LIMIT then
                        kong.ctx.plugin.body_acc = kong.ctx.plugin.body_acc .. ( ngx.arg[1] and ngx.arg[1] or "")
                        local acc_n = #kong.ctx.plugin.body_acc
			if cl_n < acc_n then
				return nil, false
			elseif cl_n == acc_n then
                                return kong.ctx.plugin.body_acc, true
                        end
                        return kong.ctx.plugin.body_acc, true
		end
		return nil, true
        else
                -- acc body string      
		kong.ctx.plugin.body_len = kong.ctx.plugin.body_len + #ngx.arg[1]
                
                if kong.ctx.plugin.body_len <= BODYDETECT_LIMIT then
                        kong.ctx.plugin.body_acc = kong.ctx.plugin.body_acc .. ngx.arg[1]
                        if ngx and ngx.arg[2] then
                                --return nil, false
                                return kong.ctx.plugin.body_acc, true
                        else
                                return nil, false
                        end
                end

                return nil, true
        end
	-- not reached
end


local function run_body_handler()
	local params = require "kong.plugins.ssk-core.params"

	local handlers = kong.ctx.plugin.handlers

	if util.get_safe( handlers, "param_res_body" ) then
		local bodyparam = kong.ctx.shared.cap.res_body
		local err = params.detect_param_main( "param_res_body", bodyparam )	
		if err then
			common.on_detect( err )
		end
	end
end



local function check_duty()
	if kong.ctx.shared.cap.res_body_ongoing then
		return kong.ctx.plugin.res_duty 
	end
	
	kong.ctx.shared.cap.res_body_ongoing = true
	kong.ctx.plugin.res_duty = true
	return kong.ctx.plugin.res_duty
end

local function phase_body()
	if kong.ctx.shared.cap.res_body_finished then return kong.ctx.shared.cap.res_body_finished end

	local handlers = kong.ctx.plugin.handlers
	if not util.get_safe( handlers, "param_res_body" ) then return false end

	-- do below on duty plugin only
	if not check_duty() then return false end

	local body, finished = get_body()
	if finished then
		kong.ctx.shared.cap.res_body_finished = finished
		local cjson = require("cjson.safe")
		local bodyparam, err = cjson.decode(body)
		kong.ctx.shared.cap.res_body = bodyparam
	end
	return finished
end

local function run_log_handler()
	local handlers = kong.ctx.plugin.handlers

	-- run handler
	for i = 1, #util.get_safe_d({}, handlers, "log" ) do
		local handler_info = handlers.log[i]
		local err = handler_info.h( {}, unpack( handler_info.args ) )
		if err then		
			local blocked = common.on_detect( err )
			if blocked then return end
		end
	end

end

return {
	run_header_handler = run_header_handler,
	phase_body = phase_body,
	run_body_handler = run_body_handler,
	run_log_handler = run_log_handler,
}
