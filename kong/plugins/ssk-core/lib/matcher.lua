local MODE_RE = 1
local MODE_PCRE2 = 2
local mode = MODE_RE

local function check_module( k )
	if package.loaded[k] then
		return true
	else
		for _, loader in ipairs(package.searchers or package.loaders) do
			local f = loader( k )
			if type(f) == "function" then
				package.preload[k] = f
				return true
			end
		end
		return false
	end
end

local function check_pcre()
	if check_module( 'rex_pcre2' ) then
		mode = MODE_PCRE2
	end
end

check_pcre()

local function build( p )
	if mode == MODE_PCRE2 then
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
		if err then kong.log.error( err ) end
		return from, to
	end
end

return {
	match = match,
	build = build,
}
