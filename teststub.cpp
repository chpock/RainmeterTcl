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
#include <shlwapi.h>
#include <vector>

typedef void (*NEWINITIALIZE)(void*, void*);
typedef LPCWSTR (*evalFunc)(void*, const int, const WCHAR**);

int main(int argc, const char* argv[]) {

    std::cout  << "Starting tests ..." << std::endl;

    if (argc != 2) {
        std::cout  << "ERROR: args count is not 1 - " << (argc - 1) << std::endl;
        return -1;
    }

    wchar_t szFullPath[MAX_PATH] = {};
    GetCurrentDirectory(MAX_PATH, szFullPath);
    PathAppendW(szFullPath, L"\\RainmeterTcl.dll");

    std::wcout  << L"Loading dll from " << szFullPath << L" ..." << std::endl;

    HINSTANCE hGetProcIDDLL = LoadLibrary(szFullPath);

    if (hGetProcIDDLL == NULL) {
        DWORD dw = GetLastError();
        std::cout << "failed to load dll - " << dw << std::endl;
        return -1;
    }

    void* m_PluginData;

    NEWINITIALIZE initializeFunc = (NEWINITIALIZE)GetProcAddress(hGetProcIDDLL, "Initialize");
    if (initializeFunc != NULL) {
        //std::cout << "call Initialize procedure..." << std::endl;
        ((NEWINITIALIZE)initializeFunc)(&m_PluginData, NULL);
        //std::cout << "ok." << std::endl;
    } else {
        DWORD dw = GetLastError();
        std::cout << "failed to find Initialize procedure " << dw << std::endl;
        return -1;
    }

    evalFunc eval = (evalFunc)GetProcAddress(hGetProcIDDLL, "eval");
    if (eval != NULL) {
        //std::cout << "call eval procedure..." << std::endl;
//        const WCHAR *cmd[2] = {
//            L"source",
//            L"../test.tcl"
//        };
//        const WCHAR *cmd[3] = {
//            L"puts",
//            L"xxxx"
//        };
//        std::vector<LPCWSTR> args;
//        ((evalFunc)eval)(m_PluginData, args.size(), args.data());
//        ((evalFunc)eval)(m_PluginData, 2, cmd);
        std::vector<LPCWSTR> interp_args;
        interp_args.push_back(L"source");

        wchar_t* buf = new wchar_t[1024];
        MultiByteToWideChar(CP_ACP, 0, argv[1], -1, buf, 4096);
        interp_args.push_back(buf);

        ((evalFunc)eval)(m_PluginData, interp_args.size(), interp_args.data());
        //std::cout << "ok." << std::endl;
    } else {
        DWORD dw = GetLastError();
        std::cout << "failed to find eval procedure " << dw << std::endl;
        return -1;
    }

    //std::cout << "Done" << std::endl;

}
