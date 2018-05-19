/*
 RainmeterTcl
 Copyright (C) 2018 Konstantin Kushnir <chpock@gmail.com>

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
*/

#include <Windows.h>
#include "src/rainmeter-plugin-sdk/API/RainmeterAPI.h"
#include "version.hpp"

#define STATIC_BUILD
#include <tcl.h>
#include <tk.h>
#undef STATIC_BUILD

HINSTANCE G_hinstDLL;

#ifdef __cplusplus
extern "C" {
#endif

extern Tcl_AppInitProc Mk4tcl_Init;
extern Tcl_AppInitProc Vfs_Init;
extern Tcl_AppInitProc Thread_Init;
extern Tcl_AppInitProc Twapi_Init;

extern Tcl_AppInitProc TclZlibInit;

extern char* TclSetPreInitScript (char*);

#ifdef __cplusplus
}
#endif

typedef struct Measure {
    Tcl_Interp *interp;
    Tcl_DString getStringResult;
    Tcl_DString evalStringResult;
} Measure;

static int RmGetCmd(ClientData rm, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]) {

    int type = 0;

    // no error handling :(
    Tcl_GetIntFromObj(interp, objv[1], &type);

    LPCWSTR result = (LPCWSTR)RmGet(rm, type);

    Tcl_DString dsResult;
    Tcl_WinTCharToUtf(result, -1, &dsResult);

    Tcl_DStringResult(interp, &dsResult);

    return TCL_OK;

}

static int RmExecuteCmd(ClientData skin, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]) {

    Tcl_DString dsStr;
    RmExecute(skin, (LPCWSTR)Tcl_WinUtfToTChar(Tcl_GetString(objv[1]), -1, &dsStr));
    Tcl_DStringFree(&dsStr);

    Tcl_ResetResult(interp);

    return TCL_OK;

}

static int RmPathToAbsoluteCmd(ClientData rm, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]) {

    Tcl_DString dsStr;
    LPCWSTR result = RmPathToAbsolute(rm, (LPCWSTR)Tcl_WinUtfToTChar(Tcl_GetString(objv[1]), -1, &dsStr));
    Tcl_DStringFree(&dsStr);

    Tcl_DString dsResult;
    Tcl_WinTCharToUtf(result, -1, &dsResult);

    Tcl_DStringResult(interp, &dsResult);

    return TCL_OK;

}

static int RmReplaceVariablesCmd(ClientData rm, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]) {

    Tcl_DString dsStr;
    LPCWSTR result = RmReplaceVariables(rm, (LPCWSTR)Tcl_WinUtfToTChar(Tcl_GetString(objv[1]), -1, &dsStr));
    Tcl_DStringFree(&dsStr);

    Tcl_DString dsResult;
    Tcl_WinTCharToUtf(result, -1, &dsResult);

    Tcl_DStringResult(interp, &dsResult);

    return TCL_OK;

}

static int RmLogCmd(ClientData rm, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]) {

    int level;

    Tcl_GetIntFromObj(interp, objv[1], (int *)&level);

    Tcl_DString dsMessage;
    RmLog(rm, level, (LPCWSTR)Tcl_WinUtfToTChar(Tcl_GetString(objv[2]), -1, &dsMessage));
    Tcl_DStringFree(&dsMessage);

    Tcl_SetObjResult(interp, objv[2]);

    return TCL_OK;

}

static int RmReadStringCmd(ClientData rm, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]) {

    Tcl_DString dsResult;
    Tcl_DString dsOption;
    Tcl_DString dsDefault;
    int replaceMeasures = 1;

    Tcl_GetBooleanFromObj(NULL, objv[3], &replaceMeasures);

    LPCWSTR str = RmReadString(
        rm,
        Tcl_WinUtfToTChar(Tcl_GetString(objv[1]), -1, &dsOption),
        Tcl_WinUtfToTChar(Tcl_GetString(objv[2]), -1, &dsDefault),
        replaceMeasures);

    Tcl_DStringFree(&dsOption);
    Tcl_DStringFree(&dsDefault);

    Tcl_WinTCharToUtf(str, -1, &dsResult);

    Tcl_DStringResult(interp, &dsResult);

    return TCL_OK;

}

