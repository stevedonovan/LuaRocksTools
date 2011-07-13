-- showing all the information returned by
-- querying the local rock tree; if something cannot
-- be found it tries to query the repository. It uses the
-- 'exact' flag, which downloads the remote rockspec. It isn't
-- always possible to deduce the modules provided by a package
-- (e.g. if it uses a 'make' backend)
-- You may provide an exact version for the second parameter
local api = require 'luarocks.api'
res,err = api.show(arg[1],arg[2])
if not res then
   print 'not found locally; searching...'
   res, err = api.search(arg[1],arg[2], {exact=true, details=true})
   if not res or #res == 0 then
      return print(err)
   else
      res = res[1]
   end
end
-- use your favourite table dumper here...
require 'pl.pretty'.dump(res)

--[[-- output
$> lua show.lua lua2json
{
  package = "lua2json",
  build_type = "none",
  repo = "C:\\LuaRocks",
  modules = {
  },
  version = "0.1-1",
  homepage = "http://github.com/agladysh/lua2json",
  dependencies = {
    "lpeg",
    "lunit",
    "luajson"
  },
  license = "MIT/X11",
  summary = "A command-line tool to convert Lua to JSON",
  rock_dir = "C:\\LuaRocks/lib/luarocks/rocks/lua2json/0.1-1"
}

$> lua show.lua sha2
not found locally; searching...
{
  description = [[
Lua Binding for the SHA-2 (SHA-256/384/512) BSD licensed C implmentation by Aaron Gifford.
Also contains a HMAC implementation in Lua.
        ]],
  package = "sha2",
  build_type = "builtin",
  repo = "http://192.168.1.101/rocks",
  version = "0.2.0-1",
  homepage = "http://code.google.com/p/sha2/",
  dependencies = {
    "lua"
  },
  license = "MIT/X11",
  modules = {
    "hmac.md5",
    "hmac.sha2",
    "hmac",
    "sha2"
  },
  summary = "Lua binding for Aaron Gifford's SHA-2 implementation"}
]]
