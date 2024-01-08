local core = require "kong.plugins.ssk-core.core"
local util = require "kong.plugins.ssk-core.lib.utils"


local RULE_ID_SAFEREDIRECT_BASE = 1500

local function make_dict_by_in( params )
	local ret  = {}
	if params then
		for i = 1, #params do
			local cat = params[i]["in"]
			if cat then
				if not ret[cat] then
					ret[cat] = {}
				end
				table.insert( ret[cat], params[i] )
			end
		end
	end

	return ret
end

local function initialize()
	local config = kong.ctx.plugin.config
	if config["params_in"] then return end

	config["params_in"] = make_dict_by_in( config["params"] )
end

local function h( cat, k, v, params, tags, ...)
	for i = 1, #params do
		if params[i]["key"] == k then
			local v_decoded =  ngx.unescape_uri( v )
			local v_shorted  = string.sub( v_decoded, 0, #params[i]["prefix"] )
			if v_shorted ~= params[i]["prefix"] then
				return { rule_id = RULE_ID_SAFEREDIRECT_BASE, args = { v }, tags = tags }
			end
		end
	end
end

local _M = core:extend()

function _M:init_handler( config )
	initialize()

	for cat, params in pairs( config["params_in"] ) do
		self:add_param_handler( cat, config, h, params, config.tags )
	end
end


return _M
