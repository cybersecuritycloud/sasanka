local core = require "kong.plugins.ssk-core.core"
local util = require "kong.plugins.ssk-core.lib.utils"

-- luacheck: no unused
local CODE_LIBINJECTION_BASE = 1300
local DETECT_CODE_LIBINJECTION_BASE = CODE_LIBINJECTION_BASE
-- luacheck: unused
local DETECT_CODE_LIBINJECTION_SQL = 1301
local DETECT_CODE_LIBINJECTION_XSS = 1302


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


local function initialize( config )
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
        if not libinjection.try_load() then
                kong.log.err( "!! libinjection not loaded !!")
                return
        end

        if param_config.sql then
                local d, fingerprint = libinjection.sqli(subj)
                if d then
                        return { detect_code = DETECT_CODE_LIBINJECTION_SQL, details={ ["fingerprint"]=fingerprint } }
                end
        end

        if param_config.xss then
                local d, fingerprint = libinjection.xss(subj)
                if d then
                        return { detect_code = DETECT_CODE_LIBINJECTION_XSS, details={ ["fingerprint"]=fingerprint } }
                end
        end

        return nil
end

-- luacheck: no unused args
local function h_param(_, k, v, v_list, params, config, ...)
-- luacheck: unused args
        if type(v) ~= "string" then return end
        local e_list = {}
        for i = 1, #params do
                if check_same( k, params[i]["key"] ) then

                        for _, decoded in ipairs( v_list ) do
                                local e = run_match( decoded, params[i] )
                                if e then
                                        e.details["key"] = k
                                        e.details["value"] = v
                                        e.details["decoded"] = decoded
                                        e.tags = util.get_safe_d( {}, config, "tags" )
                                        table.insert(e_list, e)
                                end
                        end
                end
        end
        if #e_list > 0 then
                return { ["list"] = e_list }
        end

end

local function h_raw( v, v_list, params, config )
        if type(v) ~= "string" then return end
        local e_list = {}
        for i = 1, #params do
                for _, decoded in ipairs( v_list ) do
                        local e = run_match( decoded, params[i] )
                        if e then
                                e.details["value"] = v
                                e.details["decoded"] = decoded
                                e.tags = util.get_safe_d( {}, config, "tags" )
                                table.insert(e_list, e)
                        end
                end
        end

        if #e_list > 0 then
                return { ["list"] = e_list }
        end
end

local _M = core:extend()
function _M:init_handler( config )
        initialize( config )

        for cat, params in pairs( config["params_in"] ) do
                if cat == "req_path" or
                        cat == "req_query" or
                        cat == "req_body" then
                        self:add_handler( cat, h_raw, params, config )
                else
                        self:add_param_handler( cat, config, h_param, params, config )
                end
        end
end


return _M
