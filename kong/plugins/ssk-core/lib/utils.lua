local function check_module( k )
        if package.loaded[k] then
                return true
        else
                for _, loader in ipairs(package.loaders) do
                        local f = loader( k )
                        if type(f) == "function" then
                                package.preload[k] = f
                                return true
                        end
                end
                return false
        end
end

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

local function split( str, delim )
        if not delim then return {str} end
        local ret= {};

        local i = 1
        for s in string.gmatch(str, "([^"..delim.."]+)") do
                ret[i] = s
                i = i + 1
        end

        return ret
end

local function split_once( str, delim )
        if not delim then return str, nil end

        local p = string.find( str, delim )
        if not p then
                return str, nil
        else
                local head = string.sub( str, 1, p - 1)
                local tail = string.sub( str, p + #delim )
                return head, tail

        end
end

local function parse_urlencoded_kv(target)
        local ret = {}
        local ql = split( target, "&")
        for i = 1, #ql do
                local k, v = split_once(ql[i], "=")
                if ret[k] then
                        if type( ret[k] ) == "table" then
                                table.insert(ret[k], v)
                        else
                                local v_list = { ret[k] }
                                table.insert( v_list, v )
                                ret[k] = v_list
                        end
                else
                        ret[k] = v
                end
        end
        return ret

end



return {
        check_module = check_module,

        get_safe = get_safe,
        get_safe_d = get_safe_d,

        keys = keys,
        merge = merge,
        isempty = isempty,

        split = split,
        split_once = split_once,
        parse_urlencoded_kv = parse_urlencoded_kv,
}
