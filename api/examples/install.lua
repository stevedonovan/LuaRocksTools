--- exploring how quiet a LuaRocks install can get ...
--
-- Currently, not using sudo causes an error on Unix; should really check up front.
--
local api = require 'luarocks.api'

local ok, err = api.install(arg[1],nil,{quiet=true})
if not ok then
    print('failed',err)
end