static int RmReadFormulaCmd(ClientData rm, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]) {

    Tcl_DString dsOption;
    double defValue = 0;

    Tcl_GetDoubleFromObj(NULL, objv[2], &defValue);

    double result = RmReadFormula(
        rm,
        Tcl_WinUtfToTChar(Tcl_GetString(objv[1]), -1, &dsOption),
        defValue);

    Tcl_DStringFree(&dsOption);

    Tcl_SetObjResult(interp, Tcl_NewDoubleObj(result));

    return TCL_OK;

}

int RMT_TclStdOut(ClientData rm, CONST char * buf, int toWrite, int *errorCode) {
    *errorCode = 0;
    Tcl_SetErrno(0);
    RmLog(rm, LOG_DEBUG, (wchar_t *)buf);
    return toWrite;
};

int RMT_TclStdErr(ClientData rm, CONST char * buf, int toWrite, int *errorCode) {
    *errorCode = 0;
    Tcl_SetErrno(0);
    RmLog(rm, LOG_ERROR, (wchar_t *)buf);
    return toWrite;
};

int RMT_TclCloseChannel(ClientData instanceData, Tcl_Interp *interp) {
  return EINVAL;
};

int RMT_TclInputChannel(ClientData instanceData, char *buf, int bufSize, int *errorCodePtr) {
  return EINVAL;
};

void RMT_TclWatchChannel(ClientData instanceData, int mask) {
};

int RMT_TclGetHandleChannel(ClientData instanceData, int direction, ClientData *handlePtr) {
  return TCL_ERROR;
};

Tcl_ChannelType stderrChannelType = {
    "rmtstderrtype",            /* Type name. */
    TCL_CHANNEL_VERSION_5,      /* v5 channel */
    RMT_TclCloseChannel,        /* Close proc. */
    RMT_TclInputChannel,        /* Input proc. */
    RMT_TclStdErr,              /* Output proc. */
    NULL,                       /* NULL Seek proc. */
    NULL,                       /* NULL Set option proc. */
    NULL,                       /* NULL Get option proc. */
    RMT_TclWatchChannel,        /* Set up the notifier to watch the channel. */
    RMT_TclGetHandleChannel,    /* Get an OS handle from channel. */
    NULL,                       /* NULL close2proc. */
    NULL,                       /* NULL Set blocking or non-blocking mode. */
    NULL,                       /* NULL flush proc. */
    NULL,                       /* NULL handler proc. */
    NULL,                       /* NULL Wide seek proc. */
    NULL,                       /* NULL Thread action proc. */
    NULL                        /* NULL Truncate proc. */
};

Tcl_ChannelType stdoutChannelType = {
    "rmtstdouttype",            /* Type name. */
    TCL_CHANNEL_VERSION_5,      /* v5 channel */
    RMT_TclCloseChannel,        /* Close proc. */
    RMT_TclInputChannel,        /* Input proc. */
    RMT_TclStdOut,              /* Output proc. */
    NULL,                       /* NULL Seek proc. */
    NULL,                       /* NULL Set option proc. */
    NULL,                       /* NULL Get option proc. */
    RMT_TclWatchChannel,        /* Set up the notifier to watch the channel. */
    RMT_TclGetHandleChannel,    /* Get an OS handle from channel. */
    NULL,                       /* NULL close2proc. */
    NULL,                       /* NULL Set blocking or non-blocking mode. */
    NULL,                       /* NULL flush proc. */
    NULL,                       /* NULL handler proc. */
    NULL,                       /* NULL Wide seek proc. */
    NULL,                       /* NULL Thread action proc. */
    NULL                        /* NULL Truncate proc. */
};

