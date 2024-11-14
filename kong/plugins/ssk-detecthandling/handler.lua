local core = require "kong.plugins.ssk-core.core"
local util = require "kong.plugins.ssk-core.lib.utils"

local function h( detect_info, config )
        -- Do not try to exit on phase RES
        -- 512 == header_filter
        -- 1024 == body_filter

        if ngx.ctx.KONG_PHASE >= 512 then
                return
        end

        local filter = config.default_filter

        if util.get_safe_d( false, detect_info, "tags" ) then
                for i = 1, #detect_info["tags"] do
                        local found = util.get_safe_d( nil, config.filters_tbl, detect_info["tags"][i] )
                        if found ~= nil then
                                filter = found
                                break
                        end
                end
        end


        local ondetect_status = util.get_safe_d( nil, filter, "status" )
        local ondetect_headers = util.get_safe_d( {}, filter, "headers_tbl" )
        local ondetect_body = util.get_safe_d( "", filter, "body" )
        local ondetect_delay = util.get_safe_d( 0, filter, "delay" )

        return ondetect_status, ondetect_body, ondetect_headers, ondetect_delay
end

local function optimize_filter( filter )
        filter.headers_tbl = {}
        if filter.headers then
		for i = 1, #filter.headers do
			if filter.headers[i].key and filter.headers[i].value then
				filter.headers_tbl[ filter.headers[i].key ] = filter.headers[i].value
			end
		end
	end

end

local function optimize(config)
        if config.optimized then return true end

        config.filters_tbl = {}
        config.default_filter = nil
        if config.filters then
                for i = 1, #config.filters do
                        config.filters_tbl[ config.filters[i].tag ] = config.filters[i]
                        optimize_filter( config.filters[i] )
                        if config.default_filter == nil then
                                config.default_filter = config.filters[i]
                        end
                        if config.filters[i].default then
                                config.default_filter = config.filters[i]
                        end
                end
        end

        config.optimized = true
end

local _M = core:extend()

_M.PRIORITY = 100 + 2

function _M:init_handler( config )
        optimize(config)
        self:add_global_handler( "ondetect", h, config)
end


return _M
