local utils = require "utils"
local lpeg = require "lpeg"
local td_error = require "td_error"
local td_desc = require "td_desc"
local cjson = require "cjson"
local P = lpeg.P
local R = lpeg.R
local S = lpeg.S
local C = lpeg.C
local Ct = lpeg.Ct
local V = lpeg.V
local Cc = lpeg.Cc
local Cg = lpeg.Cg
local Carg = lpeg.Carg
local Cmt = lpeg.Cmt

local function count_lines(_,pos, parser_state)
    if parser_state.pos < pos then
        parser_state.line = parser_state.line + 1
        parser_state.pos = pos
    end
    return pos
end

local eof = P(-1)
local newline = Cmt((P"\n" + "\r\n") * Carg(1) ,count_lines)
local line_comment = "#" * (1 - newline) ^0 * (newline + eof)
local blank = S" \t" + newline + line_comment
local blank0 = blank ^ 0
local blanks = blank ^ 1
local alpha = R"az" + R"AZ" + "_"
local alnum = alpha + R"09"
local word = alpha * alnum ^ 0
local structname = C(word)
local fieldname = C(P("*")^-1 * word)
local typename = C(word * ("." * word) ^ 0)

local function multipat(pat)
    return Ct(blank0 * (pat * blanks)^0 * pat^0 * blank0)
end

local function namedpat(name, pat)
    return Ct(Cg(Cc(name), "type") * Cg(pat))
end

local unit_pat = namedpat("unit",typename)
local list_pat = namedpat("list", P"[" * typename * P"]")
local map_pat = namedpat("map", P"<" * typename * blank0 * "," * blank0 * typename * P">")

local schema = P {
    "BEGIN",

    FIELD = namedpat(
        "field",
        fieldname * blanks * (unit_pat  + list_pat + map_pat)
    ),

    STRUCT = namedpat(
        "struct", 
        blank0 * structname * blank0 * P"{" * multipat(V"FIELD") * P"}"
    ),

    BEGIN = multipat(V"STRUCT"),
}

local exception = Cmt (
    Carg(1),
    function(text, pos, parser_state)
        local s = string.format(
            "syntax error, file[%s],line[%s],pos[%s]",
            parser_state.file,
            parser_state.line,
            pos
        )
        error(s)
    end
)

TdParser = {}
TdParser.__index = TdParser

function TdParser:new( ... )
    local o = {}
    setmetatable(o, self)
    o:init(...)
    return o
end

function TdParser:init()
    self.m_PathStack = Stack:new()
    self.m_mStructs = {}
end

function TdParser:path_stack()
    return self.m_PathStack
end

function TdParser:dump_path()
    return table.concat(self.m_PathStack:elements(), ".")
end

function TdParser:load(dir)
    local f = io.popen(string.format("dir /b %s\\*.td", dir))
    local stream = f:read("*a")
    f:close()
    for file in string.gmatch(stream, "([%w_]+%.td)") do
        self:parse_file(dir, file)
    end
    for name,o in pairs(self.m_mStructs) do
        o:load_check()
    end
end

function TdParser:parse_file(dir, filename)
    local file_path = dir .. "\\".. filename
    local ltext = {}
    for line in io.lines(file_path) do
        ltext[#ltext + 1] = line
    end
    local stext = table.concat(ltext, "\n")
    self:parse_string(stext, file_path)
end

function TdParser:parse_string(text, file)
    self.m_ParseState = { file = file or '@main', pos = 0, line = 1 }
    --print("---parse " .. self.m_ParseState.file .. " begin----")
    local r = lpeg.match(schema * -1 + exception, text, 1, self.m_ParseState)
    local ret = {}
    for _, item in ipairs(r) do
        local o = self:add_item( item )
        table.insert(ret, o:dump())
    end
    --print(utils.table_str(ret))
    --print("---parse " .. self.m_ParseState.file .. " end----")
end

function TdParser:add_item(item)
    local o = TdStruct:new(self, item)
    o:convert()
    assert(self.m_mStructs[o:Name()] == nil, "struct " .. o:Name() .. " redefine")
    self.m_mStructs[o:Name()] = o
    return o
end

function TdParser:get_item( struct_name )
    return self.m_mStructs[struct_name]
end

local err_msghandler = function ( err )
    if type(err) == 'string' then
        print("runtime err:", err)
    else
        err:output()
    end
end

function TdParser:json_check(struct_name, json_text)
    local ok, json_tbl = pcall(cjson.decode, json_text)
    if not ok then
        local oErr = TdError:new(self, TD_ERR_JSON_FMT_ERROR, json_tbl)
        oErr:output()
        return false
    end
    --print("load json str:", utils.table_str(json_tbl))
    local oSt = self:get_item(struct_name)
    if not oSt then
        local oErr = TdError:new(self, TD_ERR_STRUCT_NO_EXIST, struct_name)
        oErr:output()
        return false
    end
    self.m_PathStack:pop_all()
    self.m_PathStack:push(struct_name)
    return xpcall(oSt.run_check, err_msghandler, oSt, json_tbl)
end