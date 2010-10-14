package = "rockspecifier"
version = "0.5-1"

source = {
  dir = ".", 
  url = "http://github.com/stevedonovan/LuaRocksTools/raw/master/rockspecifier/rockspecifier", 
}

description = {
  summary = "Command-line tool for generating rockspecs", 
  homepage = "http://gitub.com/stevedonovan/LuaRocksTools/blob/master/rockspecifier", 
  license = "MIT/X11", 
  maintainer = "steve.j.donovan@gmail.com", 
  detailed = [[
Rockspecifier interactively allows a user to create a rockspec for their Lua modules
and scripts. It simplifies the initial generation and understands external dependencies for C modules.
]]
}

dependencies = {
  "penlight", 
}

build = {
  type = "none", 
  install = {
    bin = {
      rockspecifier = "rockspecifier", 
    }
  }
}

