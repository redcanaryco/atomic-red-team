#include <windows.h>
#include <stdio.h>

#define DllExport __declspec(dllexport)

__declspec(dllexport) void PayloadFunction()
{
    HANDLE hFile;
    hFile = CreateFile("C:\\Users\\Public\\AtomicTest.txt", 
                        GENERIC_WRITE, 
                        0,
                        NULL,
                        CREATE_ALWAYS,
                        FILE_ATTRIBUTE_NORMAL,
                        NULL);

   if (hFile == INVALID_HANDLE_VALUE) 
    { 
        printf("Unable to create file\n");
        return -1;
    }

}

BOOL ClosePrintProcessor(HANDLE hPrintProcessor)
{
    return 1;
}

BOOL ControlPrintProcessor(HANDLE hPrintProcessor, DWORD Command)
{
    return 1;
}

BOOL EnumPrintProcessorDatatypesW(LPWSTR pName, LPWSTR pPrintProcessorName, DWORD Level, LPBYTE pDatatypes, DWORD cbBuf, LPDWORD pcbNeeded, LPDWORD pcReturned)
{
    // executes when DLL is loaded
    PayloadFunction();
    return 1;
}

DWORD GetPrintProcessorCapabilities(LPTSTR pValueName, DWORD dwAttributes, LPBYTE pData, DWORD nSize, LPDWORD pcbNeeded)
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

HANDLE OpenPrintProcessor(LPWSTR pPrinterName, PPRINTPROCESSOROPENDATA pPrintProcessorOpenData)
{
    return (HANDLE)11;
}

BOOL PrintDocumentOnPrintProcessor(HANDLE hPrintProcessor, LPWSTR pDocumentName)
{
    return 1;
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpReserved)
{
    switch (fdwReason)
    {
    case DLL_PROCESS_ATTACH:
        break;
    case DLL_THREAD_ATTACH:
        break;
    case DLL_PROCESS_DETACH:
        break;
    case DLL_THREAD_DETACH:
        break;
    }

    return 1;
}