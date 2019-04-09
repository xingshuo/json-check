local utils = require "utils"
local td_error = require "td_error"

local builtin_types = {
    ['uint8'] = 1,
    ['uint16'] = 1,
    ['uint32'] = 1,
    ['uint'] = 1,
    ['uint64'] = 1,

    ['int8'] = 2,
    ['int16'] = 2,
    ['int32'] = 2,
    ['int'] = 2,
    ['int64'] = 2,
    
    ['float'] = 3,
    ['double'] = 4,
    
    ['boolean'] = 5,
    
    ['string'] = 6,
}

local function is_builtin_type( type_name )
    return builtin_types[type_name]
end

local function is_int_type( type_name )
    return builtin_types[type_name] and builtin_types[type_name] <= 2
end

local function is_number_type( type_name )
    return builtin_types[type_name] and builtin_types[type_name] <= 4
end

local function is_valid_int(type_name, value)
    local signed,nbits = string.match(type_name, "(%a*)int(%d*)")
    nbits = tonumber(nbits) or 32
    local min,max
    if signed == 'u' then --unsigned
        min = 0
        max = (1 << nbits) - 1
    else
        min = -(1 << (nbits - 1))
        max = (1 << (nbits - 1)) - 1
    end
    return min <= value and value <= max
end

local function is_valid_float( type_name, value )
    local min,max
    if type_name == 'float' then
        min = -2^128
        max = 2^128
    elseif type_name == 'double' then
        min = -2^1024
        max = 2^1024
    else
        error("unkonw float type: " .. type_name)
    end
    return min <= value and value <= max
end

local function check_valid_number(oParser, type_name , value)
    if type(value) ~= 'number' then
        error( TdError:new(oParser, TD_ERR_TYPE_NOT_MATCH, "%s <%s type not match %s type>", value, type(value), type_name) )
    end
    if is_int_type(type_name) then
        if math.floor(value) ~= value then
            error( TdError:new(oParser, TD_ERR_TYPE_NOT_MATCH, "%s <float type not match %s type>", value, type_name) )
        end
        if not is_valid_int(type_name , value ) then
            error( TdError:new(oParser, TD_ERR_NUMBER_RANGE_OVERFLOW, "%s overflow %s type", value, type_name) )
        end
    else --float or double
        if not is_valid_float(type_name , value ) then
            error( TdError:new(oParser, TD_ERR_NUMBER_RANGE_OVERFLOW, "%s overflow %s type", value, type_name) )
        end
    end
    return true
end

local function check_builtin_type(oParser, type_name , value )
    if is_number_type(type_name) then
        check_valid_number(oParser, type_name , value)
    else
        if type_name ~= type(value) then
            error( TdError:new(oParser, TD_ERR_TYPE_NOT_MATCH, "%s <%s type not match %s type>", value, type(value), type_name) )
        end
    end
    return true
end

local function trans_field_keyname( key_name )
    if key_name:sub(1,1) == '*' then
        return key_name:sub(2), true
    else
        return key_name, false
    end
end

TdField = {}
TdField.__index = TdField

function TdField:new( ... )
    local o = {}
    setmetatable(o, self)
    o:init(...)
    return o
end

function TdField:init(struct, key_name, value_data)
    self.m_oStruct = struct
    self.m_KeyName, self.m_IsRequired = trans_field_keyname(key_name)
    self.m_RawData = value_data
end

function TdField:KeyName()
    return self.m_KeyName
end

function TdField:convert()
    if self.m_RawData == nil then
        error("field convert no raw data")
        return
    end

    local obj = self.m_RawData
    self.m_FieldType = obj.type
    if obj.type == 'unit' then
        self.m_ValueData = {type = obj[1]}
    elseif obj.type == 'map' then
        assert(is_number_type( obj[1] ) or obj[1] == 'string', "error key type: " .. obj[1])
        self.m_ValueData = {k_type = obj[1], v_type = obj[2]}
    elseif obj.type == 'list' then
        self.m_ValueData = {type = obj[1]}
    else
        error(string.format("struct %s field %s unknown type", self.m_oStruct:Name(), self.m_KeyName))
    end

    self.m_RawData = nil
end

function TdField:is_required()
    return self.m_IsRequired
end

