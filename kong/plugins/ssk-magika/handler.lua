local core = require "kong.plugins.ssk-core.core"
local util = require "kong.plugins.ssk-core.lib.utils"

-- luacheck: no unused
local DETECT_CODE_MAGIKA_BASE = 3600
local DETECT_CODE_MAGIKA_NOT_ALLOWED = 3601
local DETECT_CODE_MAGIKA_DENY = 3602
-- luacheck: unused

local lumagika = nil
local function check_lumagika()
        if util.check_module( "liblumagika" ) then
                lumagika = require "liblumagika"
        end
end

check_lumagika()

local function magika( body )
        if not lumagika then
                kong.log.err( "!! magika not loaded !!")
                return "Unknown"
        end

	return lumagika.identify_content_label(body)
end


local function make_dict_by_in( params )
        local ret  = {}
        if params then
                for i = 1, #params do
                        local cat = params[i]["in"]
                        if not cat then cat = "req_body" end

                        if not ret[cat] then
                                ret[cat] = {}
                        end
                        table.insert( ret[cat], params[i] )
                end
        end

        return ret
end

local function check_same( p1, p2 )
        if p2 == nil then return true end
        if p2 == "*" then return true end
        if p1 == p2 then return true end
        return false
end

local function match( tbl, needle, default )
        if util.isempty( tbl ) then
                return default
        end

        return tbl[needle] == true
end

local function h_main( v, config )
        if type(v) ~= "string" then return end

        local label = magika(v)
        local matched = match( config.denys_tbl, label, false )
        if matched then
                return { detect_code = DETECT_CODE_MAGIKA_DENY, tags = config.tags,
                        details = { ["determined"]=label, ["value"]=v } }
        end

        matched = match( config.allows_tbl, label, true )
        if not matched then
                return { detect_code = DETECT_CODE_MAGIKA_NOT_ALLOWED, tags = config.tags,
                        details = { ["determined"]=label, ["value"]=v } }
        end

        return
end

local function h_req_body( v, _, config )
        return h_main(v, config)
end

local function h_req_param(_, k, v, _, params, config )
        for i = 1, #params do
                if check_same( k, params[i]["key"] ) then
                        local ret = h_main(v, config)
                        if ret then
                                return ret
                        end
                end
        end
end

local function h_res_body( body, config )
        return h_main(body, config)
end


local function initialize( config )
        if config["allows_tbl"] then return end

        config["allows_tbl"] = {}
        config["denys_tbl"] = {}
        if config["allows"] then
                for _, item in ipairs(config["allows"]) do
                        config["allows_tbl"][item] = true
                end
        end
        if config["denys"] then
                for _, item in ipairs(config["denys"]) do
                        config["denys_tbl"][item] = true
                end
        end
        config["params_in"] = make_dict_by_in( config["params"] )

end


local _M = core:extend()
_M.PRIORITY = 100

function _M:init_handler( config )
        initialize( config )

        if not config["params_in"] then
                self:add_handler( "req_body", h_req_body, config )
        else
                for cat, params in pairs( config["params_in"] ) do
                        if cat == "req_body" then
                                self:add_handler( cat, h_req_body, config )
                        elseif cat == "param_req_body" then
                                self:add_param_handler( cat, config, h_req_param, params, config )
                        elseif cat == "res_body" then
                                self:add_handler( cat, h_res_body, config )
                        end
                end
        end
end

return _M
