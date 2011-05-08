local api = require 'luarocks.api'
require 'pl'
res,err = api.show(arg[1],arg[2])
if not res then return print(err) end
pretty.dump(res)
