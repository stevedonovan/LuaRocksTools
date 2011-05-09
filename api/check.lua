local api = require 'luarocks.api'
local deps = require("luarocks.deps")

local installed = api.list_map()
local available = api.search_map()
for package,info in pairs(available) do
    local linfo = installed[package]
    if linfo and api.updated(linfo,info) then
        print(package,info.version,linfo.version)
    end
end
