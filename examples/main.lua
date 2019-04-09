package.path = "src/?.lua;" .. package.path
package.cpath = "deps/?.dll;" .. package.cpath

require "td_parse"

local o = TdParser:new()
o:load("examples\\check_list")


print("---test json format error begin---")
local json_text = [[
{
    "profile": {"name":"lakefu", "sex":2},
    "IsNewbie": true,
}
]]
local ok = o:json_check("AccountInfo", json_text)
assert(not ok, "json check error")
print("---test json format error end---\n\n")


print("---test type not match error begin---")
local json_text = [[
{
    "profile": {"name":"lakefu", "sex":"man"},
    "IsNewbie": true
}
]]
local ok = o:json_check("AccountInfo", json_text)
assert(not ok, "json check error")
print("---test type not match error end---\n\n")


print("---test number range overflow begin---")
local json_text = [[
{
    "profile": {"name":"lakefu", "sex":2, "level":65536},
    "IsNewbie": true
}
]]
local ok = o:json_check("AccountInfo", json_text)
assert(not ok, "json check error")
print("---test number range overflow end---\n\n")


print("---test undefined field error begin---")
local json_text = [[
{
    "profile": {"name":"lakefu", "sex":2},
    "DeviceType":"ios",
    "IsNewbie": true
}
]]
local ok = o:json_check("AccountInfo", json_text)
assert(not ok, "json check error")
print("---test undefined field error end---\n\n")


print("---test lost required field error begin---")
local json_text = [[
{
    "profile": {"name":"lakefu", "sex":"man"},
    "items": [{"ID":1,"Num":2},{"ID":2,"Num":4}]
}
]]
local ok = o:json_check("AccountInfo", json_text)
assert(not ok, "json check error")
print("---test lost required field error end---\n\n")

print("---test all right begin--")
local json_text = [[
{
    "profile": {"name":"lakefu", "sex":2},
    "IsNewbie": true,
    "items": [{"ID":1,"Num":2},{"ID":2,"Num":4}],
    "tasks": {"1002":{"ID":100001, "IsFinished": false, "Progress":14}}
}
]]
local ok = o:json_check("AccountInfo", json_text)
assert(ok, "json check error")
print("json is all right")
print("---test all right end--\n\n")

