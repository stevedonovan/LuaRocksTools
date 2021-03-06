LuaRocksUtils is intended to provide a set of tools to support the LuaRocks
versioned package manager.

The first tool is `rockspecifier`, which is an interactive console script
that generates rockspecs from a question-and-answer session.

Installing via LuaRocks:

     $ sudo luarocks install  http://github.com/stevedonovan/LuaRocksTools/raw/master/rockspecifier/rockspecifier-0.5-1.rockspec

The second tool is `rockspec`, which is also a rockspec generator, but is a library which allows concise declarative specification of rockspecs. For instance, the rockspec for this library was generated by running the following script:

    -- rspec.lua
    require 'rockspec'
    
    package('rockspec','0.1')
    depends 'penlight'
    Lua.directory '.'
    Lua.module.rockspec()
    
    rockspec.write()

It particularly shines with more complicated packages that have per-platform overrides. For instance, this will generate a working rockspec for LuaSocket:

    package('luasocket','2.0.2','3')

    C.module.socket.core [[
     luasocket.c auxiliar.c buffer.c except.c io.c tcp.c
     timeout.c udp.c options.c select.c inet.c
    ]]
    :defines 'LUASOCKET_DEBUG'
    :when 'unix' :add 'usocket.c'
    :when 'win32'
     :add 'wsocket.c'
     :libraries 'wsock32'

    C.module.mime.core 'mime.c'

    Lua.directory 'src'

    function socket(name)
     Lua.module.socket[name] (name..'.lua')
    end

    socket 'http'
    socket 'url'
    socket 'tp'
    socket 'ftp'
    socket 'smtp'

    Lua.module.ltn12()
    Lua.module.socket()
    Lua.module.mime()


Look at the readme and install like so:

     $ sudo luarocks install http://stevedonovan.github.com/files/rockspec-0.1-1.rockspec

Licence: MIT/X11

Steve Donovan
2010