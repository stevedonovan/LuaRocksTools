## Rockspec, a Library for Generating Rockspecs for LuaRocks

### 'builtin' is Best

[LuaRocks](http://www.luarocks.org) has an excellent format for describing Lua packages in a platform-independent way. Given the awkward [requirements](http://www.luarocks.org/en/Recommended_practices_for_Makefiles) for massaging makefiles to work portably with LuaRocks, it is often easier to use the [builtin](http://www.luarocks.org/en/Creating_a_rock) build back-end for C-based packages that are not too complicated.

The 'builtin' build type will automatically work across all supported platforms, and provides an [elegant mechanism](http://www.luarocks.org/en/Platform_overrides) for conditional specification of the build and any dependencies it may have.

It can, however, be a daunting task to write the rockspec, especially if you need to use per-platform overrides. The [full specification](http://www.luarocks.org/en/Rockspec_format) can be a little intimidating at first.

Although creating rockspecs seems like a marginal activity, LuaRocks is more than its official repository. It is straightforward to create a personal repository which is available to the world - it is just a Web directory with a manifest and rockspecs, with optional compiled rocks. For instance, a directory on Github pages can be used. Or you can put one on a intranet server and use it to deploy scripts. So making LuaRocks easier to use is useful for more than submitting rockspecs to the official repository.

There is an old joke about Makefiles that no-one starts out by writing one from scratch: you copy something similar and hack it until it works. This library will at least give you a good template rockspec to work with.


### The Rockspec Workflow

'rockspec' is a Lua library which allows you to specify rockspecs at a higher level. Technically, it is an embedded, declarative DSL (like the rockspec format) but the main thing is that you can use it to write short scripts which write out long rockspecs. It is in fact a specialized, small, kind of build generator (as opposed to a general, large one like CMake)

Here is the script that generated the rockspec for Rockspec itself.

    require 'rockspec'

    package('rockspec','0.1')
    depends 'penlight'
    Lua.directory '.'
    Lua.module.rockspec()

    rockspec.write()

If the library is available, running this with Lua will generate a suitable rockspec for the 'rockspec' package named `rockspec-0.1-1.rockspec`.  (I've grouped the actual script, bracketed by the two pieces of necessary boilerplate: requiring the library, and finally writing out the generated rockspec.)

The result looks like this:

    package = "rockspec"
    version = "0.1-1"

    source = {
      url = "http://rockspec.org/files/rockspec-0.1.tar.gz"
    }

    description = {
      summary = "one-line about rockspec",
      detailed = [[
       Some details about
       rockspec
      ]],
      license = "MIT/X11",
      homepage = "http://rockspec.org",
      maintainer = "you@your.org"
    }

    dependencies = {
      "penlight"
    }

    build = {
      type = "builtin",
      modules = {
        rockspec = "./rockspec.lua"
      }
    }

The idea is that you can now fill in the fields like a good citizen, and be ready to roll.  It can get tedious to type in things like your email etc, so the library will read `~/.luarocks/rockspec.cfg`. In my case this is:

    site="http://stevedonovan.github.com/files"
    email="steve.j.donovan@gmail.com"
    homepage="http://luanova.org"
    license="MIT/X11"

(On Windows, `~` means the value of `%APPDATA%`. Do a 'echo %APPDATA%' if you are in doubt.)

The main thing is that this is a properly named rocspec with all the necessary stuff already filled in, and then you can type 'luarocks make' to check if it builds and installs correctly; you can do this before making the tarball/zipball and putting it up.

### Specifying C Builds

In this case, the 'build' is pretty trivial, but it is easy to specify how to build simple C extensions.

    C.module.foo()

This gives

    build = {
      type = "builtin",
      modules = {
        foo = {
          sources = {'src/foo.c'}
        }
      }
    }

That is, the default source file is assumed to be in the `src` directory and to have the same name.  If the files are in another directory, then use `C.directory()`; you can specify a number of files:

    C.directory 'source'
    C.module.foo 'foo.c util.c'
    ==>
    modules = {
      foo = {
        sources = {'source/foo.c','source/util.c'}
      }
    }

This handles all the details of building a Lua module; the correct compiler will be used (e.g. `cl` instead of `gcc` on Windows), the correct incantation (important for OS X) and the location of the Lua includes, etc. Note that the files may be passed as a string, if they can be separated safely by spaces.

It's possible to pass other information to the build, such as other libraries to use when linking:

    C.module.foo() :libraries 'util'
    ==>
      modules = {
        foo = {
          sources = {
            "src/foo.c"
          },
          libraries = {
            "util"
          }
        }
      }

A common case is specifying an _external dependency_; most Lua extensions are bindings to some existing library:


    C.module.foo()
     :external 'bar' :include 'bar.h'

    ==>

    external_dependencies = {
      BAR = {
        header = "bar.h"
      }
    }

    build = {
      type = "builtin",
      modules = {
        foo = {
          sources = {
            "src/foo.c"
          },
          libraries = "bar",
          libdir = {
            "$(BAR_LIBDIR)"
          },
          incdirs = {
            "$(BAR_INCDIR)"
          }
        }
      }
    }

When building this extension, LuaRocks will first try to detect the external dependency named `BAR`; in particular, it will look for the location of the header file `bar.h`.  It will then create variables for the build step: which libraries to use, where to find them (`libdir`) and where to find the headers (`incdirs`). If it cannot find the header, then you will get a message like this:

    Error: Could not find expected file bar.h for BAR -- you may have to install BAR
    in your system and/or set the BAR_DIR variable

The person installing the rock has an option to set these variables;

    $> luarocks install foo BAR_INCDIR=/usr/include/bar

### Per-platform Overrides

Consider a small library `baz` which has a platform-dependent implementation; there are different files needed for the Unix and Windows implementation. Also, for Windows we need to explicitly link in the socket library.


    C.module.baz()
      :when 'unix' :add 'ubaz.c'
      :when 'win32' :add 'wbaz.c'
       :libraries 'winsock32'

The output is sufficiently scary (at first) to alone justify this library!

    build = {
      type = "builtin",
      modules = {
        baz = {
          sources = {
            "src/baz.c"
          }
        }
      },
      platforms = {
        unix = {
          module = {
            baz = {
              sources = {
                "src/baz.c",
                "src/ubaz.c"
              }
            }
          }
        },
        win32 = {
          module = {
            baz = {
              sources = {
                "src/baz.c",
                "src/wbaz.c"
              },
              libraries = {
                "winsock32"
              }
            }
          }
        }
      }
    }

One way to understand per-platform overrides in LuaRocks is to think of them as a form of conditional macro expansion. The rockspec is read in, and conditionally expanded depending on platform. So on Windows, the actual build table ends up looking like this

    build = {
      type = "builtin",
      modules = {
        baz = {
          sources = {'src/baz.c','src/wbaz.c'},
          libraries = {'winsock32'}
        }
      }
    }

Per-platform overrides can be used for dependencies as well:

    depends 'wlib'
      when 'unix' :on 'luaposix'

### Modules and Packages

Many packages deliver several modules within their own namespace.

    Lua.module.wonderland.alice()
    Lua.module.wonderland.caterpillar()

    ==>

    build = {
      type = "builtin",
      modules = {
        ["wonderland.caterpillar"] = "lua/wonderland/caterpillar.lua",
        ["wonderland.alice"] = "lua/wonderland/alice.lua"
      }
    }

Please note the default directory structure; this may not be how you want it, but then you can always be explicit:

    -- files are in same directory, flat structure.
    Lua.directory '.'
    Lua.module.wonderland.alice 'alice.lua'
    Lua.module.wonderland.caterpillar 'caterpillar.lua'

### Delivering Scripts

Apart from modules, LuaRocks can distribute Lua scripts and deploy them in the `bin` directory of the rocks tree.  The `lootool` file is actually Lua source, and should start with a Unix '#!/bin/lua' (path does not matter). You currently need to do this to ensure that the executable script is called `lootool` and not `lootool.lua` on all systems.

    Lua.install.script 'lootool'

    ==>

    build = {
      type = "builtin",
      install = {
        bin = {
          "lootool"
        }
      }
    }

`Lua.install.script` does not work like `Lua.module` - you need to provide an explicit filename. The reason for this is that the module sugar is not applicable to scripts.  You can however still use per-platform `when` calls.

### rockspec Functions

#### package(name,version,rversion)

(Required)

 * name the name of the package
 * version version of package
 * rversion version of rockspec; if not given, it is '1'

#### only(platforms)

 * platforms is an array (or space-separated list) of platforms supported by this package. It is good manners to indicate upfront whether a package can be installed by a user at all. This information may be shown in the [index](http://www.luarocks.org/repositories/rocks/) in future versions of LuaRocks, in the same way that external dependencies are.

#### depends(packages)

 * an array of package specifications, like 'luasocket' or 'foo > 0.5'.

Supports per-platform overrides.

#### Lua.module

A helper object for adding Lua modules. The default source for a qualified package like `Lua.module.foo.bar()` is `lua/foo/bar.lua`; use an explicit argument if your files are not organized this way.

#### Lua.directory

Setting the directory where Lua sources are to be found; default is `lua`.

#### Lua.install.script

A helper object for adding Lua scripts. The argument should be the relative path to the source, which should be without extension for maximum portability.

#### C.module

A helper object for adding C extension modules. Apart from the `when` per-platform operation, these modules also understand:

  * :defines (list)  a set of C preprocessor defines to use
  * :libraries (list) the libraries to link against
  * :incdirs (list)  where to find include files
  * :libdirs (list) where to find the libraries
  * :external (lib) declaring an external dependency
  * :library (lib)  giving the name of the external library name
  * :include (file) specifying the external include file to be found by LuaRocks

#### C.directory

Setting the directory where C sources are to be found; default is `src`.


#### Lua.script

### A Non-trivial Example

[LuaSocket](http://w3.impa.br/~diego/software/luasocket/) is the 'standard' networking library for Lua. If you unpack the rock you will see that it is implemented by a fairly involved pair of makefiles, about 200 lines in all.

A complete rockspec script to build and install LuaSocket follows:

    package('luasocket','2.0.2','3')

    C.module.socket.core [[
     luasocket.c auxiliar.c buffer.c except.c io.c tcp.c
     timeout.c udp.c options.c select.c inet.c
    ]]
    :defines 'LUASOCKET_DEBUG'
    :when 'unix' :add 'usocket.c'
    :when 'win32'
      :add 'wsocket.c'
      :libraries 'wsock32'

    C.module.mime.core 'mime.c'

    Lua.directory 'src'

    function socket(name)
      Lua.module.socket[name] (name..'.lua')
    end

    socket 'http'
    socket 'url'
    socket 'tp'
    socket 'ftp'
    socket 'smtp'

    Lua.module.ltn12()
    Lua.module.socket()
    Lua.module.mime()

Just to make things a little more interesting, the creation of the `socket.` namespace is helped by using a little Lua function.

This provides a much higher-level specification of the project, and is automatically as cross-platform as LuaRock's builtin build type can make it: I tested the result using both `cl` on Windows and `gcc` on Linux.

### Future Directions

There are a number of things which we can squeeze out of this specification. The first is that the library can make an appropriate tarball when we are ready to release. This can also ensure that the `source.dir` field is correctly filled in; the default is that the directory should look like `foo-1.0` but this can be overriden.

One reason I used Penlight (apart from the class support and the pretty printer) was that its higher-level file and directory operations would become useful. It is easy to check whether each specified source file actually exists, and wildcards can be supported:

    Lua.module.socket '*'

Another possibility is supporting the publishing stage; pushing the tarball up to the desired server, or copying it and the rockspec to a Github pages repository and doing a commit/push.  The challenge is providing support for the most common publishing strategies.

`rockspec` is a library, but it could just as well be driven by a script. That is, the command `rockspec` becomes an executable that (like Make) looks for a specification in the current directory. It is then possible to implement a 'make' target by invoking LuaRock, and a 'clean' target which is needed before making a tarball.


### Implementation

The first attempt at implementation involved a set of module objects which were directly modified by the methods. This lead to nasty table structures which would need to be massaged into the correct form, ignoring any 'construction' fields generated in the process. So the solution chosen was to create a class for manipulating and generating rockspec-style tables.

To understand how `PerPlatform` objects build a table, this shows a typical rockspec build table

    build = { --> root
      modules = {  --> basename is 'modules'; base points to this
        foo = 'foo.lua'  --> key = value
      }
      platforms = {
        unix = {  --> platform
          modules = {  --> basename again
            foo = 'ufoo.lua'  --> key = value for this platform
          }
        }
      }
    }

The `PerPlatform` constructor is passed:
 * the root (this is the table being constructed)
 * the type of the value (can be 'string', 'array' or 'map')
 * the key
 * the basename

To construct the above structure we need:

    bfoo = PerPlatform(build,'string','foo','modules')
    bfoo:set_value 'foo.lua'
    bfoo:set_platform 'unix'
    bfoo:set_value 'ufoo.lua'

It's important to note that there can be multiple `PerPlatform` instances which are each responsible for setting the value of a particular key; this class therefore serves as a _proxy_ for building `build` tables.

When constructing C module builtin rules, the value becomes a table of key-value pairs (a _map_). In this case the API changes and you populate the `current` field directly. To simplify the case, there are no per-platform overrides in this case:

    build = {
      modules = {
        bar = {  --> value is now a map-like table
          sources = {'bar.c','util.c'},
          libraries = {'foobar'}
        }
      }
    }

    bbar = PerPlatform(build,'map','bar','modules')
    -- note: we don't say :set_value()
    bbar.current.sources = {'bar.c','util.c'}
    bbar.current.libraries = {'foobar'}

Now the cool thing is that `bfoo` and `bbar` are proxy objects for populating the same table, so if they operate on the same table you get the total desired state.

    build = {
      modules = {
        bar = {  --> value is now a map-like table
          sources = {'bar.c','util.c'},
          libraries = {'foobar'}
        }.
        foo = 'foo.lua'
      },
      platforms = {
        unix = {  --> platform
          modules = {  --> basename again
            foo = 'ufoo.lua'  --> key = value for this platform
          }
        }
      }
    }

Other rockspec tables are done in a simular fashion:

    dependencies = { --> here we work directly on the root, there's no basename
      'alice','bob > 1.1'  --> no key; value is an array
      platforms = {
        win32 = {
         'alice','bob > 1.1','winutil'
        }
      }
    }

    bx = PerPlatform(dependencies,'array',nil,nil)
    bx:set_value {'alice','bob > 1.1'}
    bx:set_platform 'win32'
    b:set_value {'alice','bob > 1.1','winutil'}

Again, `set_value` is used. (This notation is not as consistent as I would like, and we _could_ make `current` into a 'smart pointer' using `_newindex` but it will do for now.)

Note that we have to fully specify the dependencies for the win32 case. A little bit of sugar is provided by subclassing `PerPlatform` to get a `Depends` class with some extra methods:

    class Depends(PerPlatform)

    -- provides a constructor that creates the right kind of PP and sets its initial value
    function Depends:_init(deps)
      PerPlatform._init(dependencies,'array',nil,nil)
      self:set_value(deps)
    end

    depends = Depends
    ..

    depends {'alice','bob > 1.1'}
      :when 'win32'
      :add {'winutil'}

`when` is just a version of `set_platform` which returns the object itself, so we can chain these methods. `add` takes the array value from `self.master` and appends the new values to give a new array.

Further sugar is possible. I find typing table constructors slows me down, so we allow the arguments to be strings of space-seperated words, so we can say simply `add 'winutil'`.

In a similar fashion, a subclass `Module` is provided with subclasses `LuaModule` and `CModule`.

The trick here is to extract the default value from the key. So the statement:

    C.module.foo()

must be equivalent to

    cm = PerPlatform(build,'map','foo','modules')
    cm.current.sources = {'src/foo.c'}  --> default directory for C files

Now, how to handle qualified names? For instance, how to infer the key from:

    Lua.module.foo.bar()

This requires the cooperation of two classes which combine to create `Module` instances. `Lua.module` is a `ModuleFactory` object; it has a `__index` metamethod which creates a `ModuleGen` object.

    function ModuleFactory.__index(self,key)
        return ModuleGen(self.kind,key)
    end

`ModuleGen` itself has an `__index` method which exists just to build up the full package name:

    function ModuleGen.__index(self,key)
        if rawget(self,'package') then
            self.package = key..'.'..self.package
        else
            self.package = key
        end
        return self
    end

(Please note the use of `rawget`, which is needed when fooling around with indexing. A direct access to the `package` field will cause an infinite recursion when it is not defined.)

And `ModuleGen` is also callable; this is what actually, finally, makes a module. In summary:

    Lua.module  --> a ModuleFactory for LuaModule objects
      .foo      --> creates a ModuleGen with initial key 'foo'
      .bar      --> qualifies the key: we now have 'foo.bar'
      ()        --> construct a LuaModule w/ key 'foo.bar'; default source is 'lua/foo/bar.lua'

Finally, it is a fact of life that Lua tables are not usefully ordered. The Penlight pretty-printer uses `pairs`, so the current hack is to redefine this global function so that the result becomes partially ordered. This ensures that special keys like 'type' and 'sources' are always dumped first.

Looking at the output from the LuaSocket specification shows that this approach still needs a little work: you would certainly have to do some manual re-ordering if you were submitting this to the mailing list for inclusion!




