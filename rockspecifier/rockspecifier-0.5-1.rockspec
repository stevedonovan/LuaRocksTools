package = "rockspecifier"
version = "0.5-1"

source = {
  dir = "rockspecifier", 
  url = "http://github.com/stevedonovan/LuaRocksTools/raw/master/rockspecifier/rockspecifier", 
}

description = {
  summary = "short sentence about this package", 
  homepage = "package homepage", 
  license = "MIT/X11", 
  maintainer = "your email", 
  detailed = [[
paragraph about this package
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
