//Check my codes for any errors, this is C code.

#pragma once
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <windows.h>
#include <ntstatus.h>

#ifndef RTL_CLONE_PROCESS_FLAGS_CREATE_SUSPENDED
#define RTL_CLONE_PROCESS_FLAGS_CREATE_SUSPENDED 0x00000001
#endif

#ifndef RTL_CLONE_PROCESS_FLAGS_INHERIT_HANDLES
#define RTL_CLONE_PROCESS_FLAGS_INHERIT_HANDLES 0x00000002
#endif

#ifndef RTL_CLONE_PROCESS_FLAGS_NO_SYNCHRONIZE
#define RTL_CLONE_PROCESS_FLAGS_NO_SYNCHRONIZE 0x00000004 // don't update synchronization objects
#endif

typedef struct {
    HANDLE UniqueProcess;
    HANDLE UniqueThread;
} T_CLIENT_ID;

typedef struct
{
    HANDLE ReflectionProcessHandle;
    HANDLE ReflectionThreadHandle;
    T_CLIENT_ID ReflectionClientId;
} T_RTLP_PROCESS_REFLECTION_REFLECTION_INFORMATION;

typedef NTSTATUS(NTAPI* RtlCreateProcessReflectionFunc) (
HANDLE ProcessHandle,
        ULONG Flags,
PVOID StartRoutine,
        PVOID StartContext,
HANDLE EventHandle,
        T_RTLP_PROCESS_REFLECTION_REFLECTION_INFORMATION* ReflectionInformation
);

// IDA Data: the internal struct for RtlCreateProcessReflection. gets passed to RtlpProcessReflectionStartup
typedef struct {
    DWORD64 unk1;
    ULONG Flags;
    PVOID StartRoutine;
    PVOID StartContext;
    PVOID unk2;
    PVOID unk3;
    PVOID EventHandle;
} ReflectionContext;
