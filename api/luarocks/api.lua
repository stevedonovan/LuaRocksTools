----------------------
-- A simple external API for LuaRocks
--
module("luarocks.api", package.seeall)

local util = require("luarocks.util")
local _search = require("luarocks.search")
local deps = require("luarocks.deps")
local manif = require("luarocks.manif")
local fetch = require("luarocks.fetch")
local _install = require("luarocks.install")
local build = require("luarocks.build")
local cfg = require("luarocks.cfg")
local fs = require("luarocks.fs")
local path = require("luarocks.path")
local dir = require("luarocks.dir")
local _remove = require("luarocks.remove")

local append = table.insert

local function version_iter (versions)
   return util.sortedpairs(versions, deps.compare_versions)
end

local function _latest(versions,first_repo)
   local version, repos = version_iter(versions)()
   local repo = repos[first_repo and 1 or #repos]
   return version, repo.repo
end

-- cool, let's initialize this baby. This is normally done by command_line.lua
local trees = cfg.rocks_trees
local is_local

local function use_tree(tree)
   cfg.root_dir = tree
   cfg.rocks_dir = path.rocks_dir(tree)
   cfg.deploy_bin_dir = path.deploy_bin_dir(tree)
   cfg.deploy_lua_dir = path.deploy_lua_dir(tree)
   cfg.deploy_lib_dir = path.deploy_lib_dir(tree)
end

--- set the current tree to be global or local
-- @param make_local use the local tree (default false)
function set_rocks_tree (make_local)
   is_local = make_local
   use_tree(trees[is_local and 1 or #trees])
end

local old_print = _G.print

local function check_flags (flags)
   flags._old_servers = cfg.rocks_servers
   if flags.use_local then
      if not is_local then
         set_rock_tree(true)
         flags._was_global = true
      end
   end
   if flags.from then
      table.insert(cfg.rocks_servers, 1, flags.from)
   elseif flags.only_from then
      cfg.rocks_servers = { flags.only_from }
   end
   if flags.quiet then
      _G.print = function() end
   end
end

local function restore_flags (flags)
   if flags.use_local and flags._was_global then
      set_rock_tree(false)
   end
   if flags.from then
      table.remove(cfg.rocks_servers,1)
   elseif flags.only_from then
      cfg.rocks = flags._old_servers
   end
   if flags.quiet then
      _G.print = old_print
   end
end

set_rocks_tree(false)

local manifests = {}

--- information returned by show and list.
-- @field package canonical name
-- @field repo the tree where found
-- @field version
-- @field rock_dir the full path to the rock
-- @field homepage
-- @field license
-- @field summary
-- @field description
-- @field build_type (this is the rockspec's build.type)
-- @field modules modules provided by this package
-- @field dependencies packages that this package needs
-- @class table
-- @name local_info_table


--- show information about an installed package.
-- @param name the package name
-- @param version version, may be nil
-- @param field one of the output fields
-- @return a local info table, or a string if field is specified.
-- @see local_info_table
function show(name,version,field)
   local res,err = list (name,version,{exact = true})
   if not res then return nil,err end
   res = res[1]
   if field then return res[field]
   else return res
   end
end

--- list information about currently installed packages.
-- @param pattern a string which is partially matched against packages
-- @param version a specific version, may be nil.
-- @param flags
-- @return a list of local info tables
-- @see local_info_table
function list(pattern,version,flags)
   local results = {}
   flags = flags or {}
   if flags.ropckspec == nil then flags.rockspec = true end
   if flags.manifest == nil then flags.manifest = true end
   pattern = pattern or ''
   local query = _search.make_query(pattern, version)
   query.exact_name = flags.exact == true

   local tree_map = {}
   for _, tree in ipairs(cfg.rocks_trees) do
      local rocks_dir = path.rocks_dir(tree)
      tree_map[rocks_dir] = tree
      _search.manifest_search(results, rocks_dir, query)
   end

   if not next(results) then return nil,"cannot find "..pattern..(version and (' '..version) or '') end

   local res = {}
   for name,versions in util.sortedpairs(results) do
      local version,repo_url = _latest(versions,false)
      local repo =  tree_map[repo_url] -- repo_url
      local directory = path.install_dir(name,version,repo)

      local descript, minfo, build_type
      if flags.rockspec then
           local rockspec_file = path.rockspec_file(name, version, repo)
           local rockspec, err = fetch.load_local_rockspec(rockspec_file)
           descript = rockspec.description
           build_type = rockspec.build.type
      end
      if flags.manifest then
           local manifest = manifests[repo_url]
           if not manifest then -- cache these
              manifest = manif.load_manifest(repo_url)
              manifests[repo_url] = manifest
            end
           minfo = manifest.repository[name][version][1]
      end

      local entry =  {
         package = name,
         repo = repo,
         version = version,
         rock_dir = directory,
         homepage = descript and descript.homepage,
         license = descript and descript.license,
         summary = descript and descript.summary,
         description = descript and descript.detailed,
         build_type = build_type,
         modules = minfo and util.keys(minfo.modules),
         dependencies = minfo and util.keys(minfo.dependencies),
      }
      if flags.map then
         res[name] = entry
      else
         append(res,entry)
      end
   end
   return res

end

--- list information about installed packages, but return a map.
-- @param pattern a string which is partially matched against packages
-- @param version a specific version, may be nil.
-- @param flags
-- @return a table where the keys are package naems and values are local info tables
-- @see local_info_table
function list_map(pattern,version,flags)
   flags = flags or {}
   flags.map = true
   return list(pattern,version,flags)
end

--- is this package outdated?.
-- @param linfo local info table
-- @param info server info table
-- @return true if the package is out of date.
function updated (linfo,info)
   return deps.compare_versions(linfo.version,info.version)
end

--- search LuaRocks repositories for a package.
-- @param pattern a string which is partially matched against packages
-- @param version a specific version, may be nil.
-- @param flags a table with keys 'all' means get all version information,
-- 'from' to add another repository to the search and 'only_from' to only search
-- the given repository
-- @return a list of server information. Without 'all', we get package,version and
-- repo, where repo is the remote server. With 'all', instead of repo we get versions,
-- which is a list of {version,repos}.
function search (pattern,version,flags)
   flags = flags or {}
   check_flags(flags)
   local query = _search.make_query((pattern or ''):lower(), version)
   query.exact_name = false
   local results, err = _search.search_repos(query)
   if not results then
      restore_flags(flags)
      return nil, err
   end
   local res = {}
   for package, versions in util.sortedpairs(results) do
      local rec
      if not flags.all then
         local version, repo = _latest(versions,true)
         rec = {
            package = package,
            version = version,
            repo = repo
         }
      else
         local vss = {}
         for vs,repos in version_iter (versions) do
            append(vss,{version=vs,repos=repos})
         end
         rec = {
            package = package,
            version = vss[1].version,
            versions = vss
         }
      end
      if flags.map then
         res[package] = rec
      else
         append(res,rec)
      end
   end
   restore_flags(flags)
   return res
end

--- search LuaRocks repositories for a package, returning a map.
-- @param pattern a string which is partially matched against packages
-- @param version a specific version, may be nil.
-- @param flags
-- @return a table of server information indexed by package name.
function search_map(pattern,version,flags)
   flags = flags or {}
   flags.map = true
   return search(pattern,version,flags)
end

--- install a rock.
-- @param name
-- @param version can ask for a specific version (default nil means get latest)
-- @param flags a table with keys 'use_local' to install to local tree,
-- 'from' to add another repository to the search and 'only_from' to only use
-- the given repository
-- @return true if successful, nil if not.
-- @return error message if not
function install (name,version,flags)
   check_flags(flags)
   local ok,err = _install.run(name,version)
   restore_flags(flags)
   return ok,err
end

--- remove a rock.
-- @param name
-- @param version a specific version (default nil means remove all)
function remove(name,version)
   check_flags(flags)
   local ok,err = _remove.run(name,version)
   restore_flags(flags)
   return ok,err
end

