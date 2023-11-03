/**
  Copyright © 2016 Odzhan. All Rights Reserved.

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

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>

#include <windows.h>

#pragma comment (lib, "user32.lib")

PBYTE img=NULL;
ULONGLONG img_base;
HANDLE hFile, hMap;
LPBYTE lpAddress;
DWORD cpu_arch, flags;

// return pointer to DOS header
PIMAGE_DOS_HEADER DosHdr (void) {
  return (PIMAGE_DOS_HEADER)lpAddress;
}

// return pointer to NT header
PIMAGE_NT_HEADERS NtHdr (void) {
  return (PIMAGE_NT_HEADERS) (lpAddress + DosHdr()->e_lfanew);
}

// return pointer to File header
PIMAGE_FILE_HEADER FileHdr (void) {
  return &NtHdr()->FileHeader;
}

// determines CPU architecture of binary
BOOL is32 (void) {
  return FileHdr()->Machine==IMAGE_FILE_MACHINE_I386;
}

// determines CPU architecture of binary
BOOL is64 (void) {
  return FileHdr()->Machine==IMAGE_FILE_MACHINE_AMD64;
}

// return pointer to Optional header
LPVOID OptHdr (void) {
  return (LPVOID)&NtHdr()->OptionalHeader;
}

// return pointer to first section header
PIMAGE_SECTION_HEADER SecHdr (void)
{
  PIMAGE_NT_HEADERS nt=NtHdr();
  
  return (PIMAGE_SECTION_HEADER)((LPBYTE)&nt->OptionalHeader + 
  nt->FileHeader.SizeOfOptionalHeader);
}

DWORD DirSize (void)
{
  if (is32()) {
    return ((PIMAGE_OPTIONAL_HEADER32)OptHdr())->NumberOfRvaAndSizes;
  } else {
    return ((PIMAGE_OPTIONAL_HEADER64)OptHdr())->NumberOfRvaAndSizes;
  }
}

DWORD SecSize (void)
{
  return NtHdr()->FileHeader.NumberOfSections;
}

PIMAGE_DATA_DIRECTORY Dirs (void)
{
  if (is32()) {
    return ((PIMAGE_OPTIONAL_HEADER32)OptHdr())->DataDirectory;
  } else {
    return ((PIMAGE_OPTIONAL_HEADER64)OptHdr())->DataDirectory;
  }
}

ULONGLONG ImgBase (void)
{
  if (is32()) {
    return ((PIMAGE_OPTIONAL_HEADER32)OptHdr())->ImageBase;
  } else {
    return ((PIMAGE_OPTIONAL_HEADER64)OptHdr())->ImageBase;
  }
}

// valid dos header?
int valid_dos_hdr (void)
{
  PIMAGE_DOS_HEADER dos=DosHdr();
  if (dos->e_magic!=IMAGE_DOS_SIGNATURE) return 0;
  return (dos->e_lfanew != 0);
}

// valid nt headers
int valid_nt_hdr (void)
{
  return NtHdr()->Signature==IMAGE_NT_SIGNATURE;
}

int isObj (void) {
  PIMAGE_DOS_HEADER dos=DosHdr();
  
  return ((dos->e_magic==IMAGE_FILE_MACHINE_AMD64 ||
  dos->e_magic==IMAGE_FILE_MACHINE_I386) && 
  dos->e_sp==0);
}

DWORD rva2ofs (DWORD rva) {
  int i;
  
  PIMAGE_SECTION_HEADER sec=SecHdr();
  
  for (i=0; i<SecSize(); i++) {
    if (rva >= sec[i].VirtualAddress && rva < sec[i].VirtualAddress + sec[i].SizeOfRawData)
    return sec[i].PointerToRawData + (rva - sec[i].VirtualAddress);
  }
  return -1;
}

void bin2file (char name[], BYTE bin[], DWORD len)
{
  char fname[MAX_PATH];
  
  wsprintf (name, "%s%i.bin", name, is32() ? 32 : 64);
  
  FILE *out=fopen (name, "wb");
  if (out!=NULL)
  {
    fwrite (bin, 1, len, out);
    fclose (out);
  }
}

void dump_section (char fname[], char section[])
{
  DWORD i, ofs;
  PIMAGE_SECTION_HEADER sec=SecHdr();
  PBYTE pRawData;
  
  for (i=0; i<SecSize(); i++) 
  {
    if (strcmp((char*)sec[i].Name, section)==0) {
      printf ("\nSECTION HEADER #%i\n", i+1);
      printf ("%8s name\n",            sec[i].Name);
      printf ("%8X virtual size\n",    sec[i].Misc.VirtualSize);
    
      if (is32())
      {
        printf ("%8X virtual address (%08X to %08X)\n",
        sec[i].VirtualAddress, 
        (DWORD)img_base + sec[i].VirtualAddress, 
        (DWORD)img_base + sec[i].Misc.VirtualSize - 1);      
      } else {
        printf ("%8X virtual address (%016llX to %016llX)\n",
        sec[i].VirtualAddress, 
        img_base + sec[i].VirtualAddress, 
        img_base + sec[i].Misc.VirtualSize);
      }
      printf ("%8X size of raw data (%i bytes padding)\n",
      sec[i].SizeOfRawData, 
      sec[i].SizeOfRawData - sec[i].Misc.VirtualSize - 1);
      
      printf ("%8X file pointer to raw data (%08X to %08X)\n", 
      sec[i].PointerToRawData, sec[i].PointerToRawData, 
      sec[i].PointerToRawData + sec[i].SizeOfRawData - 1);
      
      printf ("%8X file pointer to relocation table\n",   sec[i].PointerToRelocations);
      printf ("%8X file pointer to line numbers\n",       sec[i].PointerToLinenumbers);
      printf ("%8X number of relocations\n",              sec[i].NumberOfRelocations);
      printf ("%8X number of line numbers\n",             sec[i].NumberOfLinenumbers);
      printf ("%8X flags\n",                              sec[i].Characteristics);
      
      ofs=rva2ofs (sec[i].VirtualAddress);
      if (ofs != -1)
      {
        pRawData = (PBYTE) (lpAddress + ofs);
        
        bin2file (fname, pRawData, sec[i].Misc.VirtualSize);
        break;
      }
    }
  }
}

void dump_img (char name[], char section[])
{ 
  if (!valid_dos_hdr()) {
    printf ("  [ invalid dos header\n");
    return;
  }
  
  if (!valid_nt_hdr()) {
    printf ("  [ invalid nt header\n");
    return;
  }
  
  dump_section (name, section);
}

int open_img (char f[])
{ 
  int     r=0;
  
  hFile=CreateFile (f, GENERIC_READ, FILE_SHARE_READ, 
      NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
      
  if (hFile!=INVALID_HANDLE_VALUE) {
    hMap=CreateFileMapping (hFile, NULL, PAGE_READONLY, 0, 0, NULL);
    if (hMap!=NULL) {
      lpAddress=(LPBYTE)MapViewOfFile (hMap, FILE_MAP_READ, 0, 0, 0);
      r=1;
    }
  }
  return r;
}

void close_img (void)
{
  if (lpAddress!=NULL) UnmapViewOfFile ((LPCVOID)lpAddress);
  if (hMap     !=NULL) CloseHandle (hMap);
  if (hFile    !=NULL) CloseHandle (hFile);
}

int main (int argc, char *argv[])
{
  if (argc != 3) {
    printf ("\n[ usage: xbin <exe> <section name>\n");
    return 0;
  }
  if (open_img(argv[1])) {
    if (isObj()) {
      printf ("\n[ Looks like an object file");
    } else {
      dump_img (argv[1], argv[2]);
    }
  }
  close_img();
  return 0;
}