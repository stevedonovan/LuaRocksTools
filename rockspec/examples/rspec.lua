require 'rockspec'

package('luasocket','2.0.2','3')
C.module.socket.core [[
 luasocket.c auxiliar.c buffer.c except.c io.c tcp.c
 timeout.c udp.c options.c select.c inet.c
]]
:when 'unix' :add 'usocket.c'
:when 'win32'
  :add 'wsocket.c'
  :libraries 'winsock32'

rockspec.write()
