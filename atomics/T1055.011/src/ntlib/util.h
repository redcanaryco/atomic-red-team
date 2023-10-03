/**
  Copyright © 2019 Odzhan. All Rights Reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

  1. Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.

  3. The name of the author may not be used to endorse or promote products
  derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY AUTHORS "AS IS" AND ANY EXPRESS OR
  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
  STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE. */

// Original: https://github.com/odzhan/injection
// modifications made by @socketz for T1055.011 (EWM) technique

#ifndef UTIL_H
#define UTIL_H

#pragma warning(disable : 4005)
#pragma warning(disable : 4311)
#pragma warning(disable : 4312)

#define UNICODE
#define _WIN32_DCOM

#include <winsock2.h>

#include <ws2tcpip.h>
#include <ProcessSnapshot.h>
#include <memoryapi.h>
#include <Wbemidl.h>
#include <iphlpapi.h>
#include <tlhelp32.h>
#include <psapi.h>
#include <shlwapi.h>
#include <dbghelp.h>
#include <richedit.h>
#include <shlobj.h>

#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stddef.h>
#include <wchar.h>
#include <windows.h>


#include "./nttpp.h"

#pragma comment(lib, "wbemuuid.lib")
#pragma comment(lib, "ole32.lib")
#pragma comment(lib, "oleAut32.lib")
#pragma comment(lib, "advapi32.lib")
#pragma comment(lib, "dbghelp.lib")
#pragma comment(lib, "winspool.lib")
#pragma comment(lib, "dbghelp.lib")
#pragma comment(lib, "user32.lib")
#pragma comment(lib, "shlwapi.lib")
#pragma comment(lib, "kernel32.lib")
#pragma comment(lib, "shell32.lib")
#pragma comment(lib, "OneCore.lib")

// Relative Virtual Address to Virtual Address
#define RVA2VA(type, base, rva) (type)((ULONG_PTR) base + rva)

// allocate memory
LPVOID xmalloc (SIZE_T dwSize) {
    return HeapAlloc (GetProcessHeap(), HEAP_ZERO_MEMORY, dwSize);
}

// re-allocate memory
LPVOID xrealloc (LPVOID lpMem, SIZE_T dwSize) { 
    return HeapReAlloc (GetProcessHeap(), HEAP_ZERO_MEMORY, lpMem, dwSize);
}

// free memory
void xfree (LPVOID lpMem) {
    HeapFree (GetProcessHeap(), 0, lpMem);
}

#if !defined (__GNUC__)
/**
 *
 * Returns TRUE if process token is elevated
 *
 */
BOOL IsElevated(VOID) {
    HANDLE          hToken;
    BOOL            bResult = FALSE;
    TOKEN_ELEVATION te;
    DWORD           dwSize;
      
    if (OpenProcessToken (GetCurrentProcess(), TOKEN_QUERY, &hToken)) {
      if (GetTokenInformation (hToken, TokenElevation, &te,
          sizeof(TOKEN_ELEVATION), &dwSize)) {
        bResult = te.TokenIsElevated;
      }
      CloseHandle(hToken);
    }
    return bResult;
}
#endif

// display error message for last error code
VOID xstrerror (PCHAR fmt, ...){
    PCHAR  error=NULL;
    va_list arglist;
    WCHAR   buffer[1024];
    DWORD   dwError=GetLastError();
    
    va_start(arglist, fmt);
    _vsnwprintf(buffer, ARRAYSIZE(buffer), fmt, arglist);
    va_end (arglist);
    
    if (FormatMessage (
          FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM,
          NULL, dwError, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), 
          (LPWSTR)&error, 0, NULL))
    {
      wprintf(L"  [ %s : %s\n", buffer, error);
      LocalFree (error);
    } else {
      wprintf(L"  [ %s error : %08lX\n", buffer, dwError);
    }
}

// enable or disable a privilege in current process token
BOOL SetPrivilege(PCHAR szPrivilege, BOOL bEnable){
    HANDLE           hToken;
    BOOL             bResult;
    LUID             luid;
    TOKEN_PRIVILEGES tp;

    // open token for current process
    bResult = OpenProcessToken(GetCurrentProcess(),
      TOKEN_ADJUST_PRIVILEGES, &hToken);
    
    if(!bResult)return FALSE;
    
    // lookup privilege
    bResult = LookupPrivilegeValueW(NULL, szPrivilege, &luid);
    
    if (bResult) {
      tp.PrivilegeCount           = 1;
      tp.Privileges[0].Luid       = luid;
      tp.Privileges[0].Attributes = bEnable?SE_PRIVILEGE_ENABLED:SE_PRIVILEGE_REMOVED;

      // adjust token
      AdjustTokenPrivileges(hToken, FALSE, &tp, 0, NULL, NULL);
      bResult = GetLastError() == ERROR_SUCCESS;
    }
    CloseHandle(hToken);
    return bResult;
}

