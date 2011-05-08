local api = require 'luarocks.api'
local flags = { all = arg[2]}

local res,err = api.search(arg[1],nil,flags)
if not res then return print(err) end
if not flags.all then
    for _,p in ipairs(res) do
        print(p.package,p.version)
    end
else
    require 'pl.pretty'. dump(res)
end

