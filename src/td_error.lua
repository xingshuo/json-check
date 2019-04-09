TD_ERR_OK = 0
TD_ERR_TYPE_NOT_MATCH = 1
TD_ERR_NUMBER_RANGE_OVERFLOW = 2
TD_ERR_JSON_FMT_ERROR = 3
TD_ERR_STRUCT_NO_EXIST = 4
TD_ERR_REQUIRE_FIELD_LOST = 5
TD_ERR_UNDEFINE_FIELD = 6

local errors_map = {
    [TD_ERR_OK] = "TD_ERR_OK",
    [TD_ERR_TYPE_NOT_MATCH] = "TD_ERR_TYPE_NOT_MATCH",
    [TD_ERR_NUMBER_RANGE_OVERFLOW] = "TD_ERR_NUMBER_RANGE_OVERFLOW",
    [TD_ERR_JSON_FMT_ERROR] = "TD_ERR_JSON_FMT_ERROR",
    [TD_ERR_STRUCT_NO_EXIST] = "TD_ERR_STRUCT_NO_EXIST",
    [TD_ERR_REQUIRE_FIELD_LOST] = "TD_ERR_REQUIRE_FIELD_LOST",
    [TD_ERR_UNDEFINE_FIELD] = "TD_ERR_UNDEFINE_FIELD",
}

TdError = {}
TdError.__index = TdError

function TdError:new( ... )
    local o = {}
    setmetatable(o, self)
    o:init(...)
    return o
end

function TdError:init(oParser, err_type, msg, ...)
    self.m_ErrType = err_type
    local path = oParser:dump_path()
    local text = string.format(msg, ...)
    local head = errors_map[err_type] or "未知错误"
    self.m_ErrMsg = string.format("[%s]: %s: %s", head, path, text)
end

function TdError:output()
    print(self.m_ErrMsg)
end

function TdError:errmsg()
    return self.m_ErrMsg
end