local util = require "kong.plugins.ssk-core.lib.utils"

local function on_detect(e)
	local on_s, on_t, on_h = nil
	-- run handler
	for i = 1, #util.get_safe_d({}, kong.ctx.shared.cap.handlers, "ondetect" ) do
		local handler_info = kong.ctx.shared.cap.handlers.ondetect[i]
		local s,t,h = handler_info["h"]( e, unpack( handler_info["args"]) )
		if s then 
			kong.ctx.shared.cap.blocked = true 
			on_s, on_t, on_h = s,t,h
		end
	end

	if on_s then
		return kong.response.exit( on_s, on_t, on_h )
	end

	return kong.ctx.shared.cap.blocked
end



return {
	on_detect = on_detect,
}
