require 'rockspec'

package('baz','1.0')
C.module.baz()
  :when 'unix' :add 'ubaz.c'
  :when 'win32' :add 'wbaz.c'
   :libraries 'winsock32'

rockspec.write()