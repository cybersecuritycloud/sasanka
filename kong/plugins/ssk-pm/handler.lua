local core = require "kong.plugins.ssk-core.core"
local ssk = require "kong.plugins.ssk-core.lib.ssk"
local util = require "kong.plugins.ssk-core.lib.utils"
local pm = require "kong.plugins.ssk-pm.patternmatcher"

-- luacheck: no unused
local DETECT_CODE_PATTERNMATCH_BASE = 200
-- luacheck: unused
local DETECT_CODE_PATTERNMATCH_MATCHED = 201

local function get_overwritten( param, dict, v )
        local ret = util.get_safe_d( {}, param, "customize", v )
        if util.isempty( ret ) then
                ret = util.get_safe_d( {}, dict, v )
        end
        return ret
end

local function merge_dict_by_in( config, pattern_dict )

        local ret = {}

        local params = config["params"]
        if params then
                for i = 1, #params do
                        local p = params[i]["patterns"]

                        for ii = 1, #p do

                                local obj = {}
                                local cache_key = p[ii]
                                local found = pattern_dict[cache_key]
                                -- TODO: fix me : array to single
                                obj["patterns"] = { cache_key }

                                obj["key"] = get_overwritten(params[i], found, "key")
                                obj["in"] = get_overwritten(params[i], found, "in")
                                obj["tags"] = get_overwritten(params[i], found, "tags")

                                if util.isempty(obj["in"]) then
                                        local cat = "param_req_*"
                                        if not ret[cat] then
                                                ret[cat] = {}
                                        end

                                        table.insert( ret[cat], obj )
                                end

                                for iii = 1, #obj["in"] do
                                        local cat = obj["in"][iii]
                                        if not ret[cat] then
                                                ret[cat] = {}
                                        end

                                        table.insert( ret[cat], obj )
                                end
                        end

                end
        end

        return ret
end


local function initialize( config, pattern_dict)
        if config["pattern_dict"] then return end

        if pattern_dict then
                config["pattern_dict"] = pattern_dict
        else
                config["pattern_dict"] = {}
                if config["patterns"] then
                        for i = 1, #config["patterns"] do
                                local opt = 10
                                local cache_key = config["patterns"][i]["name"]
                                config["pattern_dict"][cache_key] = config["patterns"][i]
                                config["pattern_dict"][cache_key]["ud_list"] = pm.optimize( config["patterns"][i]["patterns"], opt )
                        end
                end
        end

        config["params_in"] = merge_dict_by_in( config, config["pattern_dict"] )

end


local function check_include( stack, needle)
        if util.isempty(stack) then return true end
        for i = 1, #stack do
                if stack[i] == "*" then return true end
                if stack[i] == needle then return true end
        end
        return false
end

local function run_match( subj, pattern_dict, keys )
        for i = 1, #keys do
                local ud = util.get_safe( pattern_dict, keys[i], "ud_list" )
                if ud then
                        local a, _ = pm.detect_tbl(tostring(subj), ud)
                        if a then
                                local tags = util.get_safe( pattern_dict, keys[i], "tags" )
                                return {detect_code = DETECT_CODE_PATTERNMATCH_MATCHED, tags = tags,
                                        details = {["pattern"]=keys[i], ["key"]="", ["value"]=subj}}
                        end
                end
        end
end

local function h(_, k, _, v_list, params, pattern_dict )
        for i = 1, #params do
                if check_include( params[i]["key"], k ) then
                        for _, decoded in ipairs( v_list ) do
                                local e = run_match( decoded, pattern_dict, params[i]["patterns"] )
                                if e then
                                        e.details["key"] = k
                                        return e
                                end
                        end
                end
        end

end

local _M = core:extend()
function _M:init_handler( config )

        local pattern_dict = nil
        if ssk.get_shared_ctx().pattern_dict then
                pattern_dict = ssk.get_shared_ctx().pattern_dict
        end

        initialize( config, pattern_dict )

        for cat, params in pairs( config["params_in"] ) do
                self:add_param_handler( cat, config, h, params, config["pattern_dict"] )
        end
end


return _M
