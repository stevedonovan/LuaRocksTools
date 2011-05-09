module("luarocks.api", package.seeall)

local util = require("luarocks.util")
local _search = require("luarocks.search")
local deps = require("luarocks.deps")
local manif = require("luarocks.manif")
local fetch = require("luarocks.fetch")
local install = require("luarocks.install")
local build = require("luarocks.build")
local cfg = require("luarocks.cfg")
local fs = require("luarocks.fs")
local path = require("luarocks.path")
local dir = require("luarocks.dir")

local function version_iter (versions)
   return util.sortedpairs(versions, deps.compare_versions)
end

local function _latest(versions,first_repo)
   local version, repos = version_iter(versions)()
   local repo = repos[first_repo and 1 or #repos]
   return version, repo.repo
end

-- cool, let's initialize this baby
local trees = cfg.rocks_trees
cfg.root_dir = trees[#trees]
cfg.rocks_dir = path.rocks_dir(cfg.root_dir)

local manifests = {}

function show(name,version,field)
   local res,err = list (name,version,{exact = true})
   if not res then return nil,err end
   res = res[1]
   if field then return res[field]
   else return res
   end
end

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
       -- following loop is trying to find the latest version in the global repo
      local version,repo_url = _latest(versions,false)
      local repo = tree_map[repo_url]
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
           if not manifest then
              manifest = manif.load_manifest(repo_url)
              manifests[repo_url] = manifest
            end
           minfo = manifest.repository[name][version][1]
      end

      local entry =  {
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
      table.insert(res,entry)
   end
   return res

end

function search (pattern,version,flags)
   flags = flags or {}
   local query = _search.make_query((pattern or ''):lower(), version)
   query.exact_name = false
   local results, err = _search.search_repos(query)
   if not results then
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
            table.insert(vss,{version=vs,repos=repos})
         end
         rec = {
            package = package,
            versions = vss
         }
      end
      table.insert(res,rec)
   end
   return res
end

