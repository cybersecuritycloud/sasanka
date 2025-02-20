local util = require "kong.plugins.ssk-core.lib.utils"
local ssk = require "kong.plugins.ssk-core.lib.ssk"

local function on_detect_list(e_list)
       local on_s, on_t, on_h, on_d = nil

       -- run handler
       local max_delay = 0
       for i, e in ipairs( e_list["list"] ) do
              kong.log.inspect("detected", e)
              -- add common info
              e[ "route_id" ] = util.get_safe( ngx.ctx, "route", "id" )
              e[ "host" ] = util.get_safe( kong.ctx.shared, "cap", "req_params", "header", "host" )
              e[ "remote" ] = ssk.get_ip()
              -- Nginx cached time (no syscall )
              e[ "time" ] = ngx.utctime()

              for i = 1, #util.get_safe_d({}, kong.ctx.shared.cap.handlers, "ondetect" ) do
                     local handler_info = kong.ctx.shared.cap.handlers.ondetect[i]
                     local s,t,h,d = handler_info["h"]( e, unpack( handler_info["args"]) )
                     if s then
                            if not (on_s and s < on_s) then
                                   kong.ctx.shared.cap.blocked = true
                                   on_s, on_t, on_h, on_d = s,t,h,d
                            end
                     end

                     if d and max_delay < d then
                            max_delay = d
                     end
              end
       end



       if on_s then
              if on_d and on_d > 0 then
                     ngx.sleep( on_d )
              end

              return kong.response.exit( on_s, on_t, on_h )
       end

       if max_delay > 0 then
              ngx.sleep( max_delay )
       end

       return kong.ctx.shared.cap.blocked
end


local function on_detect(e)
       local on_s, on_t, on_h, on_d = nil
       kong.log.inspect("detected", e)
       -- add common info
       e[ "route_id" ] = util.get_safe( ngx.ctx, "route", "id" )
       e[ "host" ] = util.get_safe( kong.ctx.shared, "cap", "req_params", "header", "host" )
       e[ "remote" ] = ssk.get_ip()

       -- run handler
       local max_delay = 0
       for i = 1, #util.get_safe_d({}, kong.ctx.shared.cap.handlers, "ondetect" ) do
              local handler_info = kong.ctx.shared.cap.handlers.ondetect[i]
              local s,t,h,d = handler_info["h"]( e, unpack( handler_info["args"]) )
              if s then
                     kong.ctx.shared.cap.blocked = true
                     on_s, on_t, on_h, on_d = s,t,h,d
              end

              if d and max_delay < d then
                     max_delay = d
              end
       end

       if on_s then
              if on_d and on_d > 0 then
                     ngx.sleep( on_d )
              end

              return kong.response.exit( on_s, on_t, on_h )
       end

       if max_delay > 0 then
              ngx.sleep( max_delay )
       end

       return kong.ctx.shared.cap.blocked
end

local function store_detected( e_new )
       if e_new then
              if not kong.ctx.shared.detected_info then
                     kong.ctx.shared.detected_info = { ["list"] = {} }
              end

              if e_new["list"] then
                     for i, v in ipairs( e_new["list"] ) do
                            table.insert( kong.ctx.shared.detected_info["list"], v )
                     end
              else
                     table.insert( kong.ctx.shared.detected_info["list"], e_new )
              end
       end
end


return {
       on_detect = on_detect,
       on_detect_list = on_detect_list,
       store_detected = store_detected,
}
