/*
 RainmeterTcl
 Copyright (C) 2018 Konstantin Kushnir <chpock@gmail.com>

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
*/

#include <Windows.h>
#include <iostream>

#define STATIC_BUILD
#include <tcl.h>
#undef STATIC_BUILD

#ifdef __cplusplus
extern "C" {
#endif

extern Tcl_AppInitProc Mk4tcl_Init;
extern Tcl_AppInitProc Vfs_Init;

extern int TclZlibInit(Tcl_Interp *interp);
extern Tcl_Obj *TclDStringToObj(Tcl_DString *dsPtr);

#ifdef __cplusplus
}
#endif

using namespace std;

int main(int argc, char *argv[]) {
    cout  << "Starting kit build ..." << endl;

    Tcl_Interp *interp = Tcl_CreateInterp();

    Tcl_Obj *argvPtr = Tcl_NewListObj(0, NULL);
    for (auto i = 0; i < argc; ++i) {
        Tcl_DString ds;
        Tcl_ExternalToUtfDString(NULL, argv[i], -1, &ds);
        Tcl_ListObjAppendElement(NULL, argvPtr, TclDStringToObj(&ds));
    }
    Tcl_SetVar2Ex(interp, "argv", NULL, argvPtr, TCL_GLOBAL_ONLY);


    Mk4tcl_Init(interp);
    Tcl_StaticPackage(interp, "Mk4tcl", Mk4tcl_Init, NULL);
    Vfs_Init(interp);
    Tcl_StaticPackage(interp, "vfs", Vfs_Init, NULL);
    TclZlibInit(interp);

    Tcl_Eval(interp, "source [lindex $::argv 1]");

    cout  << "Done." << endl;
    return 0;
}
