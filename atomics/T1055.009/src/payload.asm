section .text
global _start

_start:
    jmp short get_path

do_open:
    pop rdi ; call-pop

    ; open("/tmp/pwned", O_CREAT|O_WRONLY, 0644)
    push 2
    pop rax
    mov rsi, 0x41
    mov dx, 0x1a4
    syscall

    ; exit(0)
    push 60
    pop rax
    xor rdi, rdi
    syscall

get_path:
    call do_open
    db "/tmp/pwned", 0