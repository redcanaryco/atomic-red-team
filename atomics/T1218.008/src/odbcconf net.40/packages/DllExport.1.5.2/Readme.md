# [DllExport](https://github.com/3F/DllExport)

*Unmanaged Exports ( .NET DllExport )*

```
Copyright (c) 2009-2015  Robert Giesecke
Copyright (c) 2016-2017  Denis Kuzmin <entry.reg@gmail.com>
```

[![Build status](https://ci.appveyor.com/api/projects/status/yh1pnuhaqk8h334h/branch/master?svg=true)](https://ci.appveyor.com/project/3Fs/dllexport/branch/master)
[![NuGet package](https://img.shields.io/nuget/v/DllExport.svg)](https://www.nuget.org/packages/DllExport/) 
[![License](https://img.shields.io/badge/License-MIT-74A5C2.svg)](https://github.com/3F/DllExport/blob/master/LICENSE)


```csharp
[DllExport("Init", CallingConvention.Cdecl)]
public static int entrypoint(IntPtr L)
{
    // ... it will be called from Lua script

    lua_pushcclosure(L, onProc, 0);
    lua_setglobal(L, "onKeyDown");

    return 0;
}
```

* **For work with Unmanaged code/libraries (binding between .NET and C/C++ etc.), see [Conari](https://github.com/3F/Conari)**
* If you need convenient work with Lua (5.1, 5.2, 5.3, ...), see [LunaRoad](https://github.com/3F/LunaRoad)

```csharp
[DllExport("Init", CallingConvention.Cdecl)]
// __cdecl is the default calling convention for our library as and for C and C++ programs
[DllExport(CallingConvention.StdCall)]
[DllExport("MyFunc")]
[DllExport]
```

Support of Modules: Library (**.dll**) and Executable (**.exe**) [[?](https://github.com/3F/DllExport/issues/18)]


Where to look ? v1.2+ provides dynamic definitions of namespaces (ddNS feature), thus you can use what you want - details **[here](https://github.com/3F/DllExport/issues/2)**

```cpp
    Via Cecil or direct modification:

    Offset(h) 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F

    000005B0                 00 C4 7B 01 00 00 00 2F 00 12 05       .Ä{..../...
    000005C0  00 00 02 00 00 00 00 00 00 00 00 00 00 00 26 00  ..............&.
    000005D0  20 02 00 00 00 00 00 00 00 49 2E 77 61 6E 74 2E   ........I.want.   <<<-
    000005E0  74 6F 2E 66 6C 79 00 00 00 00 00 00 00 00 00 00  to.fly..........  <<<-
```

[![](https://raw.githubusercontent.com/3F/DllExport/master/Resources/img/DllExport.png)](#)
[![](https://raw.githubusercontent.com/3F/DllExport/master/Resources/img/DllExport_ordinals.png)](https://github.com/3F/DllExport/issues/11#issuecomment-250907940)

----


[Initially](https://github.com/3F/DllExport/issues/3) the original tool `UnmanagedExports` was distributed by Robert Giesecke as an closed-source tool **under the [MIT License](https://opensource.org/licenses/mit-license.php)**:

* [Official page](https://sites.google.com/site/robertgiesecke/Home/uploads/unmanagedexports) - *posted Jul 9, 2009 [ updated Dec 19, 2012 ]*
* [Official NuGet Packages](https://www.nuget.org/packages/UnmanagedExports) 

Now, we will be more open ! all details [here](https://github.com/3F/DllExport/issues/3)

## License

It still under the [MIT License (MIT)](https://github.com/3F/DllExport/blob/master/LICENSE) - be a ~free~ and open

## &

### How it works

Current features has been implemented through [ILDasm](https://github.com/3F/coreclr/tree/master/src/ildasm) & [ILAsm](https://github.com/3F/coreclr/tree/master/src/ilasm) that does the all required steps via `.export` directive.

**What inside ? or how works the .export directive ?**

Read about format PE32/PE32+, start with grammar from asmparse and move to writer:

```cpp
...
if(PASM->m_pCurMethod->m_dwExportOrdinal == 0xFFFFFFFF)
{
  PASM->m_pCurMethod->m_dwExportOrdinal = $3;
  PASM->m_pCurMethod->m_szExportAlias = $6;
  if(PASM->m_pCurMethod->m_wVTEntry == 0) PASM->m_pCurMethod->m_wVTEntry = 1;
  if(PASM->m_pCurMethod->m_wVTSlot  == 0) PASM->m_pCurMethod->m_wVTSlot = $3 + 0x8000;
}
...
EATEntry*   pEATE = new EATEntry;
pEATE->dwOrdinal = pMD->m_dwExportOrdinal;
pEATE->szAlias = pMD->m_szExportAlias ? pMD->m_szExportAlias : pMD->m_szName;
pEATE->dwStubRVA = EmitExportStub(pGlobalLabel->m_GlobalOffset+dwDelta);
m_EATList.PUSH(pEATE);
...
// logic of definition of records into EXPORT_DIRECTORY (see details from PE format)
HRESULT Assembler::CreateExportDirectory()  
{
...
    IMAGE_EXPORT_DIRECTORY  exportDirIDD;
    DWORD                   exportDirDataSize;
    BYTE                   *exportDirData;
    EATEntry               *pEATE;
    unsigned                i, L, ordBase = 0xFFFFFFFF, Ldllname;
    ...
    ~ now we're ready to miracles ~
```

or read my short explanations from here: [DllMain & the export-table](https://github.com/3F/DllExport/issues/5#issuecomment-240697109); [DllExport.dll](https://github.com/3F/DllExport/issues/28#issuecomment-281957212); [.exp & .lib](https://github.com/3F/DllExport/issues/9#issuecomment-246189220); [ordinals](https://github.com/3F/DllExport/issues/8#issuecomment-245228065) ...

### How to get DllExport

Available variants:

* NuGet PM: `Install-Package DllExport`
* [GetNuTool](https://github.com/3F/GetNuTool): `msbuild gnt.core /p:ngpackages="DllExport"` or [gnt](https://github.com/3F/GetNuTool/releases/download/v1.5/gnt.bat) /p:ngpackages="DllExport"
* NuGet Commandline: `nuget install DllExport`
* [/releases](https://github.com/3F/DllExport/releases) ( [latest](https://github.com/3F/DllExport/releases/latest) )
* [Nightly builds](https://ci.appveyor.com/project/3Fs/dllexport/history) (`/artifacts` page). But remember: It can be unstable or not work at all. Use this for tests of latest changes.

### How to Build

No requires additional steps for you, just build as you need.

Use build.bat if you need final NuGet package as a `DllExport.<version>.nupkg` etc.
* *You do not need to do anything inside IDE if you have installed [this plugin](https://visualstudiogallery.msdn.microsoft.com/0d1dbfd7-ed8a-40af-ae39-281bfeca2334/).*


### How to Debug

For example, find the DllExport.MSBuild project in solution:

* `Properties` > `Debug`:
    * `Start Action`: set as `Start External program`
        * Add full path to **msbuild.exe**, for example: C:\Program Files (x86)\MSBuild\14.0\Bin\MSBuild.exe
    * `Start Options` > `Command line arguments` write for example:

```bash
"<path_to_SolutionFile_for_debugging>.sln" /t:Build /p:Configuration=<Configuration>
```

use additional `Diagnostic` key to msbuild if you need details from .targets
```bash
"<path_to_SolutionFile_for_debugging>.sln" /verbosity:Diagnostic /t:Rebuild /p:Configuration=<Configuration>
```

Go to `Start Debugging`. Now you can debug at runtime.

### coreclr - ILAsm / ILDasm

We use **our custom versions of coreclr**, special for DllExport project - https://github.com/3F/coreclr

This helps to avoid some problems ([like this](https://github.com/3F/DllExport/issues/17)) and more...

*To build minimal version (means that it does not include all components as for original coreclr repo):*

* Restore git submodule or use repo: https://github.com/3F/coreclr.git

```bash
git submodule update --init --recursive
```

*Make sure that you have installed [CMake](https://cmake.org/download/), then build simply:*

```bash
build_s all x86 x64 Release
build_s x86 Release
```

or use
```bash
build_coreclr_x86.cmd
build_coreclr_x86_x64.cmd
```

*You can also use our binaries of coreclr separately if needed:*

* [![NuGet package](https://img.shields.io/nuget/v/ILAsm.svg)](https://www.nuget.org/packages/ILAsm/)
* Look also [here](https://github.com/3F/coreclr/issues/1)

-------------

**Support ?**

[just a note again...](https://plus.google.com/101239554716569212042/posts/6yP64gDyum1)
*I mentioned earlier that DllExport is not priority for me (current impl.) "- I will do something from current tasks, but guys, please support it with me" and... why so many support from me o_o*