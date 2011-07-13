-- list currently installed rocks
-- the argument is a name to be used for partial matching;
-- if none, then return everything
local api = require 'luarocks.api'
local  res,err = api.list(arg[1])
if not res then return print(err) end
for _,p in ipairs(res) do
   print(p.package,p.version,p.build_type,p.summary)
end

--[[-- output
$> lua list.lua lua
lua-cjson       1.0.1-1 builtin Fast JSON encoding/parsing support for Lua
lua2json        0.1-1   none    A command-line tool to convert Lua to JSON
luafilesystem   1.5.0-2 module  File System Library for the Lua Programming Language
luajson 1.2.1-1 module  customizable JSON decoder/encoder
luasocket       2.0.2-4 command Network support for the Lua language
]]
