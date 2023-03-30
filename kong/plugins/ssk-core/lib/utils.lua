local function get_safe( tbl, ... )
	local ret = tbl
	local arg = {...}
	for i,v in ipairs(arg) do
		if ret == nil or v == nil then return nil end
		ret = ret[v]
	end
	return ret
end

local function get_safe_d( default, tbl, ... )
	local ret = tbl
	local arg = {...}
	for i,v in ipairs(arg) do
		if ret == nil or v == nil then return default end
		ret = ret[v]
	end
	if ret == nil then return default end
	return ret
end

local function keys( tbl )
	local i = 0
	local ret = {}
	for k,v in pairs(tbl) do
		i = i + 1
  		ret[i] = k
	end
	return ret
end

local function merge(tbl_l, tbl_r)
	for k, v in pairs(tbl_r) do
		if tbl_l[k] == nil then
			tbl_l[k] = tbl_r[k]
		else
			if type(tbl_l[k])=="table" then
				merge(tbl_l[k], tbl_r[k])
			end
		end
	end
	return tbl_l
end
local function isempty( tbl )
	local next = next
	if tbl == nil or next(tbl) == nil then
		return true
	end
	return false
end

local function split( str, tok)
	if not tok then return {str} end
	local ret= {};

	local i = 1 
	for s in string.gmatch(str, "([^"..tok.."]+)") do
		ret[i] = s
		i = i + 1
	end

	return ret
end


return {
	get_safe = get_safe,
	get_safe_d = get_safe_d,

	keys = keys,
	merge = merge,
	isempty = isempty,
	
	split = split,
}
