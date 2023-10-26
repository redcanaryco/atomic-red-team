#pragma comment(lib, "Crypt32.lib")
#include <Windows.h>
#include <tchar.h>
#include <mssip.h>
#include <Psapi.h>

#define DLLEXPORT __declspec(dllexport)

GUID guid_GTSIP =
{
	0x00000000, 0xDEAD, 0xBEEF, {0xDE, 0xAD, 0xDE, 0xAD, 0xBA, 0xBE, 0xCA, 0xFE}
};


DLLEXPORT
STDAPI
DllRegisterServer(VOID)
{
	TCHAR strMsg[1024];

	_stprintf_s(strMsg, _countof(strMsg), TEXT("[GTSIP] %hs."), __func__);
	OutputDebugString(strMsg);

	TCHAR szFilePath[MAX_PATH];

	GetModuleFileName(GetModuleHandle(TEXT("GTSIPProvider.dll")), szFilePath, MAX_PATH);

	_stprintf_s(strMsg, _countof(strMsg), TEXT("[GTSIP] %hs says DLL = %s."), __func__, szFilePath);
	OutputDebugString(strMsg);

	SIP_ADD_NEWPROVIDER sProv = {0};
	sProv.cbStruct = sizeof(SIP_ADD_NEWPROVIDER);
	sProv.pgSubject = (GUID*)&guid_GTSIP;
	sProv.pwszDLLFileName = szFilePath;
	sProv.pwszMagicNumber = NULL;
	sProv.pwszIsFunctionName = NULL; // L"GtSipIs";
	sProv.pwszGetFuncName = L"GtSipGet";
	sProv.pwszPutFuncName = L"GtSipPut";
	sProv.pwszCreateFuncName = L"GtSipCreate";
	sProv.pwszVerifyFuncName = L"GtSipVerify";
	sProv.pwszRemoveFuncName = L"GtSipRemove";
	sProv.pwszIsFunctionNameFmt2 = L"GtSipIsFmt2";
	sProv.pwszGetCapFuncName = L"GtSipGetCap";

	if (!CryptSIPAddProvider(&sProv))
	{
		return HRESULT_FROM_WIN32(GetLastError());
	}

	return S_OK;
}


DLLEXPORT
STDAPI
DllUnregisterServer(VOID)
{
	TCHAR strMsg[1024];
	_stprintf_s(strMsg, _countof(strMsg), TEXT("[GTSIP] %hs."), __func__);
	OutputDebugString(strMsg);
	CryptSIPRemoveProvider(&guid_GTSIP);
	return S_OK;
}


DLLEXPORT
BOOL
WINAPI
GtSipIs(
	HANDLE hFile,
	GUID* pgSubject
)
{
	TCHAR strMsg[1024];
	TCHAR szFilePath[MAX_PATH];

	GetFinalPathNameByHandle(hFile, szFilePath, MAX_PATH, FILE_NAME_NORMALIZED);

	_stprintf_s(strMsg, _countof(strMsg), TEXT("[GTSIP] %hs obtained %s as a parameter."), __func__, szFilePath);
	OutputDebugString(strMsg);

	SetLastError(0);
	return FALSE;
}


DLLEXPORT
BOOL
WINAPI
GtSipIsFmt2(
	WCHAR* pwszFileName,
	GUID* pgSubject
)
{
	TCHAR strMsg[1024];
	_stprintf_s(strMsg, _countof(strMsg), TEXT("[GTSIP] %hs obtained %ws as a parameter."), __func__, pwszFileName);
	OutputDebugString(strMsg);

	SetLastError(0);
	return FALSE;
}


DLLEXPORT
BOOL
WINAPI
GtSipGetCap(
	SIP_SUBJECTINFO* pSubjectInfo,
	SIP_CAP_SET* pCaps)
{
	TCHAR strMsg[1024];
	_stprintf_s(strMsg, _countof(strMsg), TEXT("[GTSIP] %hs obtained %ws as a parameter."), __func__,
	            pSubjectInfo->pwsFileName);
	OutputDebugString(strMsg);

	pCaps->dwVersion = 2;
	pCaps->isMultiSign = 1;
	pCaps->dwReserved = 0;
	return TRUE;
}


BOOL APIENTRY DllMain(HMODULE hModule,
                      DWORD ul_reason_for_call,
                      LPVOID lpReserved
)
{
	TCHAR strMsg[1024] = {0};
	TCHAR szFilePath[MAX_PATH];

	switch (ul_reason_for_call)
	{
	case DLL_PROCESS_ATTACH:
		GetProcessImageFileName(GetCurrentProcess(), szFilePath, MAX_PATH);
		_stprintf_s(strMsg, _countof(strMsg), TEXT("[GTSIP] %hs says EXE = %s"), __func__, szFilePath);
		break;
	case DLL_THREAD_ATTACH:
		break;
	case DLL_THREAD_DETACH:
		break;
	case DLL_PROCESS_DETACH:
		break;
	default:
		break;
	}

	OutputDebugString(strMsg);

	return TRUE;
}
