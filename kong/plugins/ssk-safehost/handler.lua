local core = require "kong.plugins.ssk-core.core"
local util = require "kong.plugins.ssk-core.lib.utils"

-- luacheck: no unused
local DETECT_CODE_SAFEHOST_BASE = 300
-- luacheck: unused
local DETECT_CODE_SAFEHOST_NO_HOST = 301
local DETECT_CODE_SAFEHOST_NOT_MATCHED = 302

local function h( params, config )
        local host_check = config.host_check
        local host = util.get_safe(params, "host")
        if host == nil then
                return { detect_code = DETECT_CODE_SAFEHOST_NO_HOST, tags = config.tags,
                        details = {["expected"]=host_check}}
        end
        if host ~= host_check then
                return { detect_code = DETECT_CODE_SAFEHOST_NOT_MATCHED, tags = config.tags,
                        details = {["expected"]=host_check, ["input"]=host}}
        end
end

local _M = core:extend()

_M.PRIORITY = 100

function _M:init_handler( config )
        self:add_handler( "req_header", h, config)
end


return _M
