#include <Windows.h>
#include <iostream>

#define RM_EXPORT EXTERN_C __declspec(dllexport)

HINSTANCE G_hinstDLL;

RM_EXPORT LPCWSTR __stdcall RmReadString(void* rm, LPCWSTR option, LPCWSTR defValue, BOOL replaceMeasures)
{
    return NULL;
}

RM_EXPORT double __stdcall RmReadFormula(void* rm, LPCWSTR option, double defValue)
{
}

RM_EXPORT LPCWSTR __stdcall RmReplaceVariables(void* rm, LPCWSTR str)
{
    return NULL;
}

RM_EXPORT LPCWSTR __stdcall RmPathToAbsolute(void* rm, LPCWSTR relativePath)
{
    return NULL;
}

RM_EXPORT void* __stdcall RmGet(void* rm, int type)
{
    return NULL;
}

RM_EXPORT void __stdcall RmExecute(void* skin, LPCWSTR command)
{
}

RM_EXPORT BOOL LSLog(int level, LPCWSTR unused, LPCWSTR message)
{
}

RM_EXPORT void __stdcall RmLog(void* rm, int level, LPCWSTR message)
{
    std::wcout  << L"RMLOG [" << level << "] " << message << std::endl;
}

RM_EXPORT void RmLogF(void* rm, int level, LPCWSTR format, ...)
{
}

// Deprecated!
RM_EXPORT LPCWSTR ReadConfigString(LPCWSTR section, LPCWSTR option, LPCWSTR defValue)
{
    return NULL;
}

// Deprecated!
RM_EXPORT LPCWSTR PluginBridge(LPCWSTR command, LPCWSTR data)
{
    return NULL;
}

