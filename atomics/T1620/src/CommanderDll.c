/*
 * CommanderDLL.c — Benign DLL that reconstructs its own Export Address Table at runtime.
 *
 * BUILD (MSVC / x64 Native Tools):
 *   cl /LD /Fe:CommanderDLL.dll CommanderDLL.c /link /NOENTRY /EXPORT:DllMain
 * 
 * Alternatively with MinGW:
 *   x86_64-w64-mingw32-gcc -shared -o CommanderDLL.dll CommanderDLL.c -lkernel32
 */

#include <windows.h>
#include <winnt.h>


__declspec(noinline)
static BOOL WINAPI StartRoutine(void) {
    return TRUE;
}


static IMAGE_NT_HEADERS* get_nt_headers(HMODULE hMod) {
    BYTE *base = (BYTE *)hMod;
    IMAGE_DOS_HEADER *dos = (IMAGE_DOS_HEADER *)base;
    return (IMAGE_NT_HEADERS *)(base + dos->e_lfanew);
}


static BYTE* find_image_tail(HMODULE hMod, IMAGE_NT_HEADERS *nt) {
    BYTE *base = (BYTE *)hMod; 
    BYTE *section_end = 0;
    for (DWORD i=0; i<nt->FileHeader.NumberOfSections; i++){
        IMAGE_SECTION_HEADER* sec = &IMAGE_FIRST_SECTION(nt)[i];
        BYTE *curr =  base + sec->VirtualAddress + sec->Misc.VirtualSize;

        if(curr>section_end){
            section_end = curr;
        }
    }
    return section_end;
}


static void build_export_directory(HMODULE hMod) {
    BYTE *base = (BYTE *)hMod;
    IMAGE_NT_HEADERS *nt = get_nt_headers(hMod);
    #define BLOCK_SIZE 0x50

    /* Step 1: Find scratch space at the tail of the mapped image */
    BYTE *tail = find_image_tail(hMod, nt);
    if (!tail) return;

    DWORD oldProtect;
    if (!VirtualProtect(tail,BLOCK_SIZE,PAGE_READWRITE,&oldProtect)) return;
    BYTE block[BLOCK_SIZE];
    memset(block, 0, BLOCK_SIZE);

    DWORD tailRVA = (DWORD)(tail - base);

    IMAGE_EXPORT_DIRECTORY *exp = (IMAGE_EXPORT_DIRECTORY *)block;
    exp->Characteristics       = 0;
    exp->TimeDateStamp         = 0;
    exp->MajorVersion          = 0;
    exp->MinorVersion          = 0;
    exp->Name                  = tailRVA + 0x32;
    exp->Base                  = 1;
    exp->NumberOfFunctions     = 1;
    exp->NumberOfNames         = 1;
    exp->AddressOfFunctions    = tailRVA + 0x28;
    exp->AddressOfNames        = tailRVA + 0x2C;
    exp->AddressOfNameOrdinals = tailRVA + 0x30;

    /* Functions array: RVA of StartRoutine, computed from its address */
    *(DWORD *)(block + 0x28) = (DWORD)((BYTE *)StartRoutine - base);

    /* Names array: RVA of the "StartRoutine" string */
    *(DWORD *)(block + 0x2C) = tailRVA + 0x43;

    /* Ordinals array: ordinal 0 */
    *(WORD *)(block + 0x30) = 0;

    /* DLL name string */
    memcpy(block + 0x32, "CommanderDll.dll", 17);

    /* Export name string */
    memcpy(block + 0x43, "StartRoutine", 13);

    /* Copy the entire block to the image tail in one shot */
    memmove(tail, block, BLOCK_SIZE);

    /* Step 4: Patch the PE data-directory to point at the new export table */
    IMAGE_DATA_DIRECTORY *exportDD =
        &nt->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT];
    VirtualProtect(exportDD, sizeof(IMAGE_DATA_DIRECTORY), PAGE_READWRITE, &oldProtect);
    exportDD->VirtualAddress = tailRVA;
    exportDD->Size           = BLOCK_SIZE;
    VirtualProtect(exportDD, sizeof(IMAGE_DATA_DIRECTORY), oldProtect, &oldProtect);
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) {
    if (fdwReason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(hinstDLL);
        build_export_directory((HMODULE)hinstDLL);
    }
    return TRUE;
}
