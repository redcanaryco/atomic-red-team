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
  
/**
  These structures were reverse engineered and are not an accurate representation
  of thread pool structures. They are based on analyzing private API in NTDLL.dll
  
  Use with caution. - odzhan
  Last updated: March 2019
*/

// Original: https://github.com/odzhan/injection

#ifndef TPP_H
#define TPP_H

#include "ntddk.h"

typedef struct _TP_ALPC *PTP_ALPC;

typedef void (WINAPI *PTP_ALPC_CALLBACK)(PTP_CALLBACK_INSTANCE Instance, 
  LPVOID Context, PTP_ALPC TpAlpc, LPVOID Reserved);

typedef struct _TP_SIMPLE_CALLBACK {
    PVOID                             Function;
    PVOID                             Context;
} TP_SIMPLE_CALLBACK;

typedef struct _TP_CLEANUP_GROUP {
    ULONG                             Version;
    SRWLOCK                           Lock;
    LIST_ENTRY                        GroupList1;
    PTP_SIMPLE_CALLBACK               FinalizationCallback;
    LIST_ENTRY                        GroupList2;
    ULONG64                           Unknown1;
    LIST_ENTRY                        GroupList3;
} TP_CLEANUP_GROUP, *PTP_CLEANUP_GROUP;
    
typedef struct _TP_CALLBACK_OBJECT {
    ULONG                             RefCount;
    PVOID                             CleanupGroupMember;
    PTP_CLEANUP_GROUP                 CleanupGroup;
    PTP_CLEANUP_GROUP_CANCEL_CALLBACK CleanupGroupCancelCallback;
    PTP_SIMPLE_CALLBACK               FinalizationCallback;
    LIST_ENTRY                        WorkList;
    ULONG64                           Barrier;
    ULONG64                           Unknown1;
    SRWLOCK                           SharedLock;
    TP_SIMPLE_CALLBACK                Callback;
    PACTIVATION_CONTEXT               ActivationContext;
    ULONG64                           SubProcessTag;
    GUID                              ActivityId;
    BOOL                              WorkingOnBehalfTicket;
    PVOID                             RaceDll;
    PTP_POOL                          Pool;
    LIST_ENTRY                        GroupList;
    ULONG                             Flags;
    TP_SIMPLE_CALLBACK                CallerAddress;
    TP_CALLBACK_PRIORITY              CallbackPriority;
} TP_CALLBACK_OBJECT, *PTP_CALLBACK_OBJECT;

typedef struct _TP_POOL {
    ULONG64                           RefCount;
    ULONG64                           Version;
    LIST_ENTRY                        NumaRelatedList;
    LIST_ENTRY                        PoolList;
    PVOID                             NodeList;
    
    HANDLE                            WorkerFactory;
    HANDLE                            IoCompletion;
    SRWLOCK                           PoolLock;
    LIST_ENTRY                        UnknownList1;
    LIST_ENTRY                        UnknownList2;
    
} TP_POOL, *PTP_POOL;

typedef struct _TP_WORK {
    TP_CALLBACK_OBJECT                CallbackObject;
    PVOID                             TaskId;
    ULONG64                           Unknown[4];
} TP_WORK, *PTP_WORK;

typedef struct _TP_TIMER {
    TP_CALLBACK_OBJECT                CallBackObject;
    PVOID                             TaskId;
    ULONG64                           Unknown1;
    LIST_ENTRY                        UnknownList1;
    ULONG                             Unknown2;
    SRWLOCK                           TimerLock;
    LIST_ENTRY                        UnknownList2;
    LIST_ENTRY                        UnknownList3;
    ULONG64                           TimerDueTime;
    LIST_ENTRY                        UnknownList4;
    LIST_ENTRY                        UnknownList5;
    LIST_ENTRY                        UnknownList6;
    ULONG64                           Unknown3;
    ULONG                             WindowLength;
    ULONG                             TimePeriod;
    BOOLEAN                           bFlag1;
    BOOLEAN                           bFlag2;
    BOOLEAN                           bFlag3;
    BOOLEAN                           bFlag4;
    BOOLEAN                           bFlag5;
    BOOLEAN                           bFlag6;
    BOOLEAN                           bFlag7;
    BOOLEAN                           bFlag8;
} TP_TIMER, *PTP_TIMER;

typedef struct _TP_ALPC {
    PVOID                             TaskId;
    ULONG                             NumaRelated1[2];
    LIST_ENTRY                        CleanupGroupList;
    PTP_SIMPLE_CALLBACK               FinalizationCallback;
    LIST_ENTRY                        AlpcList;
    PVOID                             ExecuteCallback;
    ULONG                             NumaRelated2[2];
    TP_CALLBACK_OBJECT                CallbackObject;
    HANDLE                            Port;
    HANDLE                            Semaphore;
    ULONG                             NumaRelated;
    ULONG                             Flag;
} TP_ALPC, *PTP_ALPC;    

typedef struct _TP_CALLBACK_INSTANCE {
    ULONG64                           Unknown1[10];
    ULONG64                           SubProcessTag;
    TP_SIMPLE_CALLBACK                Callback; 
    ULONG64                           Unknown2[4];
    PVOID                             TpWork;           // PTP_ALPC for print spooler
    ULONG64                           Unknown3[3];
    HMODULE                           Dll;
    PTP_TIMER                         Timer;
    PTP_CALLBACK_OBJECT               CallbackObject;
} TP_CALLBACK_INSTANCE, *PTP_CALLBACK_INSTANCE;

typedef struct _TP_WORKER_LIST {
    LIST_ENTRY                        TppWorkerpList;
    LIST_ENTRY                        TppPoolList;
    ULONG64                           Unknown1;
    ULONG64                           ThreadId;
    PTP_POOL                          Pool;
    BYTE                              Unknown[248];
} TP_WORKER_LIST, *PTP_WORKER_LIST;

typedef struct _TP_POOL_CALLBACK {
    TP_SIMPLE_CALLBACK                Callback;
    ULONG64                           SubProcessTag;
    ULONG64                           TimeRelated;
} TP_POOL_CALLBACK, *PTP_POOL_CALLBACK;

typedef struct _TP_POOL_DATA {
    PTP_WORKER_LIST                   Workers;
    ULONG                             PoolStatus;
    ULONG                             RefCount;
    ULONG64                           CallbackCount;
    ULONG64                           TimeRelated;
    TP_POOL_CALLBACK                  CallbackArray[2];
    ULONG64                           Reserved[5];
} TP_POOL_DATA, *PTP_POOL_DATA;

#endif