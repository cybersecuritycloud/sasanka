local core = require "kong.plugins.ssk-core.core"
local util = require "kong.plugins.ssk-core.lib.utils"

local escape_control_map = {
        ["\b"] = "\\b",  -- 8, backspace
        ["\t"] = "\\t",  -- 9, horizontal tab
        ["\n"] = "\\n",  -- 10, line feed
        ["\v"] = "\\v",  -- 11, vertical tab
        ["\f"] = "\\f",  -- 12, form feed
        ["\r"] = "\\r",  -- 13, carriage return
        ["\""] = "\\\"",  -- 34, double quote
        ["\'"] = "\\\'",  -- 39, single quote
        ["\\"] = "\\\\",  -- 92, backslash
}
local urlencode_control_map = {
        ["\b"] = "%08",  -- 8, backspace
        ["\t"] = "%09",  -- 9, horizontal tab
        ["\n"] = "%0A",  -- 10, line feed
        ["\v"] = "%0B",  -- 11, vertical tab
        ["\f"] = "%0C",  -- 12, form feed
        ["\r"] = "%0D",  -- 13, carriage return
        ["\""] = "%22",  -- 34, double quote
        ["\'"] = "%27",  -- 39, single quote
        ["\\"] = "%5C",  -- 92, backslash
}

local CONTROL_CHAR_RANGE = 32
local LOG_LEN = 8192

local function encode_escape_ctrl( v )
        local result = {}
        local result_idx = 1
        for i = 1, #v do
                local c = v:sub(i, i)
                if escape_control_map[c] then
                        result[result_idx] = escape_control_map[c]
                        result_idx = result_idx + 1
                elseif string.byte(c) < CONTROL_CHAR_RANGE then
                        result[result_idx] = " "
                        result_idx = result_idx + 1
                else
                        result[result_idx] = c
                        result_idx = result_idx + 1
                end
        end

        return table.concat(result)
end

local function encode_url_ctrl( v )
        local result = {}
        local result_idx = 1
        for i = 1, #v do
                local c = v:sub(i, i)
                if urlencode_control_map[c] then
                        result[result_idx] = urlencode_control_map[c]
                        result_idx = result_idx + 1
                elseif string.byte(c) < CONTROL_CHAR_RANGE then
                        result[result_idx] = " "
                        result_idx = result_idx + 1
                else
                        result[result_idx] = c
                        result_idx = result_idx + 1
                end
        end

        return table.concat(result)
end

local function encode( v, enc )
        if enc == "url" then
                return ngx.escape_uri( v )
        elseif enc == "url_ctrl" then
                return encode_url_ctrl( v )
        elseif enc == "base64" then
                return ngx.encode_base64( v )
        elseif enc == "escape_ctrl" then
                return encode_escape_ctrl( v )
        end
        --else enc == "none"
        return v
end

local function inspect( t, config )
        local ret = ""
        local is_first = true
        local is_array = false
        for k, v  in pairs (t) do
                if not is_first then
                        ret = ret .. ", "
                end
                is_first = false

                if type( k ) == "string" then
                        ret = ret .. '"' .. k ..'" : '
                else
                        is_array = true
                end

                if type( v ) == "table" then
                        ret = ret .. inspect( v, config )
                elseif type ( v ) == "string" then
                        ret = ret .. '"' .. encode( v, config.encode ) ..'"'
                else
                        ret = ret .. tostring( v )
                end
        end

        if is_array then
                return "[" .. ret .. "]"
        else
                return "{" .. ret .. "}"
        end

end

local function filter( detect_info )
        if detect_info.details then
                for k, v in pairs( detect_info.details ) do
                        if type ( v ) == "string" then
                                detect_info.details[k] = v:sub(1,LOG_LEN)
                        end
                end
        end
end

local function h( detect_info, config )
        local header = util.get_safe_d( "", config, "header" )
        config.handler( header, detect_info )
        return
end


local function init( config )
        if not config.inited then
                config.inited = true
                if config.std == "out" then
                        config.handler = function ( header, detect_info)
                                if not detect_info.silence then
                                        filter(detect_info)
                                        io.stdout:write( header .. inspect(detect_info, config) .. "\n" )
                                end
                        end
                end
                if config.std == "err" then
                        config.handler = function ( header, detect_info)
                                if not detect_info.silence then
                                        filter(detect_info)
                                        io.stderr:write( header ..  inspect(detect_info, config) .. "\n")
                                end
                        end
                end
        end
end

local _M = core:extend()
_M.PRIORITY = 100 + 2

function _M:init_handler( config )
        init( config )

        self:add_global_handler( "ondetect", h, config)
end


return _M
