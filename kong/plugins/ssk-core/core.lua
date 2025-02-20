local util = require "kong.plugins.ssk-core.lib.utils"
local request = require "kong.plugins.ssk-core.request"
local response = require "kong.plugins.ssk-core.response"
local common = require "kong.plugins.ssk-core.common"

local _M = {
        VERSION  = "0.0.1",
        PRIORITY = 100
}

function _M:extend()
        self.__index = self
        local o = {}
        for k, v in pairs(self) do
                if k:find("__") == 1 then
                        o[k] = v
                end
        end
        o.__index = o
        o.super = self
        setmetatable(o, self)
        return o
end

function _M:hasoptimize()
        return kong.ctx.shared.cap.optimize
end

local function initialize( config )
        if not kong.ctx.shared.cap then
                --initialize
                kong.ctx.shared.cap = {}
                kong.ctx.shared.cap.id = {}
                kong.ctx.shared.cap.handlers = {}
                kong.ctx.shared.cap.options = {}
                kong.ctx.shared.cap.plugin = {}
                kong.ctx.shared.cap.optimize = false
        end

        -- already intted
        if not util.get_safe(kong.ctx.plugin, "handlers") then
                -- init objects
                kong.ctx.plugin.handlers = {}
        end
        kong.ctx.plugin.config = config

end

function _M:new( name )
end

function _M:add_param_handler( cat, config, h, ...)
        if  not cat or cat == "param_req_*" then
                self:add_handler( "param_req_path", h, ... )
                self:add_handler( "param_req_query", h, ... )
                self:add_handler( "param_req_header", h, ...)
                self:add_handler( "param_req_body", h, ...)
                self:add_handler( "param_req_cookie", h, ...)
        elseif cat == "param_req_path" then
                self:add_handler( "param_req_path", h, ...)
        elseif cat == "param_req_query" then
                self:add_handler( "param_req_query", h, ...)
        elseif cat == "param_req_header" then
                self:add_handler( "param_req_header", h, ...)
        elseif cat == "param_req_cookie" then
                self:add_handler( "param_req_cookie", h, ...)
        elseif cat == "param_req_body" then
                self:add_handler( "param_req_body", h, ...)
        -- response
        elseif cat == "param_res_header" then
                self:add_handler( "param_res_header", h, ...)
        elseif cat == "param_res_body" then
                self:add_handler( "param_res_body", h, ...)
        end
end

-- as global plugin handler
function _M:add_global_handler( cat, h, ... )
        local p = util.get_safe( kong.ctx.shared.cap.handlers, cat )
        if p == nil then
                kong.ctx.shared.cap.handlers[cat] = {}
                p = kong.ctx.shared.cap.handlers[cat]
        end

        table.insert( p, { args = {...}, h= h } )
end


-- as local plugin handler
function _M:add_handler( cat, h, ...)

        if self:hasoptimize() then
                return self:add_global_handler( cat, h, ... )
        end

        local p = util.get_safe( kong.ctx.plugin.handlers, cat )
        if p == nil then
                kong.ctx.plugin.handlers[cat] = {}
                p = kong.ctx.plugin.handlers[cat]
        end
        table.insert( p, { args = {...}, h= h } )
end

-- run at init worker phase
-- it runs when enabled in kong.conf
-- ( even not plugin created )
function _M:init_worker()
end

-- call once on access
-- it used on child plugin
function _M:init_handler( config )
        -- empty
end

function _M:preprocess( config )
        initialize(config)
        if not kong.ctx.plugin.inited then
                self:init_handler( config )
                kong.ctx.plugin.inited = true
        end

        if kong.ctx.shared.cap.blocked then
                return false
        end

        if kong.ctx.plugin.done then
                return false
        end

        -- check whether run on local plugin or global plugin
        if self:hasoptimize() then return false end

        return true
end

-- every time from client until send to upstream
function _M:access(config)
        if not self:preprocess( config ) then return end

        local handlers = kong.ctx.plugin.handlers

        local cont, err = request.phase_access( handlers )
        if err then
                local blocked = common.on_detect( err )
                if blocked then return end
        end
        if not cont then return end

        return request.run_access_handler()
end

function _M:header_filter(config)
        if not self:preprocess( config ) then return end

        return response.run_header_handler()
end

-- every time when received from upstrem, until sent to client
function _M:body_filter(config)
        if not self:preprocess( config ) then return end

        return response.phase_body()
end

-- last time of transaction
function _M:log(config)
        if not self:preprocess( config ) then return end

        return response.run_log_handler()
end

return _M