DWORD name2pid(LPWSTR ImageName) {
    HANDLE         hSnap;
    PROCESSENTRY32 pe32;
    DWORD          dwPid=0;
    
    // create snapshot of system
    hSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if(hSnap == INVALID_HANDLE_VALUE) return 0;
    
    pe32.dwSize = sizeof(PROCESSENTRY32);

    // get first process
    if(Process32First(hSnap, &pe32)){
      do {
        if (lstrcmpi(ImageName, pe32.szExeFile)==0) {
          dwPid = pe32.th32ProcessID;
          break;
        }
      } while(Process32Next(hSnap, &pe32));
    }
    CloseHandle(hSnap);
    return dwPid;
}

PCHAR pid2name(DWORD pid) {
    HANDLE         hSnap;
    BOOL           bResult;
    PROCESSENTRY32 pe32;
    PCHAR         name=L"N/A";
    
    hSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    
    if (hSnap != INVALID_HANDLE_VALUE) {
      pe32.dwSize = sizeof(PROCESSENTRY32);
      
      bResult = Process32First(hSnap, &pe32);
      while (bResult) {
        if (pe32.th32ProcessID == pid) {
          name = pe32.szExeFile;
          break;
        }
        bResult = Process32Next(hSnap, &pe32);
      }
      CloseHandle(hSnap);
    }
    return name;
}

LPVOID GetRemoteModuleHandle(DWORD pid, LPCWSTR lpModuleName) {
    HANDLE        ss;
    MODULEENTRY32 me;
    LPVOID        ba = NULL;
    
    ss = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, pid);
    
    if(ss == INVALID_HANDLE_VALUE) return NULL;
    
    me.dwSize = sizeof(MODULEENTRY32);
    
    if(Module32First(ss, &me)) {
      do {
        if(me.th32ProcessID == pid) {
          if(lstrcmpi(me.szModule, lpModuleName)==0) {
            ba = me.modBaseAddr;
            break;
          }
        }
      } while(Module32Next(ss, &me));
    }
    CloseHandle(ss);
    return ba;
}

PCHAR addr2sym(HANDLE hp, LPVOID addr) {
    WCHAR        path[MAX_PATH];
    BYTE         buf[sizeof(SYMBOL_INFO)+MAX_SYM_NAME*sizeof(WCHAR)];
    PSYMBOL_INFO si=(PSYMBOL_INFO)buf;
    static WCHAR name[MAX_PATH];
    
    ZeroMemory(path, ARRAYSIZE(path));
    ZeroMemory(name, ARRAYSIZE(name));
          
    GetMappedFileName(
      hp, addr, path, MAX_PATH);
    
    PathStripPath(path);
    
    si->SizeOfStruct = sizeof(SYMBOL_INFO);
    si->MaxNameLen   = MAX_SYM_NAME;
    
    if(SymFromAddr(hp, (DWORD64)addr, NULL, si)) {
      wsprintf(name, L"%s!%hs", path, si->Name);
    } else {
      lstrcpy(name, path);
    }
    return name;
}

PCHAR wnd2proc(HWND hw) {
    PCHAR         name=L"N/A";
    DWORD          pid;
    HANDLE         ss;
    BOOL           bResult;
    PROCESSENTRY32 pe;
    
    GetWindowThreadProcessId(hw, &pid);
    
    ss = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    
    if(ss != INVALID_HANDLE_VALUE) {
      pe.dwSize = sizeof(PROCESSENTRY32);
      
      bResult = Process32First(ss, &pe);
      while (bResult) {
        if (pe.th32ProcessID == pid) {
          name = pe.szExeFile;
          break;
        }
        bResult = Process32Next(ss, &pe);
      }
      CloseHandle(ss);
    }
    return name;
}

void ShowProcessIntegrityLevel(DWORD pid)
{
 HANDLE hToken;
 HANDLE hProcess;

 DWORD dwLengthNeeded;
 DWORD dwError = ERROR_SUCCESS;

 PTOKEN_MANDATORY_LABEL pTIL = NULL;
 LPWSTR pStringSid;
 DWORD dwIntegrityLevel;
 
 hProcess = OpenProcess(PROCESS_ALL_ACCESS,FALSE,pid);
 if (OpenProcessToken(hProcess, TOKEN_QUERY, &hToken)) 
 {
  // Get the Integrity level.
  if (!GetTokenInformation(hToken, TokenIntegrityLevel, 
      NULL, 0, &dwLengthNeeded))
  {
   dwError = GetLastError();
   if (dwError == ERROR_INSUFFICIENT_BUFFER)
   {
    pTIL = (PTOKEN_MANDATORY_LABEL)LocalAlloc(0, 
         dwLengthNeeded);
    if (pTIL != NULL)
    {
     if (GetTokenInformation(hToken, TokenIntegrityLevel, 
         pTIL, dwLengthNeeded, &dwLengthNeeded))
     {
      dwIntegrityLevel = *GetSidSubAuthority(pTIL->Label.Sid, 
        (DWORD)(UCHAR)(*GetSidSubAuthorityCount(pTIL->Label.Sid)-1));
 
      if (dwIntegrityLevel == SECURITY_MANDATORY_LOW_RID)
      {
       // Low Integrity
       wprintf(L"Low");
      }
      else if (dwIntegrityLevel >= SECURITY_MANDATORY_MEDIUM_RID && 
           dwIntegrityLevel < SECURITY_MANDATORY_HIGH_RID)
      {
       // Medium Integrity
       wprintf(L"Medium");
      }
      else if (dwIntegrityLevel >= SECURITY_MANDATORY_HIGH_RID)
      {
       // High Integrity
       wprintf(L"High Integrity");
      }
      else if (dwIntegrityLevel >= SECURITY_MANDATORY_SYSTEM_RID)
      {
       // System Integrity
       wprintf(L"System Integrity");
      }
     }
     LocalFree(pTIL);
    }
   }
  }
  CloseHandle(hToken);
 }
 CloseHandle(hProcess);
 putchar('\n');
}

