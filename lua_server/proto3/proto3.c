#include <lua.h>
#include <lauxlib.h>

#include <math.h>

static int l_sin(lua_State *L) {
	double d = lua_tonumber(L, 1); /* Get argument */
	lua_pushnumber(L, sin(d));
	return 1; /* Number of results */
}

static const struct luaL_Reg mylib [] = {
	{"mysin", l_sin},
	{NULL, NULL}
};

int luaopen_proto3(lua_State *L) {
	luaL_newlib(L, mylib);
	return 1;
}
