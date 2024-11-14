local core = require "kong.plugins.ssk-core.core"
local ssk = require "kong.plugins.ssk-core.lib.ssk"
local matcher = require "kong.plugins.ssk-core.lib.matcher"

-- luacheck: no unused
local CODE_STRICTPARAM = 1800
local DETECT_CODE_STRICTPARAM_BASE = CODE_STRICTPARAM
-- luacheck: unused
local DETECT_CODE_STRICTPARAM_TYPE = 1801
local DETECT_CODE_STRICTPARAM_REQUIRED = 1802
local DETECT_CODE_STRICTPARAM_MIN = 1803
local DETECT_CODE_STRICTPARAM_MAX = 1804


-- https://swagger.io/specification/#dataTypeFormat
local function build()
        local ret = {}

        ret["boolean"] = matcher.build( "^(true|false)$" )
        ret["int"] = matcher.build( "^[0-9]+$" )
        ret["integer"] = matcher.build( "^[0-9]+$" )
        ret["number"] = matcher.build( "^[+-]?\\d+([.]\\d+([Ee][+-]\\d+)?)?$" )
        ret["uuid"] = matcher.build( "^[0-9a-fA-F-]+$" )
        local full_date = '\\d{4}-\\d{2}-\\d{2}'
        local time_delta = '(Z|[+-]\\d{2}:\\d{2})'
        local full_time = '\\d{2}:\\d{2}:\\d{2}([.]\\d+)?' .. time_delta
        local date_time = full_date .. "T" .. full_time

        ret["date"] = matcher.build( "^".. full_date .. "$" )
        ret["date-time"] = matcher.build( "^".. date_time .. "$" )

        return ret
end


local function make_param_map( params )
        local ret  = {}
        if params then
                for i = 1, #params do
                        local cat = params[i]["in"]
                        local key = params[i]["key"]
                        if not cat then cat = "param_req_*" end

                        if not ret[cat] then
                                ret[cat] = {}
                        end

                        if params[i]["type"] == "regex" and params[i]["pattern"] then
                                params[i]["pattern_ud"] = matcher.build(params[i]["pattern"])
                        end

                        ret[cat][key] = params[i]
                end
        end

        return ret
end

local function make_req_map( params )
        local ret = {}
        if params then
                for i = 1, #params do
                        if params[i]["required"] then
                                local cat = params[i]["in"]
                                if not ret[cat] then
                                        ret[cat] = {}
                                end
                                local key = params[i]["key"]
                                ret[cat][key] = false
                        end
                end
        end

        return ret
end


local _M = core:extend()

function _M:initialize_global()
        if not self.type_tbl then
                self.type_tbl = build()
        end
end

local function initialize( config )

        if config["param_map"] == nil then
                config["param_map"] = make_param_map( config["params"] )
        end

        ssk.get_ctx(CODE_STRICTPARAM).required_map = make_req_map( config["params"] )
end



local function check_regex( pattern_ud, target )
        local a, _ = matcher.match( target, pattern_ud, 1, 0 )
        if a ~= nil then return true end
        return false
end

local function check_type( t, target )
        -- if not defined type, allow
        if not _M.type_tbl[t] then
                return true
        end

        local a, _ = matcher.match( target, _M.type_tbl[t], 1, 0 )

        if a ~= nil then return true end
        return false
end

local function h( cat, k, v, _, params, tags )

        local param = params[k]

        if param then
                if param["required"] then
                        ssk.get_ctx(CODE_STRICTPARAM).required_map[cat][k] = true
                end

                if param["type"] ~= nil then
                        if param["type"] == "regex" and param["pattern_ud"] then
                                if not check_regex( param["pattern_ud"], v ) then
                                        return { detect_code = DETECT_CODE_STRICTPARAM_TYPE, tags = tags,
                                                details = {
                                                        ["key"] = param["key"],
                                                        ["value"] = v,
                                                        ["type"] = param["type"],
                                                        ["pattern"] = param["pattern"]
                                                }}
                                end
                        else
                                if not check_type( param["type"], v) then
                                        return { detect_code = DETECT_CODE_STRICTPARAM_TYPE, tags = tags,
                                                details = {
                                                        ["key"] = param["key"],
                                                        ["value"] = v,
                                                        ["type"] = param["type"]
                                                }}
                                end
                        end
                end
                if param["min"] ~= nil then
                        if param["type"] == "int" or
                                param["type"] == "integer" or
                                param["type"] == "number" then
                                local num = tonumber( v )
                                if num == nil then
                                        return { detect_code = DETECT_CODE_STRICTPARAM_TYPE, tags = tags,
                                                details = {
                                                        ["key"] = param["key"],
                                                        ["value"] = v,
                                                        ["type"] = param["type"]
                                                }}
                                end
                                if num < param["min"] then
                                        return { detect_code = DETECT_CODE_STRICTPARAM_MIN, tags = tags,
                                                details = {
                                                        ["key"] = param["key"],
                                                        ["value"] = v,
                                                        ["min"] = param["min"]
                                                }}
                                end
                        else
                                if string.len(v) < param["min"] then
                                        return { detect_code = DETECT_CODE_STRICTPARAM_MIN, tags = tags,
                                                details = {
                                                        ["key"] = param["key"],
                                                        ["value"] = v,
                                                        ["min"] = param["min"]
                                                }}
                                end
                        end
                end

                if param["max"] ~= nil then
                        if param["type"] == "int" or
                                param["type"] == "integer" or
                                param["type"] == "number" then
                                local num = tonumber( v )
                                if num == nil then
                                        return { detect_code = DETECT_CODE_STRICTPARAM_TYPE, tags = tags,
                                        details = {
                                                ["key"] = param["key"],
                                                ["value"] = v,
                                                ["type"] = param["type"]
                                        }}
                                end
                                if num > param["max"] then
                                        return { detect_code = DETECT_CODE_STRICTPARAM_MAX, tags = tags,
                                        details = {
                                                ["key"] = param["key"],
                                                ["value"] = v,
                                                ["max"] = param["max"]
                                        }}
                                end
                        else
                                if string.len(v) > param["max"] then
                                        return { detect_code = DETECT_CODE_STRICTPARAM_MAX, tags = tags,
                                        details = {
                                                ["key"] = param["key"],
                                                ["value"] = v,
                                                ["max"] = param["max"]
                                        }}
                                end
                        end
                end
        end
end

local function after_access( tags )
        for _, params in pairs( ssk.get_ctx(CODE_STRICTPARAM).required_map ) do
                for k,v in pairs( params ) do
                        if not v then
                                return { detect_code = DETECT_CODE_STRICTPARAM_REQUIRED, tags = tags,
                                        details = {
                                                ["key"] = k
                                        }}
                        end
                end
        end
end


function _M:init_handler( config )
        self:initialize_global()
        initialize(config)

        for cat, params in pairs( config["param_map"] ) do
                self:add_param_handler( cat, config, h, params, config.tags )
        end

        self:add_handler( "after_access", after_access, config.tags )
end


return _M
