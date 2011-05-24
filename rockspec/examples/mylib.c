// build@ gcc -shared -I/home/sdonovan/lua/include -o mylib.so mylib.c
// includes for your code
#include <string.h>
#include <math.h>

// includes for Lua
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

// defining functions callable from Lua
static int l_createtable (lua_State *L) {
  int narr = luaL_optint(L,1,0);         // initial array slots, default 0
  int nrec = luaL_optint(L,2,0);   // intialof hash slots, default 0
  lua_createtable(L,narr,nrec);
  return 1;
}

static int l_solve (lua_State *L) {
    double a = lua_tonumber(L,1);  // coeff of x*x
    double b = lua_tonumber(L,2);  // coef of x
    double c = lua_tonumber(L,3);  // constant
    double abc = b*b - 4*a*c;
    if (abc < 0.0) {
        lua_pushnil(L);
        lua_pushstring(L,"imaginary roots!");
        return 2;
    } else {
        abc = sqrt(abc);
        a = 2*a;
        lua_pushnumber(L,(-b + abc)/a);
        lua_pushnumber(L,(+b - abc)/a);
        return 2;
    }
}

static const luaL_reg mylib[] = {
    {"createtable",l_createtable},
    {"solve",l_solve},
    {NULL,NULL}
};

int luaopen_mylib_core(lua_State *L)
{
    luaL_register (L, "mylib", mylib);
    return 1;
}
