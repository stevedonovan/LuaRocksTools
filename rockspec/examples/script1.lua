require 'rockspec'

package('mylib','1.0')
C.directory '.'
C.module.mylib.core 'mylib.c'

rockspec.write()