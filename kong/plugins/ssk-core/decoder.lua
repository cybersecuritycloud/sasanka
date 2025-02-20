local util = require "kong.plugins.ssk-core.lib.utils"

local decoder = nil
local function check_shydecoder()
        if util.check_module( "shydecoder" ) then
                decoder = require "shydecoder"
        end
end

check_shydecoder()


-- reference each other
local decode_list, decode_record
function decode_list( params, option )
        for i = 1, #params do
                local v = params[i]
                if type(v) == "table" then
                        if util.get_safe(v,1) then     --list
                                decode_list( params[i], option)
                        else
                                decode_record( params[i], option)
                        end
                else
                        if util.get_safe( option, "urldecode" )then
                                params[i] = ngx.unescape_uri(params[i])
                        end
                end
        end
end

function decode_record( params, option )
        for k, v in pairs(params) do
                if type(v) == "table" then
                        if util.get_safe(v,1) then     --list
                                decode_list( params[k], option)
                        else
                                decode_record( params[k], option)
                        end
                else
                        if util.get_safe( option, "urldecode" )then
                                params[k] = ngx.unescape_uri(params[k])
                        end
                end
        end
end

local function decode_body( params, option )
        if type(params) == "table" then
                if util.get_safe(params,1) then     --list
                        decode_list( params, option)
                else
                        decode_record( params, option)
                end
        end
end

local function build_decoded_list( v, option )
    local ret = { v }
    if type ( v ) ~= "string" then return ret end

    local max = util.get_safe_d(2, option, "decodemax" )
    local cur = v

        if util.get_safe( option, "unifydecode" ) and
                decoder then
                for i = 1, max do
                        -- 1. unifydecode
                        local result, suc = decoder.unify_decode( cur, 2 )
                        if suc and #cur ~= #result then
                                table.insert( ret, result )
                                cur = result
                        end

                        -- 2. base64decode
                        if util.get_safe( option, "base64decode" ) then
                                local result, suc = decoder.base64_decode( cur )
                                if suc and #cur ~= #result then
                                        local ret_inner = build_decoded_list( result, option )
                                        for _, v in ipairs( ret_inner ) do
                                                table.insert( ret, v )
                                        end
                                end
                        end
                end
        elseif decoder then
                for i = 1, max do
                        local more = false
                        -- 1. urldecode
                        if util.get_safe( option, "urldecode" ) then
                                local result = decoder.url_decode( cur )
                                if #cur ~= #result then
                                        table.insert( ret, result )
                                        more = true
                                        cur = result
                                end
                        end

                        -- 2. htmldecode
                        if util.get_safe( option, "htmldecode" ) and
                                decoder then
                                local result, suc = decoder.html_decode( cur, 2 )
                                if suc and #cur ~= #result then
                                        table.insert( ret, result )
                                        more = true
                                        cur = result
                                end
                        end

                        -- 3. escapedecode
                        if util.get_safe( option, "escapedecode" ) and
                                decoder then
                                local result, suc = decoder.escape_decode( cur, 2 )
                                if suc and #cur ~= #result then
                                        table.insert( ret, result )
                                        more = true
                                        cur = result
                                end
                        end

                        -- 4. base64decode
                        if util.get_safe( option, "base64decode" ) then
                                local result, _ = decoder.base64_decode( cur )
                                if result and #cur ~= #result then
                                        local ret_inner = build_decoded_list( result, option )
                                        for _, v in ipairs( ret_inner ) do
                                                table.insert( ret, v )
                                        end
                                end
                        end

                        if more ~= true then
                                break
                        end
                end
        else
                for i = 1, max do
                        local more = false
                        -- 1. urldecode
                        if util.get_safe( option, "urldecode" ) then
                                local result = ngx.unescape_uri( cur )
                                if #cur ~= #result then
                                        table.insert( ret, result )
                                        more = true
                                        cur = result
                                end
                        end

                        -- 2. base64decode
                        if util.get_safe( option, "base64decode" ) then
                                local result = ngx.decode_base64( cur )
                                if result and #cur ~= #result then
                                        local ret_inner = build_decoded_list( result, option )
                                        for _, v in ipairs( ret_inner ) do
                                                table.insert( ret, v )
                                        end
                                end
                        end

                        if more ~= true then
                                break
                        end
                end
        end

        return ret

end

return {
        decode_body = decode_body,
        build_decoded_list = build_decoded_list,
}
