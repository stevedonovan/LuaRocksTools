require 'rockspec'

package('wonderland','1.0')
Lua.module.wonderland.alice()
Lua.module.wonderland.caterpillar()

rockspec.write()