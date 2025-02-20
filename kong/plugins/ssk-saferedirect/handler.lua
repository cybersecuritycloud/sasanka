local core = require "kong.plugins.ssk-core.core"

-- luacheck: no unused
local DETECT_CODE_SAFEREDIRECT_BASE = 1500
-- luacheck: unused
local DETECT_CODE_SAFEREDIRECT_NOT_MATCHED = 1501

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

local function initialize(config)
        if config["params_in"] then return end

        config["params_in"] = make_dict_by_in( config["params"] )
end

-- luacheck: no unused args
local function h( _, k, v, v_list, params, tags, ...)
-- luacheck: unused args
        for i = 1, #params do
                if params[i]["key"] == k then
                        -- check if one of v_list matched at least
                        local found = false;
                        for ii = 1, #v_list do
                                local v_decoded = v_list[ii]
                                local v_shorted  = string.sub( v_decoded, 1, #params[i]["prefix"] )
                                if v_shorted == params[i]["prefix"] then
                                        found = true;
                                end
                        end
                        if not found then
                                return { detect_code = DETECT_CODE_SAFEREDIRECT_NOT_MATCHED, tags = tags,
                                        details = { ["key"]=k, ["value"]=v, ["expected"]=params[i]["prefix"] } }
                        end
                end
        end
end

local _M = core:extend()

function _M:init_handler( config )
        initialize(config)

        for cat, params in pairs( config["params_in"] ) do
                self:add_param_handler( cat, config, h, params, config.tags )
        end
end


return _M
