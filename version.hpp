#pragma once

#define VER_MAJOR 0
#define VER_MINOR 0
#define VER_REVIS 1
#define VER_BUILD 419

#define _W(arg) L##arg
#define _STR(arg) _W(#arg)
#define STR(arg) _STR(arg)

#ifdef _WIN64
#define PLATFORM L"64-bit"
#else
#define PLATFORM L"32-bit"
#endif

#define PLUGIN_VERSION STR(VER_MAJOR) L"." STR(VER_MINOR) L"." STR(VER_REVIS) L"." STR(VER_BUILD) L" (" PLATFORM L")"
#define PLUGIN_NAME L"RainmeterTcl"
#define PLUGIN_DESC L"Tcl/Tk for Rainmeter"
#define PLUGIN_FILENAME L"RainmeterTcl.dll"
#define PLUGIN_AUTHOR L"Konstantin Kushnir <chpock@gmail.com>"
#define PLUGIN_COPYRIGHT L"(c) 2018 - Konstantin Kushnir"
