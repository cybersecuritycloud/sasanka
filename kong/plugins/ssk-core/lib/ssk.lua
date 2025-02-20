local util = require "kong.plugins.ssk-core.lib.utils"

-- kong.request.get_path
--- on kong 2.0: unnormalized path
--- on kong 3.0: normalized path
local function get_raw_path()
        if kong.request.get_raw_path then
                -- on kong3.0
                return kong.request.get_raw_path()
        else
                -- on kong2.0
                return kong.request.get_path()
        end
end

-- on kong, ngx: get_query will return value which url decoded once
local function get_query()
        local q = kong.request.get_raw_query()
        return util.parse_urlencoded_kv( q )
end


local function get_ip_bin()
        local ip_bin = ngx.var.binary_remote_addr
        if kong.ctx.shared.cap.ip_bin then
                ip_bin = kong.ctx.shared.cap.ip_bin
        end
        return ip_bin
end

local function get_ip()
        local ip = ngx.var.remote_addr
        if kong.ctx.shared.cap.ip then
                ip = kong.ctx.shared.cap.ip
        end
        return ip
end

local function get_id()
        return get_ip_bin()
end

-- plugin_ctx
-- in case of optimization, use shared.ctx
local function get_ctx( key )
        if kong.ctx.shared.cap.optimize then
                if kong.ctx.shared.cap.plugin[key] == nil then
                        kong.ctx.shared.cap.plugin[key] = {}
                end
                return kong.ctx.shared.cap.plugin[key]
        else
                return kong.ctx.plugin
        end
end

-- shared_ctx
local function get_shared_ctx()
        return kong.ctx.shared.cap
end

return {
        get_raw_path = get_raw_path,
        get_query = get_query,
        get_ip = get_ip,
        get_ip_bin = get_ip_bin,
        get_id = get_id,
        get_ctx = get_ctx,
        get_shared_ctx = get_shared_ctx,
}
