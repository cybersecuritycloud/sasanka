local core = require "kong.plugins.ssk-core.core"
local util = require "kong.plugins.ssk-core.lib.utils"

local function h( detect_info, config )
	-- Do not try to exit on phase RES 
	-- TODO GET status

	local ondetect_status = util.get_safe_d( 400, config, "status" )
	local ondetect_headers = util.get_safe_d( {}, config, "headers_tbl" )
	local ondetect_body = util.get_safe_d( "", config, "body" )

	return ondetect_status, ondetect_body, ondetect_headers
end

local function optimize(config)
	if config.optimized then return true end

	config.headers_tbl = {}
	if config.headers then
		for i = 1, #config.headers do
			config.headers_tbl[ config.headers[i].key ] = config.headers[i].value
		end
	end
	config.optimized = true
end

local _M = core:extend()

_M.PRIORITY = 100 + 1

function _M:init_handler( config )
	optimize(config)
	self:add_global_handler( "ondetect", h, config)
end


return _M
