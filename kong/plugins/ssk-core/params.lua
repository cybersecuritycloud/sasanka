local common = require "kong.plugins.ssk-core.common"
local util = require "kong.plugins.ssk-core.lib.utils"
local decoder = require "kong.plugins.ssk-core.decoder"

local function handle_param_list( cat, k, v_list )
        local options = kong.ctx.shared.cap.options[cat]
        local handlers = util.get_safe_d({}, kong.ctx.plugin.handlers, cat )
        for _, subv in ipairs(v_list) do
                local decoded_list = decoder.build_decoded_list(subv, options)
                for i = 1, #handlers do
                        local handler_info = handlers[i]
                        local e_new = handler_info.h( cat, k, nil, decoded_list, unpack(handler_info.args) )
                        common.store_detected( e_new )
                end
        end
end
local function handle_param( cat, k, v )
        local options = kong.ctx.shared.cap.options[cat]
        local handlers = util.get_safe_d({}, kong.ctx.plugin.handlers, cat )
        local decoded_list = decoder.build_decoded_list(v, options)
        for i = 1, #handlers do
                local handler_info = handlers[i]
                local e_new = handler_info.h( cat, k, v, decoded_list, unpack(handler_info.args) )
                common.store_detected( e_new )
        end
end

-- reference each other
local detect_param_record, detect_param_list
function detect_param_list( cat, prefix, params )
        for i = 1, #params do
                local v = params[i]
                if type(v) == "table" then
                        if util.get_safe(v,1) then     --list
                                detect_param_list( cat, prefix .. "[]", v )
                        else
                                detect_param_record( cat, prefix  .. ".", v )
                        end
                else
                        handle_param( cat, prefix, v )
                end
        end
end

function detect_param_record( cat, prefix, params )
        for k, v in pairs(params) do
                if type(v) == "table" then
                        if util.get_safe(v,1) then     --list
                                detect_param_list( cat, prefix .. k .. "[]", v )
                        else
                                detect_param_record( cat, prefix .. k .. ".", v )
                        end
                else
                        handle_param( cat, prefix .. k, v )
                end
        end
end

local function detect_param_urlencoded(cat, params )
        for k, v in pairs(params) do
                if type(v) == "table" then
                        if util.get_safe(v,1) then     --list
                                local v_merged = ""
                                for _, subv in ipairs(v) do
                                        if type(subv) == "string" then
                                                v_merged = v_merged .. subv
                                        -- else
                                                -- not allowed
                                        end
                                end
                                table.insert( v, v_merged )
                                handle_param_list( cat, k, v )
                        -- else
                                -- not allowed
                        end

                else
                        handle_param( cat, k, v )
                end
        end
end


local function detect_param_main( cat, v )
        if type(v) == "table" then
                if util.get_safe(v,1) then     --list
                        detect_param_list( cat, "[]", v )
                else
                        detect_param_record( cat, "", v )
                end
        else
                handle_param( cat, "", v)
        end
end

return {
        detect_param_urlencoded = detect_param_urlencoded,
        detect_param_main = detect_param_main,
}
