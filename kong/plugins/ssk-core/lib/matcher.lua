local util = require "kong.plugins.ssk-core.lib.utils"

local MODE_RE = 1
local MODE_PCRE2 = 2
local mode = MODE_RE


local function check_pcre()
        if util.check_module( 'rex_pcre2' ) then
                mode = MODE_PCRE2
        end
end

check_pcre()

local function validate( p )
        local _, _, err = ngx.re.find( "s", p, "jo" )
        if err then
                kong.log.err( "pattern validate fail : ", err )
                return false
        end
        return true
end

local function build( p )
        if mode == MODE_PCRE2 then
                if not validate( p ) then
                        return p
                end

                local rp = require ('rex_pcre2')
                local userdata = rp.new( p )
                return userdata
        else
                return p
        end
end

local function match( subj, p, from, cf)
        if mode == MODE_PCRE2 then
                local rp = require ('rex_pcre2')
                local from, to = rp.find (subj, p, from, cf )
                return from, to
        else
                local from, to, err = ngx.re.find( subj, p, "jo" )
                if err then kong.log.err( err ) end
                return from, to
        end
end

return {
        match = match,
        build = build,
}
