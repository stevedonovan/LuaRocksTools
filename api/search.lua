-- search the LuaRocks repository for a pattern.
-- If the pattern is empty or '--all', then return everything.
-- THe second argument can be an explicit repo to be searched
local api = require 'luarocks.api'
local patt = arg[1]
local flags = { only_from = arg[2]}
if patt == '--all' then patt = nil end
local res,err = api.search(patt,nil,flags)
if not res then return print(err) end
for _,p in ipairs(res) do
   print(p.package,p.version)
end