function TdField:run_check( v )
    local oParser = self.m_oStruct:get_parser()
    oParser:path_stack():push(self.m_KeyName)
    local _type = self.m_ValueData.type
    if self.m_FieldType == 'unit' then
        if is_builtin_type(_type) then
            check_builtin_type(oParser, _type, v)
        else
            local oStruct = oParser:get_item(_type)
            assert(oStruct, "unkonw td type:" .. _type)
            oStruct:run_check( v )
        end
    elseif self.m_FieldType == 'list' then
        if type(v) ~= 'table' then
            error( TdError:new(oParser, TD_ERR_TYPE_NOT_MATCH, "%s <%s type not match list field>", v, type(v)) )
        end
        if not utils.is_raw_array( v ) then
            error( TdError:new(oParser, TD_ERR_TYPE_NOT_MATCH, "list field need raw array") )
        end
        for _,vv in ipairs(v) do
            if is_builtin_type(_type) then
                check_builtin_type(oParser, _type, vv)
            else
                local oStruct = oParser:get_item(_type)
                assert(oStruct, "unkonw td type:" .. _type)
                oStruct:run_check( vv )
            end
        end
    elseif self.m_FieldType == 'map' then
        if type(v) ~= 'table' then
            error( TdError:new(oParser, TD_ERR_TYPE_NOT_MATCH, "%s <%s type not match map field>", v, type(v)) )
        end
        local k_type = self.m_ValueData.k_type
        local v_type = self.m_ValueData.v_type
        for kk,vv in pairs(v) do
            if is_number_type(k_type) then
                local _kk = tonumber(kk)
                if not _kk then
                    error( TdError:new(oParser, TD_ERR_TYPE_NOT_MATCH, "%s not match map field's keytype %s", kk, k_type) )
                end
                check_valid_number(oParser, k_type, _kk)
            end

            if is_builtin_type(v_type) then
                check_builtin_type(oParser, v_type, vv)
            else
                local oStruct = oParser:get_item(v_type)
                assert(oStruct, "unkonw td type:" .. v_type)
                oStruct:run_check( vv )
            end
        end
    end
    oParser:path_stack():pop()
end

function TdField:load_check()
    local _type = self.m_ValueData.type
    if self.m_FieldType == 'unit' or self.m_FieldType == 'list' then
        if not is_builtin_type(_type) then
            assert(self.m_oStruct:get_parser():get_item(_type), "unkonw td type:" .. _type)
        end
    elseif self.m_FieldType == 'map' then
        local v_type = self.m_ValueData.v_type
        if not is_builtin_type(v_type) then
            assert(self.m_oStruct:get_parser():get_item(v_type), "unkonw td type:" .. v_type)
        end
    end
end

function TdField:dump( ... )
    local m = {
        type = 'field',
        key_name = self.m_KeyName,
        value_data = self.m_ValueData,
        is_required = self.m_IsRequired,
        field_type = self.m_FieldType,
    }
    return m
end


TdStruct = {}
TdStruct.__index = TdStruct

function TdStruct:new( ... )
    local o = {}
    setmetatable(o, self)
    o:init(...)
    return o
end

function TdStruct:init(oParser , data )
    self.m_oParser = oParser
    self.m_RawData = data
    self.m_FieldList = {}
    self.m_FieldMap = {}
end

function TdStruct:get_parser()
    return self.m_oParser
end

function TdStruct:Name()
    return self.m_Name
end

function TdStruct:convert()
    if self.m_RawData == nil then
        error("struct convert no raw data")
        return
    end
    local obj = self.m_RawData
    assert(obj.type == 'struct')
    self.m_Name = obj[1]
    for _, f in ipairs(obj[2]) do
        assert(f.type == 'field')
        local key_name = f[1] --key
        local value_data = f[2] --value
        local _keyname = trans_field_keyname(key_name)
        if self.m_FieldMap[_keyname] then
            error(string.format("struct %s field %s is redefined", self.m_Name, _keyname))
        end

        local oField = TdField:new(self, key_name, value_data)
        oField:convert()
        self.m_FieldMap[oField:KeyName()] = oField
        self.m_FieldList[#self.m_FieldList + 1] = oField
    end
    self.m_RawData = nil
end

function TdStruct:run_check( json_tbl )
    if type(json_tbl) ~= 'table' then
        error( TdError:new(self.m_oParser, TD_ERR_TYPE_NOT_MATCH, "%s <%s type not match Struct type>", json_tbl, type(json_tbl)) )
    end
    for key,oField in pairs(self.m_FieldMap) do
        if oField:is_required() then
            if json_tbl[key] == nil then
                error( TdError:new(self.m_oParser, TD_ERR_REQUIRE_FIELD_LOST, "%s", key) )
            end
        end
    end
    for k,v in pairs(json_tbl) do
        if self.m_FieldMap[k] == nil then
            error( TdError:new(self.m_oParser, TD_ERR_UNDEFINE_FIELD, "%s", k) )
        end
    end

    for k,v in pairs(json_tbl) do
        local oField = self.m_FieldMap[k]
        oField:run_check(v)
    end
end

function TdStruct:load_check()
    for _,oField in ipairs(self.m_FieldList) do
        oField:load_check()
    end
end

function TdStruct:dump()
    local m = {
        type = 'struct',
        name = self.m_Name,
        fields = {},
    }
    for i,obj in ipairs(self.m_FieldList) do
        m.fields[i] = obj:dump()
    end
    return m
end