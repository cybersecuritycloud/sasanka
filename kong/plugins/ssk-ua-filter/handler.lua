local core = require "kong.plugins.ssk-core.core"
local util = require "kong.plugins.ssk-core.lib.utils"
local matcher = require "kong.plugins.ssk-core.lib.matcher"

-- luacheck: no unused
local DETECT_CODE_USERAGENT_BASE = 700
-- luacheck: unused
local DETECT_CODE_USERAGENT_NO_UA = 701
local DETECT_CODE_USERAGENT_UA_MATCHED = 702

local function match( ua, config, key )
        for _, pat in ipairs( util.get_safe_d({}, config, key) ) do
                local a, _ = matcher.match(ua, pat, 1 )
                if a then return true end
        end
        return false
end

local function h( params, config )
        local ua = util.get_safe( params, "user-agent" )

        if type(ua) ~= "string" then
                if util.get_safe( config, "block_no_useragent" ) then
                        return { detect_code = DETECT_CODE_USERAGENT_NO_UA, tags = config.tags }
                end
                return -- ignore useragent
        end
        if match( ua, config, "block_useragents" ) then
                return { detect_code = DETECT_CODE_USERAGENT_UA_MATCHED, tags = config.tags,
                        details = { ["ua"]=ua } }
        end
end

local _M = core:extend()

function _M:init_handler( config )
        self:add_handler( "req_header", h, config)
end


return _M
