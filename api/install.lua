--~ ~/lua/api$ sudo lua install.lua stringy
--~ gcc -O2 -fPIC -I/usr/include/lua5.1 -c stringy.c -o stringy.o
--~ gcc -shared -o stringy.so -L/usr/local/lib stringy.o
--~ true	nil
---
--- exploring how quiet a LuaRocks install can get ...
--
-- note: quiet=true redirects print() to nowhere - would make more sense to
-- to redirect to the log file
--
local api = require 'luarocks.api'
local fs = require 'luarocks.fs'

function fs.execute_string(cmd) -- fs
   --print('*',cmd)
   cmd = cmd ..' >> /tmp/log.tmp 2>&1'
   if os.execute(cmd) == 0 then
      return true
   else
      return false
   end
end

print(api.install(arg[1],nil,{quiet=true}))
