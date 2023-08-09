local core = require "kong.plugins.ssk-core.core"
local util = require "kong.plugins.ssk-core.lib.utils"
local pm = require "kong.plugins.ssk-pm.patternmatcher"

local RULE_ID_LIBINJECTION_BASE = 60
local RULE_ID_LIBINJECTION_SQL = 61
local RULE_ID_LIBINJECTION_XSS = 62


local function make_dict_by_in( params )
	local ret  = {}
	if params then
		for i = 1, #params do
			local cat = params[i]["in"]
			if not cat then cat = "param_req_*" end
			
			if not ret[cat] then
				ret[cat] = {}
			end
			table.insert( ret[cat], params[i] )
		end
	end

	return ret
end


local function initialize()
	local config = kong.ctx.plugin.config

	if not config["params_in"] then
		config["params_in"] = make_dict_by_in( config["params"] )
	end
end


local function check_same( p1, p2 )
	if p2 == nil then return true end
	if p2 == "*" then return true end
	if p1 == p2 then return true end
	return false
end

local function run_match( subj, param_config )
	local libinjection = require "kong.plugins.ssk-libinjection.libinjection"
	
	if param_config.sql then
		local d, fingerprint = libinjection.sqli(subj)
		if d then
			return { rule_id = RULE_ID_LIBINJECTION_SQL, args = { subj, fingerprint } }
		end
	end

	if param_config.xss then
		local d, fingerprint = libinjection.xss(subj)
		if d then
			return { rule_id = RULE_ID_LIBINJECTION_XSS, args = { subj, fingerprint } }
		end
	end
	
	return nil	
end

local function h(cat, k, v, params, ...)
	if type(v) ~= "string" then return end
	for i = 1, #params do
		if check_same( k, params[i]["key"] ) then
			local e = run_match( v, params[i] )
			if e then 
				e.args[2] = k 
				return e
			end
		end
	end

end

local _M = core:extend()
function _M:init_handler( config )
	initialize()

	for cat, params in pairs( config["params_in"] ) do
		self:add_param_handler( cat, config, h, params )
	end
end


return _M
