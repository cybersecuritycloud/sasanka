local core = require "kong.plugins.ssk-core.core"
local util = require "kong.plugins.ssk-core.lib.utils"

local RULE_ID_ALLOWKEY_BASE = 2500

local function h( cat, k, v, allowed, tags )
	kong.log.inspect( k, allowed )
	if not allowed[k] then
		kong.log.inspect(tags)
		return { rule_id = RULE_ID_ALLOWKEY_BASE, args = { k }, tags = tags }
	end
end


local function listtodict( l )
	local d = {}
	for _, v in ipairs(l) do
       		d[v] = true
    	end
	return d
end


local function initialize( config )
	if config.inited then
		return
	end
	
	config.inited = true
	config.dict = {}

	if util.get_safe_d( false, config, "query" ) then
		config.dict.query = listtodict( config.query )
	end
	if util.get_safe_d( false, config, "cookie" ) then
		config.dict.cookie = listtodict( config.cookie )
	end
	if util.get_safe_d( false, config, "header" ) then
		config.dict.header = listtodict( config.header )
	end
	if util.get_safe_d( false, config, "body" ) then
		config.dict.body = listtodict( config.body )
	end
end


local _M = core:extend()

function _M:init_handler( config )
	initialize(config)

	kong.log.inspect( config )
	if config.dict.query then
		self:add_param_handler( "param_req_query", config, h, config.dict.query, config.tags )
	end
	if config.dict.cookie then
		self:add_param_handler( "param_req_cookie", config, h, config.dict.cookie, config.tags )
	end
	if config.dict.header then
		self:add_param_handler( "param_req_header", config, h, config.dict.header, config.tags )
	end
	if config.dict.body then
		self:add_param_handler( "param_req_body", config, h, config.dict.body, config.tags )
	end

end


return _M
