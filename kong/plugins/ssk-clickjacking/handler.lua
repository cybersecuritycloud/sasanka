local core = require "kong.plugins.ssk-core.core"

local function add_header( k, subj )
	if subj then
		kong.response.set_header(k, subj)
	end
end

local function h_res_header( params, config )
	add_header( "X-Frame-Options", config["policy"] )
end


local _M = core:extend()
_M.PRIORITY = 100

function _M:init_handler( config )
	self:add_handler( "res_header", h_res_header, config)
end


return _M