static char preInitCmd[] =
"proc tclKitPreInit {} {\n"
    "rename tclKitPreInit {}\n"
    "load {} tclkitpath\n"
    "load {} zlib\n"
    "load {} Mk4tcl\n"
    "set ::tcl::kitpath [file normalize $::tcl::kitpath]\n"
    "mk::file open exe $::tcl::kitpath -readonly\n"
    "set n [mk::select exe.dirs!0.files name boot.tcl]\n"
    "array set a [mk::get exe.dirs!0.files!$n]\n"
    "if {$a(size) != [string length $a(contents)]} {\n"
        "set a(contents) [zlib decompress $a(contents)]\n"
    "}\n"
    "uplevel #0 $a(contents)\n"
"}\n"
"tclKitPreInit"
;

static int TclKitPath_Init(Tcl_Interp *interp) {

    Tcl_DString dsPath;
    WCHAR path[MAX_PATH+1];

    GetModuleFileNameW(G_hinstDLL, path, sizeof(path));

    Tcl_WinTCharToUtf(path, -1, &dsPath);
    Tcl_SetVar(interp, "::tcl::kitpath", Tcl_DStringValue(&dsPath), TCL_GLOBAL_ONLY);
    Tcl_DStringFree(&dsPath);

    return Tcl_PkgProvide(interp, "tclkitpath", "1.0");
}

