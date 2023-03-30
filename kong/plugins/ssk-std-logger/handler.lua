local core = require "kong.plugins.ssk-core.core"
local util = require "kong.plugins.ssk-core.lib.utils"

local function inspect( t )
	local ret = ""
	local is_first = true
	local is_array = false
	for k, v  in pairs (t) do
		if not is_first then
			ret = ret .. ", "
		end
		is_first = false
		
		if type( k ) == "string" then
			ret = ret .. '"' .. k ..'" = '
		else
			is_array = true
		end

		if type( v ) == "table" then
			ret = ret .. inspect( v )
		elseif type ( v ) == "string" then
			ret = ret .. '"' .. tostring( v ) ..'"'
		else 
			ret = ret .. tostring( v )
		end
	end
	
	if is_array then
		return "[" .. ret .. "]"
	else
		return "{" .. ret .. "}"
	end
	
end

local function h( detect_info, config )
	config.handler( detect_info )
	return
end


local function init( config )
	if not config.inited then
		config.inited = true
		if config.std == "out" then
			config.handler = function (detect_info)
				io.stdout:write(inspect(detect_info) .. "\n" )
			end
		end
		if config.std == "err" then
			config.handler = function (detect_info)
				io.stderr:write(inspect(detect_info) .. "\n")
			end
		end
	end
end

local _M = core:extend()
_M.PRIORITY = 100 + 1

function _M:init_handler( config )
	init( config )

	self:add_global_handler( "ondetect", h, config)
end


return _M
