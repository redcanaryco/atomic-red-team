#include "pch.h"
#include <windows.h>
#include <stdio.h>
#include <fstream> 

#define DllExport __declspec(dllexport)

extern "C" __declspec(dllexport) void PayloadFunction()
{
    std::ofstream outfile("C:\\Users\\Public\\AtomicTest.txt");
    outfile << "AtomicRedTeam test for T1547.012" << std::endl;
    outfile.close();
}

extern "C" DllExport BOOL ClosePrintProcessor(HANDLE hPrintProcessor)
{
    return 1;
}

extern "C" DllExport BOOL ControlPrintProcessor(HANDLE hPrintProcessor, DWORD Command)
{
    return 1;
}

BOOL EnumPrintProcessorDatatypesW(LPWSTR pName, LPWSTR pPrintProcessorName, DWORD Level, LPBYTE pDatatypes, DWORD cbBuf, LPDWORD pcbNeeded, LPDWORD pcReturned)
{
    // executes when DLL is loaded
    return 1;
}

extern "C" DllExport DWORD GetPrintProcessorCapabilities(LPTSTR pValueName, DWORD dwAttributes, LPBYTE pData, DWORD nSize, LPDWORD pcbNeeded)
{
    return 0;
}

typedef struct _PRINTPROCESSOROPENDATA {
    PDEVMODE pDevMode;
    LPWSTR   pDatatype;
    LPWSTR   pParameters;
    LPWSTR   pDocumentName;
    DWORD    JobId;
    LPWSTR   pOutputFile;
    LPWSTR   pPrinterName;
} PRINTPROCESSOROPENDATA, * PPRINTPROCESSOROPENDATA, * LPPRINTPROCESSOROPENDATA;

extern "C" DllExport HANDLE OpenPrintProcessor(LPWSTR pPrinterName, PPRINTPROCESSOROPENDATA pPrintProcessorOpenData)
{
    return (HANDLE)11;
}

extern "C" DllExport BOOL PrintDocumentOnPrintProcessor(HANDLE hPrintProcessor, LPWSTR pDocumentName)
{
    return 1;
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpReserved)
{
    switch (fdwReason)
    {
    case DLL_PROCESS_ATTACH:
        PayloadFunction();
        break;
    case DLL_THREAD_ATTACH:
    case DLL_PROCESS_DETACH:
    case DLL_THREAD_DETACH:
        break;
    }

    return 1;
}