PLUGIN_EXPORT void Initialize(Measure** data, void* rm) {

    *data = NULL;

    Tcl_Interp *interp = Tcl_CreateInterp();

    Tcl_StaticPackage(0, "Mk4tcl", Mk4tcl_Init, NULL);
    Tcl_StaticPackage(0, "vfs",    Vfs_Init, NULL);
    Tcl_StaticPackage(0, "Thread", Thread_Init, NULL);
    Tcl_StaticPackage(0, "zlib",   TclZlibInit, NULL);
    Tcl_StaticPackage(0, "Tk",     Tk_Init, Tk_SafeInit);
    Tcl_StaticPackage(0, "twapi",  Twapi_Init, NULL);
    Tcl_StaticPackage(0, "tclkitpath", TclKitPath_Init, NULL);

//    Tcl_Channel stdoutChannel = Tcl_CreateChannel(&stdoutChannelType, "rmtstdout", rm, TCL_WRITABLE);
//    if (stdoutChannel) {
//        Tcl_SetChannelOption(NULL, stdoutChannel,"-translation", "lf");
//        Tcl_SetChannelOption(NULL, stdoutChannel,"-buffering", "none");
//        Tcl_SetChannelOption(NULL, stdoutChannel,"-encoding", "unicode");
//        Tcl_RegisterChannel(interp, stdoutChannel);
//    }
//    Tcl_SetStdChannel(stdoutChannel, TCL_STDOUT);

//    Tcl_Channel stderrChannel = Tcl_CreateChannel(&stderrChannelType, "rmtstderr", rm, TCL_WRITABLE);
//    if (stderrChannel) {
//        Tcl_SetChannelOption(NULL, stderrChannel,"-translation", "lf");
//        Tcl_SetChannelOption(NULL, stderrChannel,"-buffering", "none");
//        Tcl_SetChannelOption(NULL, stderrChannel,"-encoding", "unicode");
//        Tcl_RegisterChannel(interp, stderrChannel);
//    }
//    Tcl_SetStdChannel(stderrChannel, TCL_STDERR);

//    if (Mk4tcl_Init(interp) != TCL_OK) {
//        RmLog(rm, LOG_ERROR, L"Could not init Mk4tcl extension");
//        Tcl_DeleteInterp(interp);
//        return;
//    }

//    if (Vfs_Init(interp) != TCL_OK) {
//        RmLog(rm, LOG_ERROR, L"Could not init vfs extension");
//        Tcl_DeleteInterp(interp);
//        return;
//    }

    if (Thread_Init(interp) != TCL_OK) {
        RmLog(rm, LOG_ERROR, L"Could not thread extension");
        Tcl_DeleteInterp(interp);
        return;
    }

//    if (TclZlibInit(interp) != TCL_OK) {
//        RmLog(rm, LOG_ERROR, L"Could not init zlib extension");
//        Tcl_DeleteInterp(interp);
//        return;
//    }

    TclSetPreInitScript(preInitCmd);
    if (Tcl_Init(interp) != TCL_OK) {
        Tcl_DString buf;
        Tcl_WinUtfToTChar(Tcl_GetStringResult(interp), -1, &buf);
        RmLog(rm, LOG_ERROR, (const wchar_t *)Tcl_DStringValue(&buf));
        Tcl_DStringFree(&buf);
        Tcl_DeleteInterp(interp);
        return;
    } else {
//        RmLog(rm, LOG_DEBUG, L"RainmeterTcl: Tcl init - OK");
    }

//    if (Tk_Init(interp) != TCL_OK) {
//        Tcl_DString buf;
//        Tcl_WinUtfToTChar(Tcl_GetStringResult(interp), -1, &buf);
//        RmLog(rm, LOG_ERROR, (const wchar_t *)Tcl_DStringValue(&buf));
//        Tcl_DStringFree(&buf);
//        Tcl_DeleteInterp(interp);
//        return;
//    } else {
//        RmLog(rm, LOG_DEBUG, L"RainmeterTcl: Tk init - OK");
//    }
//    Tcl_Eval(interp, "wm geometry . 1x1+-10000+-10000; wm overrideredirect . 1; wm transient .");

//    if (Twapi_Init(interp) != TCL_OK) {
        // temporary ignore errors
        //RmLog(rm, LOG_ERROR, L"Could not init twapi extension");
        //Tcl_DeleteInterp(interp);
        //return;
//    }

    Tcl_Eval(interp, "namespace eval ::rm::raw {}");

    Tcl_CreateObjCommand(interp, "::rm::raw::log", RmLogCmd, rm, NULL);
    Tcl_CreateObjCommand(interp, "::rm::raw::readString", RmReadStringCmd, rm, NULL);
    Tcl_CreateObjCommand(interp, "::rm::raw::readFormula", RmReadFormulaCmd, rm, NULL);
    Tcl_CreateObjCommand(interp, "::rm::raw::replaceVariables", RmReplaceVariablesCmd, rm, NULL);
    Tcl_CreateObjCommand(interp, "::rm::raw::pathToAbsolute", RmPathToAbsoluteCmd, rm, NULL);
    Tcl_CreateObjCommand(interp, "::rm::raw::get", RmGetCmd, rm, NULL);

    void* skin = RmGetSkin(rm);

    Tcl_CreateObjCommand(interp, "::rm::raw::execute", RmExecuteCmd, skin, NULL);

    Tcl_Eval(interp, "package require rm");

    *data = (Measure*)ckalloc(sizeof(Measure));
    (*data)->interp = interp;
    Tcl_DStringInit(&((*data)->getStringResult));
    Tcl_DStringInit(&((*data)->evalStringResult));

}

PLUGIN_EXPORT void Reload(Measure *data, void* rm, double* maxValue) {

    if (data == NULL || data->interp == NULL) {
        return;
    }

    Tcl_Interp *interp = data->interp;

    if (Tcl_FindCommand(interp, "Reload", NULL, TCL_GLOBAL_ONLY) == NULL) {
        return;
    }

    Tcl_Obj *objv[2];

    objv[0] = Tcl_NewStringObj("::rm::raw::Reload", -1);
    objv[1] = Tcl_NewDoubleObj(*maxValue);

    // errors are handled on the script level
    Tcl_EvalObjv(data->interp, 2, objv, TCL_EVAL_DIRECT | TCL_EVAL_GLOBAL);

    Tcl_Obj *result = Tcl_GetVar2Ex(data->interp, "::rm::raw::MaxValue", NULL, 0);

    if (result != NULL) {
        Tcl_GetDoubleFromObj(NULL, result, maxValue);
    }

}

