local matcher = require "kong.plugins.ssk-core.lib.matcher"

local function build( patt )
	return matcher.build( patt )
end

-- for all match
-- rp.gmatch (subj, patt)

-- for single find 
-- rp.find(subj, patt)



local function detect_tbl( subj, patt_tbl, ignorecase )
	local flag = flag or false
	if patt_tbl == nil then
		return nil, nil
	end

	-- for lua5.2
	-- local ft = rp.flags()	
	-- ft["CASELESS"] = 8
	local cf = 0
	if ignorecase then
		cf = 8
	end

	for i=1, #patt_tbl do
		local a, b = matcher.match( subj, patt_tbl[i], 1, cf)
		if a ~= nil then
			return a, b
		end
	end

	return nil, nil
end

local function append_patterns(patterns)
	local appended = ""
	for i = 1, #patterns do
		appended = appended .. "(" .. patterns[i] .. ")"
		if i ~= #patterns then
			appended = appended .. "|"
		end
	end
	return appended
end


local function optimize(patterns, opt)
	local out = {}
	local buffer = {}
	for i = 1, #patterns do
		table.insert( buffer, patterns[i] )

		if #buffer % opt == 0 then
			table.insert( out, build( append_patterns(buffer)) )
			buffer = {}
		end
	end
	if #buffer ~= 0 then
		table.insert( out, build( append_patterns(buffer)) )
	end
	return out
end

return {
	optimize = optimize,
	append_patterns = append_patterns,
	detect = detect,
	detect_tbl = detect_tbl,
}
