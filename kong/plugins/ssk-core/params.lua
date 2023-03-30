local common = require "kong.plugins.ssk-core.common" 
local util = require "kong.plugins.ssk-core.lib.utils"

local function match_path( configed_list, pathsplit )
	local pathconfig_pathparam = {}
	local pathconfig_len = 0
	for i = 1, #configed_list do
		local found = true
		local found_len = 0
		local apisplit = configed_list[i]
		local pathparam = {}
		if #pathsplit >= #apisplit then
			for j = 1, #apisplit do
				if apisplit[j]:sub(1,1) == "{" and apisplit[j]:sub(#apisplit[j],#apisplit[j]) == "}"  then
					local key = apisplit[j]:sub(2,#apisplit[j]-1)
					pathparam[key] = pathsplit[j]
				elseif pathsplit[j] == apisplit[j] then
					found_len = j
				else
					found = false
					break
				end
			end
		else
			found = false
		end
		if found then
			if found_len > pathconfig_len then
				pathconfig_pathparam = pathparam
			end
		end
	end

	return pathconfig_pathparam
end


local function detect_param_path( cat, pathsplit )
	local handlers = util.get_safe_d({}, kong.ctx.plugin.handlers, cat )
	for i = 1, #handlers do
		local handler_info = handlers[i]
		if handler_info.opt then -- needed splited path
			local path_params = match_path( handler_info.opt, pathsplit )
			for k, v in pairs(path_params) do
				local err = handler_info.h( cat, k, v, unpack(handler_info.args) )
				if err then return err end
			end
		end
	end
end

local function handle_param( cat, k, v )
	local handlers = util.get_safe_d({}, kong.ctx.plugin.handlers, cat )
	for i = 1, #handlers do
		local handler_info = handlers[i]
		local err = handler_info.h( cat, k, v, unpack(handler_info.args) )
		if err then return err end
	end
end

-- reference each other
local detect_param_record, detect_param_list
function detect_param_list( cat, prefix, params )
	for i = 1, #params do
		local v = params[i]
		if type(v) == "table" then
			if util.get_safe(v,1) then     --list
				local blocked = detect_param_list( cat, prefix .. "[]", v )
				if blocked then return blocked end
			else
				local blocked = detect_param_record( cat, prefix  .. ".", v )
				if blocked then return blocked end
			end
		else
			local blocked = handle_param( cat, prefix, v )
			if blocked then return blocked end
		end
	end		
end

function detect_param_record( cat, prefix, params )
	for k, v in pairs(params) do
		if type(v) == "table" then
			if util.get_safe(v,1) then     --list
				local blocked = detect_param_list( cat, prefix .. k .. "[]", v )
				if blocked then return blocked end
			else
				local blocked = detect_param_record( cat, prefix .. k .. ".", v )
				if blocked then return blocked end
			end
		else
			local blocked = handle_param( cat, prefix .. k, v )
			if blocked then return blocked end
		end
	end		
end

local function detect_param_main( cat, v )
	if type(v) == "table" then
		if util.get_safe(v,1) then     --list
			return detect_param_list( cat, "[]", v )
		else  --
			return detect_param_record( cat, "", v )
		end
	else
		return handle_param( cat, "", v)
	end
end

return {
	detect_param_path = detect_param_path,
	detect_param_main = detect_param_main,
}
