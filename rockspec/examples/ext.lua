require 'rockspec'

package('foo','1.0')
C.module.foo()
 :external 'bar'
   :library 'bar'
   :include 'bar.h'


rockspec.write()