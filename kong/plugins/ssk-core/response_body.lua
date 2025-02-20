local zlib = require "zlib"

local function get_body_part()
        if kong.ctx.shared.cap.body_part then
                return kong.ctx.shared.cap.body_part
        end

        -- set body_part
        local enc = kong.response.get_header("content_encoding")
        if enc == nil or string.find(enc, "gzip") == nil then
                kong.ctx.shared.cap.body_part = ngx.arg[1]
                return kong.ctx.shared.cap.body_part
        end

        -- gzip
        if kong.ctx.shared.cap.inflate == nil then
                kong.ctx.shared.cap.inflate = zlib.inflate()
        end

        local decompressed, _, _, _ = kong.ctx.shared.cap.inflate(ngx.arg[1])
        kong.ctx.shared.cap.body_part = decompressed
        return kong.ctx.shared.cap.body_part
end

local function set_body_part( in_body )
        kong.ctx.shared.cap.body_part = in_body
end

local function get_deflated_body_part()
        if kong.ctx.shared.cap.body_part == nil then
                kong.ctx.shared.cap.body_part = get_body_part()
        end
        local opt = nil
        if ngx.arg[2] then
                opt = "finish"
        end
        local compressed, _, _, len_out = kong.ctx.shared.cap.deflate( kong.ctx.shared.cap.body_part , opt)

        return compressed, len_out
end

local function get_encoded_body()
        -- gzip
        if kong.ctx.shared.cap.deflate then
                return get_deflated_body_part()
        end

        -- normal
        local enc = kong.response.get_header("content_encoding")
        if  enc == nil or string.find(enc, "gzip") == nil then
                return get_body_part(), #get_body_part()
        end

        -- gzip

        kong.ctx.shared.cap.deflate = zlib.deflate(6,31)
        return get_deflated_body_part()

end


return {
        get_body_part = get_body_part,
        set_body_part = set_body_part,
        get_encoded_body = get_encoded_body,
}
