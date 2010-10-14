## A question-driven tool for building Rockspecs

The [rockspec format](http://www.luarocks.org/en/Rockspec_format) is documented, and there is an excellent [tutorial](http://www.luarocks.org/en/Creating_a_rock) for authoring rockspecs.  It can be however a little awkward to get going when writing rockspecs, especially if you do not wish to make a career out of this activity.

A rockspec name follows a certain pattern, which must be consistent with its contents.  it is `NAME-PVERSION-RVERSION` where `PVERSION` is the package version (e.g. 0.5) and `RVERSION` is the rockspec version (e.g. 1 or 2)

It serves to provide:
    - a name and a version
    - useful metadata like maintainer and licence
    - where to get the package
    - how to build the source, if required
    - where to put the results

`rockspecifier` will ask you a set of questions, and will try to find reasonable defaults so that the process is as painless as possible. By default it runs in 'easy mode' which is verbose - (when this starts ibecoming rritating  you can use the `-x` flag to switch it into expert mode.)

There are some rules about allowed characters in package names, etc which `rockspecifier` enforces, although it currently does not do further verification (e.g. whether a dependency is actually a known LuaRocks package.  LuaRocks will quickly tell you if it cannot find a dependency.

It assumes that you will do the final editing of the rockspec using the editor of your choice. If not, you may end up publishing something with a `description.summary` field containing "short sentence about this package". You have been warned!

## Preparation

LuaRocks can deliver executable Lua scripts or Lua modules.  The first thing to consider is if there is not an [existing](http://luarocks.org/repositories/rocks) package that already serves this purpose. Make sure your package name does not conflict.

Generally I recommend you run `rockspecifier` in the same directory as the source.

The second is whether this package is truly portable to all operating systems. If it is not, then indicate so; if it is likely to run on all Unix-like operating systems, then choose 'unix' for the answer to `supported platforms`; if it relies on some particularly of that system (like the detals of the `/proc` filesystem) then be more specific (e.g 'linux'). This is much better than the user discovering something that breaks on compilation or when using it.

The dependencies are a list of existing packages on the target repository.

After this you will be asked to specify the actual modules; give the name that `require` would use, which is not necessarily the name of the package.  If it's a directory, then `rockspecifier` will assume you wish to bring in a set of Lua files in their own subpackage.

You then have to specify whether it is a Lua script, a pure Lua module or a C extension. The 'dir' question is what relative path to use, generally '.' will do unless you have put the Lua files in a separate 'src' subdirectory..

If it is a C extension, then there are extra things that need to be specified. For a simple C file, just pressing enter (accepting the derault) is usually adequate. LuaRocks will ensure that the Lua include and library paths are brought in when building.

There are sometimes extra libraries to be specified which are (assumed to be!)  part of the target system.  If an extension needs an external library, then make sure it is captured by specifying 'external headers' as well.  This will fill in the rockspec's `external_dependencies` field, which does two jobs (a) it will check for the existance of that header file before compiling and (b) allow the user to explicitly specify the locations of the library and/or header file.  For example, if the external header was `foo.h`, then an external dependency FOO is created and LuaRocks will try find `foo.h` before compiling. Putting `FOO_INCDIR=<path>' on the command-line when calling `luarocks install`can often fix common problems with wandering include file locations.

## Per-Platform Overides

There are several places where you can specify per-platform alternatives. The first is 'dependencies'. Your module may be portable, but requires basic functionality which is provided by different packages on different platforms.  If any of the dependencies you type in ends with '?' then `rockspecifier` will ask for the platform on which this dependency is needed.

Otherwise, with C extensions, the sources, external headers, include directories, external libraries, library directories and preprocessor define questions all permit this use of '?' to specify alternatives.

An example is programs that use the `readline` library.  On Windows, it is redundant (shell handles history), on OS X you just link against `readline`, and on Linux you link against `readline`,`history` and `ncurses`. 

## Verification

The suggested process is to try it out on a fairly trivial task, and then see if `luarocks make` does what you expect.  For simple single-file rocks, it will set the value of `source.url` to be a reference to the local `.lua` or `.c` file. So you can immediately also test `luarocks install package-version.rockspec`

You can then update the `source.url` field to point to an actual online resource, and try `luarocks install` again.

To distribute it to the world, you do not have to submit it to the official repository for inclusion.  A user can install your rock directly from the remote rockspec:

    $ sudo luarocks install http://example.com/downloads/frodo-1.0-1.rockspec