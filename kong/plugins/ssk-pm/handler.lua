local core = require "kong.plugins.ssk-core.core"
local util = require "kong.plugins.ssk-core.lib.utils"
local pm = require "kong.plugins.ssk-pm.patternmatcher"

local RULE_ID_PATTERNMATCH_BASE = 10

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

	if config["ud_list"] then return end
	
	config["ud_list"] = {}	
	if config["patterns"] then
		for i = 1, #config["patterns"] do
			local opt = 10
			local cache_key = config["patterns"][i]["name"]
			config["ud_list"][cache_key] = pm.optimize( config["patterns"][i]["patterns"], opt )
		end
	end

	config["params_in"] = make_dict_by_in( config["params"] )
end


local function check_same( p1, p2 )
	if p2 == nil then return true end
	if p2 == "*" then return true end
	if p1 == p2 then return true end
	return false
end

local function run_match( subj, patterns, keys)
	for i = 1, #keys do
		local ud = util.get_safe( patterns, keys[i])
		if ud then 
			local a, b = pm.detect_tbl(tostring(subj), ud)
			if a then
				return {rule_id = RULE_ID_PATTERNMATCH_BASE,  args = { keys[i], nil, subj, subj:sub(a,b) } }
			end
		end
	end
end

local function h(cat, k, v, params, ud_list, ...)
	for i = 1, #params do
		if check_same( k, params[i]["key"] ) then
			local e = run_match( v, ud_list, params[i]["patterns"])
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
		self:add_param_handler( cat, config, h, params, config["ud_list"] )
	end
end


return _M
