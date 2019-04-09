Stack = {}
Stack.__index = Stack

function Stack:new( ... )
    local o = {}
    setmetatable(o, self)
    o:init(...)
    return o
end

function Stack:init( ... )
    self.m_list = {}
end

function Stack:push( e )
    self.m_list[#self.m_list + 1] = e
end

function Stack:pop()
    return table.remove(self.m_list)
end

function Stack:pop_all()
    local ret = self.m_list
    self.m_list = {}
    return ret
end

function Stack:size()
    return #self.m_list
end

function Stack:elements()
    return self.m_list
end

local M = {}

function M.table_len( t )
    local count = 0
    for k,v in pairs(t) do
        count = count +1
    end
    return count
end

function M.is_raw_array( t )
    if type(t) ~= 'table' then
        return false
    end
    return M.table_len(t) == #t
end

function M.table_str(mt, max_floor, cur_floor)
    cur_floor = cur_floor or 1
    max_floor = max_floor or 5
    if max_floor and cur_floor > max_floor then
        return tostring(mt)
    end
    local str
    if cur_floor == 1 then
        str = string.format("%s{\n",string.rep("--",max_floor))
    else
        str = "{\n"
    end
    for k,v in pairs(mt) do
        if type(v) == 'table' then
            v = M.table_str(v, max_floor, cur_floor+1)
        else
            if type(v) == 'string' then
                v = "'" .. v .. "'"
            end
            v = tostring(v) .. "\n"
        end
        str = str .. string.format("%s[%s] = %s",string.rep("--",cur_floor),k,v)
    end
    str = str .. string.format("%s}\n",string.rep("--",cur_floor-1))
    return str
end

local function _split(str, sep)
    local s, e = str:find(sep)
    if s then
        return str:sub(0, s - 1), str:sub(e + 1)
    end
    return str
end

function M.str_split(str, sep, n)
    local res = {}
    local i = 0
    while true do
        local lhs, rhs = _split(str, sep)
        table.insert(res, lhs)
        if not rhs then
            break
        end
        i = i + 1
        if n and i >= n then
            table.insert(res, rhs)
            break
        end
        str = rhs
    end
    return res
end

return M