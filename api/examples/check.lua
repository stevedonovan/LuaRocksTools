-- see if any installed rocks need updating!
local api = require 'luarocks.api'
local from = arg[1]

local installed = api.list_map()
local available = api.search_map(nil,nil,{only_from=from})
for package,info in pairs(available) do
   local linfo = installed[package]
   if linfo and api.compare_versions(linfo,info) then
      print(package,info.version,linfo.version)
   end
end