PLUGIN_EXPORT LPCWSTR eval(Measure* data, const int argc, const WCHAR* argv[]) {

    if (data == NULL || data->interp == NULL) {
        return nullptr;
    }

    Tcl_DString ds;

    Tcl_DStringFree(&(data->evalStringResult));

    Tcl_Interp *interp = data->interp;

    Tcl_Obj *objv[argc+1];

    objv[0] = Tcl_NewStringObj("::rm::raw::Eval", -1);
    for (auto i = 0; i < argc; ++i) {
        Tcl_WinTCharToUtf(argv[i], -1, &ds);
        objv[i+1] = Tcl_NewStringObj(Tcl_DStringValue(&ds), -1);
        Tcl_DStringFree(&ds);
    }

    Tcl_EvalObjv(data->interp, argc+1, objv, TCL_EVAL_DIRECT | TCL_EVAL_GLOBAL);

    Tcl_DStringGetResult(data->interp, &ds);
    Tcl_WinUtfToTChar(Tcl_DStringValue(&ds), -1, &(data->evalStringResult));
    Tcl_DStringFree(&ds);

    return (LPCWSTR)Tcl_DStringValue(&(data->evalStringResult));

}

PLUGIN_EXPORT LPCWSTR GetString(Measure *data) {

    if (data == NULL || data->interp == NULL) {
        return nullptr;
    }

    Tcl_DStringFree(&(data->getStringResult));

    Tcl_Interp *interp = data->interp;

    const char *result = Tcl_GetVar2(interp, "::rm::raw::UpdateString", NULL, 0);

    if (result == NULL) {
        return nullptr;
    }

    Tcl_WinUtfToTChar(result, -1, &(data->getStringResult));

    return (LPCWSTR)Tcl_DStringValue(&(data->getStringResult));

}

PLUGIN_EXPORT double Update(Measure *data) {

    if (data == NULL || data->interp == NULL) {
        return 0;
    }

    Tcl_Interp *interp = data->interp;

    if (Tcl_FindCommand(interp, "Update", NULL, TCL_GLOBAL_ONLY) == NULL) {
        return 0;
    }

    Tcl_Obj *objv[1];

    objv[0] = Tcl_NewStringObj("::rm::raw::Update", -1);

    Tcl_EvalObjv(data->interp, 1, objv, TCL_EVAL_DIRECT | TCL_EVAL_GLOBAL);

    double result = 0;

    Tcl_GetDoubleFromObj(interp, Tcl_GetObjResult(interp), &result);

    return result;
}

PLUGIN_EXPORT void Finalize(Measure *data) {

    if (data == NULL) {
        return;
    }

    if (data->interp != NULL) {

        Tcl_Interp *interp = data->interp;

        Tcl_Obj *objv[1];
        objv[0] = Tcl_NewStringObj("::rm::raw::Finalize", -1);

        // errors are handled on the script level
        Tcl_EvalObjv(data->interp, 1, objv, TCL_EVAL_DIRECT | TCL_EVAL_GLOBAL);

        Tcl_DeleteInterp(data->interp);
    }

    Tcl_DStringFree(&(data->getStringResult));
    Tcl_DStringFree(&(data->evalStringResult));

    ckfree(data);

}

PLUGIN_EXPORT void ExecuteBang(Measure* data, LPCWSTR args) {

    if (data == NULL || data->interp == NULL) {
        return;
    }

    Tcl_Obj *objv[2];

    objv[0] = Tcl_NewStringObj("::rm::raw::ExecuteBang", -1);

    Tcl_DString dsArg;
    Tcl_WinTCharToUtf(args, -1, &dsArg);
    objv[1] = Tcl_NewStringObj(Tcl_DStringValue(&dsArg), -1);

    // errors are handled on the script level
    Tcl_EvalObjv(data->interp, 2, objv, TCL_EVAL_DIRECT | TCL_EVAL_GLOBAL);

    Tcl_DStringFree(&dsArg);

}

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpReserved) {
    G_hinstDLL = hinstDLL;
    return TRUE;
}