/**
  read a shellcode from disk into memory
*/
DWORD readpic(PCHAR path, LPVOID *pic){
    HANDLE hf;
    DWORD  len, rd=0;
    
    // 1. open the file
    hf = CreateFile(path, GENERIC_READ, 0, 0,
      OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
      
    if(hf != INVALID_HANDLE_VALUE){
      // get file size
      len = GetFileSize(hf, 0);
      // allocate memory
      *pic = malloc(len + 16);
      // read file contents into memory
      ReadFile(hf, *pic, len, &rd, 0);
      CloseHandle(hf);
    }
    return rd;
}

// returns TRUE if ptr is heap
BOOL IsHeapPtr(LPVOID ptr) {
    MEMORY_BASIC_INFORMATION mbi;
    DWORD                    res;
    
    if(ptr == NULL) return FALSE;
    
    // query the pointer
    res = VirtualQuery(ptr, &mbi, sizeof(mbi));
    if(res != sizeof(mbi)) return FALSE;

    return ((mbi.State   == MEM_COMMIT    ) &&
            (mbi.Type    == MEM_PRIVATE   ) && 
            (mbi.Protect == PAGE_READWRITE));
}

// returns TRUE if ptr is .data
BOOL IsDataPtr(LPVOID ptr) {
    MEMORY_BASIC_INFORMATION mbi;
    DWORD                    res;
    
    if(ptr == NULL) return FALSE;
    
    // query the pointer
    res = VirtualQuery(ptr, &mbi, sizeof(mbi));
    if(res != sizeof(mbi)) return FALSE;

    return ((mbi.State   == MEM_COMMIT    ) &&
            (mbi.Type    == MEM_IMAGE     ) && 
            (mbi.Protect == PAGE_READWRITE));
}

// returns TRUE if ptr is RX code
BOOL IsCodePtr(LPVOID ptr) {
    MEMORY_BASIC_INFORMATION mbi;
    DWORD                    res;
    
    if(ptr == NULL) return FALSE;
    
    // query the pointer
    res = VirtualQuery(ptr, &mbi, sizeof(mbi));
    if(res != sizeof(mbi)) return FALSE;

    return ((mbi.State   == MEM_COMMIT    ) &&
            (mbi.Type    == MEM_IMAGE     ) && 
            (mbi.Protect == PAGE_EXECUTE_READ));
}

BOOL IsCodePtrEx(HANDLE hp, LPVOID ptr) {
    MEMORY_BASIC_INFORMATION mbi;
    DWORD                    res;
    
    if(ptr == NULL) return FALSE;
    
    // query the pointer
    res = VirtualQueryEx(hp, ptr, &mbi, sizeof(mbi));
    if(res != sizeof(mbi)) return FALSE;

    return ((mbi.State   == MEM_COMMIT    ) &&
            (mbi.Type    == MEM_IMAGE     ) && 
            (mbi.Protect == PAGE_EXECUTE_READ));
}

BOOL IsMapPtr(LPVOID ptr) {
    MEMORY_BASIC_INFORMATION mbi;
    DWORD                    res;
    
    if(ptr == NULL) return FALSE;
    
    // query the pointer
    res = VirtualQuery(ptr, &mbi, sizeof(mbi));
    if(res != sizeof(mbi)) return FALSE;

    return ((mbi.State   == MEM_COMMIT) &&
            (mbi.Type    == MEM_MAPPED));
}

BOOL IsReadWritePtr(LPVOID ptr) {
    MEMORY_BASIC_INFORMATION mbi;
    DWORD                    res;
    
    if(ptr == NULL) return FALSE;
    
    // query the pointer
    res = VirtualQuery(ptr, &mbi, sizeof(mbi));
    if(res != sizeof(mbi)) return FALSE;

    return (mbi.Protect == PAGE_READWRITE);    
}

#endif