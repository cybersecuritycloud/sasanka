local table = require "table"
local core = require "kong.plugins.ssk-core.core"
local util = require "kong.plugins.ssk-core.lib.utils"

-- luacheck: no unused
local DETECT_CODE_CORS_BASE = 400
-- luacheck: unused
local DETECT_CODE_CORS_ORIGIN_NOT_ALLOWED = 401
local DETECT_CODE_CORS_METHOD_NOT_ALLOWED = 402
local DETECT_CODE_CORS_HEADER_NOT_ALLOWED = 403


local function isInclude(needle, stack)
        for i = 1, #stack do
                if stack[i] == "*" then return true end
                if stack[i] == needle then return true end
        end
        return false
end

local function h_req_header( params, config )
        if config.block then
                -- origin
                if util.get_safe( config.allow_origins ) then
                        local subj = util.get_safe( params, "origin" )
                        if subj ~= nil and
                                not isInclude( subj, config.allow_origins ) then
                                return { detect_code = DETECT_CODE_CORS_ORIGIN_NOT_ALLOWED, tags = config.tags,
                                        details = { ["input"]=subj } }
                        end
                else
                        local subj = util.get_safe( params, "origin" )
                        if subj then
                                return { detect_code = DETECT_CODE_CORS_ORIGIN_NOT_ALLOWED, tags = config.tags,
                                        details = { ["input"]=subj } }
                        end
                end

                -- allow_methods
                if util.get_safe( config.allow_methods ) then
                        local subj = kong.request.get_method()
                        if not isInclude( subj, config.allow_methods ) then
                                return { detect_code = DETECT_CODE_CORS_METHOD_NOT_ALLOWED, tags = config.tags,
                                        details = { ["input"]=subj } }
                        end
                end

                -- allow_headers

                if util.get_safe( config.allow_headers ) then
                        for subj, _ in pairs(params) do
                                if not isInclude( subj, config.optimized_config.allow_headers ) then
                                        return { detect_code = DETECT_CODE_CORS_HEADER_NOT_ALLOWED, tags = config.tags,
                                                details = { ["input"]=subj } }
                                end
                        end
                end
        end
end

local function add_header_a( k, array )
        if array then
                if #array > 0 then
                        kong.response.set_header(k, table.concat(array, ", "))
                end
        end
end

local function add_header( k, subj )
        if subj then
                kong.response.set_header(k, subj)
        end
end

local function h_res_header( _, config )
        if config.modify_response_header then
                add_header_a( "Access-Control-Allow-Origin", config.allow_origins )
                add_header_a( "Access-Control-Allow-Methods", config.allow_methods )
                add_header_a( "Access-Control-Allow-Headers", config.allow_headers )
                add_header_a( "Access-Control-Expose-Headers", config.expose_headers )
                add_header( "Access-Control-Max-Age", config.max_age )
                add_header( "Access-Control-Allow-Credentials", config.allow_credentials )
        end
end


local _M = core:extend()
_M.PRIORITY = 100

local function make_lower( l )
        local ret = {}
        if not l then return ret end

        for i = 1, #l do
                table.insert(ret, l[i]:lower() )
        end
        return ret
end

local function optimize(config)
        if not config.optimized_config then
                config.optimized_config = {}
                config.optimized_config.allow_headers = make_lower( config.allow_headers )
        end
end

function _M:init_handler( config )
        optimize(config)
        self:add_handler( "req_header", h_req_header, config)
        self:add_handler( "res_header", h_res_header, config)
end


return _M
