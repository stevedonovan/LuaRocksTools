## Experimental LuaRocks API

These functions encapsulate the querying interface of LuaRocks as available through the `show`, `list`, `search` and `install` commands. Patterns are interpreted in the same way as in the LuaRocks `list` command.
 
### list

    function list(pattern,version,flags)
    function list_map(pattern,version,flags)
    
By default, it gets all information using a non-exact search; it will return a list of tables containing the following entries:

First, basic information:

  * `package`  package name
  * `version` package version
  * `repo` LuaRocks repository
  
Then details from the rockspec:

  * `homepage`
  * `rock_dir`
  * `license`
  * `summary`
  * `description`
  * `build_type`
  
If `flags.rockspec` is set to `false` these fields will not be filled in.

The `list_map` version returns a table where the keys are the packages and the values are the infomation tables above.
  
And information from the manifest:

  * `modules` table of module names
  * `dependencies` table of packages needed by this package
  
if `flags.manifest` is set to `false` these fields will not be filled in.

### show

    function show(pattern,version,field)
    
This calls `list` above and returns the same information.  `pattern` will be exactly matched, and must not be `nil`.  If `field` is specified, it must be one of the fields specified above and specifies what value will be returned.

For example, `show('myrock',nil,'version')` will return the currently loaded version of `myrock` and `nil` if not found.

### search

    function search(pattern,version,flags)
    function search_map(pattern,version,flags)
    
This searches the LuaRocks repositories using the pattern, which may be `nil` meaning 'everything'.

By default, the result is a table of basic information just as with `list`: that is `name`, `version` and `repo` are filled in.

If `flags.all` is set to `true` then each item looks like this:

 * `package` as before
 * `version` as before
 *  `versions` which is a list of:
  * `version` (highest version is first in the list)
  * `repos` list of repo info

where 'repo info' is:

 * `repo`  the repository name
 * `arch` one of "src", "rockspec" or "all"
          
As before, the `search_map` returns a table where the package names are keys.

### install          

    function install (name,version,flags)

Same as `luarocks install`. `flags` may contain `use_local` (install to local tree) and also `from` and `only_from` which work the same way as the command.

### remove

    function remove (name,version)



