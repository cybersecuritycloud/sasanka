local core = require "kong.plugins.ssk-core.core"
local util = require "kong.plugins.ssk-core.lib.utils"

local RULE_ID_SAFEHOST_BASE = 20
local RULE_ID_SAFEHOST_NO_HOST = 21
local RULE_ID_SAFEHOST_NOT_MATCHED = 22

local function h( params, config )
	local host_check = config.host_check
	local host = util.get_safe(params, "host")
	if host == nil then
		return { rule_id = RULE_ID_SAFEHOST_NO_HOST,  args = { host_check } }
	end
	if host ~= host_check then
		return { rule_id = RULE_ID_SAFEHOST_NOT_MATCHED,  args = { host_check, host } }
	end
end

local _M = core:extend()

_M.PRIORITY = 100

function _M:init_handler( config )
	self:add_handler( "req_header", h, config)
end


return _M
