require 'rockspec'

package('rockspec','0.1')
depends 'penlight'
Lua.directory '.'
Lua.module.rockspec()

rockspec.write()
