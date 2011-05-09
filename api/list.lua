local api = require 'luarocks.api'
local  res,err = api.list(arg[1])
if not res then return print(err) end
for _,p in ipairs(res) do 
    print(p.package,p.version,p.build_type,p.summary)
end
