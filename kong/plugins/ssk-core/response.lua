local common = require "kong.plugins.ssk-core.common"
local util = require "kong.plugins.ssk-core.lib.utils"
local response_body = require "kong.plugins.ssk-core.response_body"

local function enable_body_write()
        kong.ctx.shared.cap.response_body_write_enabled = true

        if ngx.header.content_length then
                ngx.header.content_length = nil
        end
end

local function rewrite_body()
        if kong.ctx.shared.cap.response_body_write_enabled ~= true then
                -- disabled
                return
        end

        local encoded_body, _ = response_body.get_encoded_body()
        ngx.arg[1] = encoded_body
end

local function run_header_handler()
        local handlers = kong.ctx.plugin.handlers
        local res_params = kong.response.get_headers()
        -- run handler
        for i = 1, #util.get_safe_d({}, handlers, "res_header" ) do
                local handler_info = handlers.res_header[i]
                local err = handler_info.h( res_params, unpack( handler_info.args ) )
                if err then
                        local blocked = common.on_detect( err )
                        if blocked then return end
                end
        end

        -- run header param
        if util.get_safe(handlers, "param_res_header") then
                local params = require "kong.plugins.ssk-core.params"
                params.detect_param_main( "param_res_header", res_params )
        end

        -- check detected list
        local ret = kong.ctx.shared.detected_info
        kong.ctx.shared.detected_info = nil
        if ret then
                local blocked = common.on_detect_list( ret )
                if blocked then return end
        end

end


-- luacheck: no unused
local BUFFERING_LIMIT = 8192
local BODYDETECT_LIMIT = 81920
-- luacheck: unused

local function run_body_handler()
        local params = require "kong.plugins.ssk-core.params"
        local handlers = kong.ctx.plugin.handlers

        -- run handler
        for i = 1, #util.get_safe_d({}, handlers, "res_body" ) do
                local handler_info = handlers.res_body[i]
                local err = handler_info.h( kong.ctx.shared.cap.res_body, unpack( handler_info.args ) )
                if err then
                        local blocked = common.on_detect( err )
                        if blocked then return end
                end
        end

        -- run body param
        if util.get_safe( handlers, "param_res_body" ) then
                local bodyparam = kong.ctx.shared.cap.res_bodyparam
                params.detect_param_main( "param_res_body", bodyparam )
        end

        -- check detected list
        local ret = kong.ctx.shared.detected_info
        kong.ctx.shared.detected_info = nil
        if ret then
                local blocked = common.on_detect_list( ret )
                if blocked then return end
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
        local handlers = kong.ctx.plugin.handlers
        if (not util.get_safe( handlers, "res_body" )) and
                (not util.get_safe( handlers, "param_res_body" )) then
                return false
        end

        -- do below on duty plugin only
        if check_duty() then
                kong.ctx.shared.cap.body_part = nil
                local parsers = util.get_safe_d({}, kong.ctx.shared.cap.handlers, "parse_res_body" )
                if #parsers > 0 then
                        -- if have custom parser
                        for i = 1, #parsers do
                                local handler_info = parsers[i]
                                local err = handler_info.h( "param_res_body", unpack(handler_info.args) )
                                if err then return err end
                        end
                else
                        -- else just call raw_body
                        local body = kong.response.get_raw_body()
                        if body then
                                kong.ctx.shared.cap.res_body_finished = nil
                                local cjson = require("cjson.safe")
                                local bodyparam, _ = cjson.decode(body)
                                kong.ctx.shared.cap.res_body = body
                                kong.ctx.shared.cap.res_bodyparam = bodyparam

                        end
                end
        end

        run_body_handler()
        rewrite_body()
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
        enable_body_write = enable_body_write,
        get_body_part = response_body.get_body_part,
        set_body_part = response_body.set_body_part,
        run_header_handler = run_header_handler,
        phase_body = phase_body,
        run_log_handler = run_log_handler,
}
