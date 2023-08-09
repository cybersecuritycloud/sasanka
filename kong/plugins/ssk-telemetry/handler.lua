local core = require "kong.plugins.ssk-core.core"
local util = require "kong.plugins.ssk-core.lib.utils"

local EMITTER_INTERVAL_TIME = 5

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



local telemetry_map = {}

local function new_telemetry( path )
	local ret = {}
	ret.transaction_time = 0
	ret.kong_request_delay = 0
	ret.kong_request_time = 0
	ret.endpoint_latency = 0
	ret.kong_response_time = 0
	ret.count = 0
	ret.path = path

	return ret
end

local function h( config )
	local path = util.get_safe_d(nil, ngx.ctx, "router_matches", "uri")
	if not path then
		return
	end
	
	if not telemetry_map[ path ] then
		telemetry_map[ path ] = new_telemetry( path )
	end
		
	telemetry_map[path].transaction_time = telemetry_map[path].transaction_time +
		( ngx.ctx.KONG_LOG_START - ngx.ctx.KONG_PROCESSING_START )
	telemetry_map[path].kong_request_delay = telemetry_map[path].kong_request_delay +
		( ngx.ctx.KONG_ACCESS_ENDED_AT - ngx.ctx.KONG_ACCESS_START )
	telemetry_map[path].kong_request_time = telemetry_map[path].kong_request_time +
		( ngx.ctx.KONG_BALANCER_ENDED_AT - ngx.ctx.KONG_PROCESSING_START )
	telemetry_map[path].endpoint_latency = telemetry_map[path].endpoint_latency +
		( ngx.ctx.KONG_HEADER_FILTER_START - ngx.ctx.KONG_BALANCER_ENDED_AT )
	telemetry_map[path].kong_response_time = telemetry_map[path].kong_response_time +
		( ngx.ctx.KONG_BODY_FILTER_ENDED_AT - ngx.ctx.KONG_HEADER_FILTER_START )
	telemetry_map[path].count = telemetry_map[path].count + 1
end



-- as global plugin
local _M = core:extend()
_M.header = ""
_M.tag = nil
_M.std = "out"

_M.PRIORITY = 100

local function async_emitter()
	-- TODO : send somewhere?
	local t_map = {}
	t_map.duration = EMITTER_INTERVAL_TIME
	t_map.data = telemetry_map
	if _M.tag then
		t_map.tag = _M.tag
	end

	telemetry_map = {}

	--	kong.log.inspect( _M.header .. inspect(t_map) .. "\n")
	if _M.std == "err" then
		io.stderr:write( _M.header .. inspect(t_map) .. "\n")
	elseif _M.std == "out" then
		io.stdout:write( _M.header .. inspect(t_map) .. "\n")
	end

end

-- ngx.timer.every will create 'fake' connection every that time.
-- it will release its thread memory by intervaltime (maybe)
local function start_emitter()
	ngx.timer.every( EMITTER_INTERVAL_TIME, async_emitter )
end


function _M:init_worker()
	_M.super.init_worker(self)	
	-- init send pool
	start_emitter()

end

function _M:init_handler( config )
	if config.tag then _M.tag = config.tag end
	if config.std then _M.std = config.std end
	if config.header then _M.header = config.header end

	self:add_handler( "log", h, config)
end


return _M
