# Hello World XLL

This is a simple XLL, showing how to create an XLL from scratch.

## Requirements

* A 64-bit version of Excel
* [Microsoft Visual Studio 2015 Community Edition](https://www.visualstudio.com/en-us/products/visual-studio-community-vs.aspx)
* [The Excel 2010 SDX](https://www.microsoft.com/en-us/download/details.aspx?id=20199). Instructions assume this is installed at C:\2010 Office System Developer Resources\Excel2010XLLSDK

## Reference

For further details on creating XLLs, dealing with XLOPERs and correct memory handling, I recommend Steve Dalton's excellent [Financial Applications using Excel Add-in Development in C/C++](http://www.amazon.com/Financial-Applications-using-Excel-Development/dp/0470027975)

## Build and Load Instructions

Instructions assume the solution is at "C:\Users\Jameson\Documents\Visual Studio 2015\Projects\HelloWorldXll\HelloWorldXll.sln". Adjust the steps below according to the location your cloned this project on your system.

- Load the solution in Visual Studio.
- Build the solution (Menu: Build... Build Solution)
- In Excel, open the Add-Ins dialog (this can be done quickly with Alt-T, I)
- Click "Browse..."
- Select the XLL at "C:\Users\Jameson\Documents\Visual Studio 2015\Projects\HelloWorldXll\x64\Debug\HelloWorldXll.xll". Click OK.
- If Excel asks "A file name '...' already exists in this location. Do you want to replace it?", click Yes.
- Click Ok.
- Excel should display a dialog that says "Hello world". This is from the XLL. Click OK to dismiss the dialog.

## Creation instructions

- Create a new solution (Mone: File... New... Project)
- In Templates... Other Languages... Visual C++ select Win32. Select Win32 Project. Set Name to "HelloWorldXll". Set Solution name to "HelloWorldXll". Ensure "Create directory for solution" is checked. Click OK. Note: These instructions assume the Location is set to "C:\Users\Jameson\Documents\Visual Studio 2015\Projects". Adjust the steps below according to the location you use.
- Click Next at the Overview page.
- Select Application type "DLL". Clear the checkboxes for Precompiled header and Security Development Lifecycle. Click Finish.
- In the Solution Explorer, right click the HelloWorldXll and select Properties.
- Select Configuration "All Configurations" and Platform "x64".
- In Configuration Properties...General, Set Target Extension to ".xll".
- In Configuration Properties...C/C++...General, select "Additional Include Directories", click the dropdown arrow on the right, select "Edit...". In the Additional Include Directories dialog, click the New Line icon (it looks like a folder with a red star, in the top-right corner of the window). This will create a new line in the top input box (the ungreyed one). Click the "..." button on the right of that line, which will open a Select Directory dialog. Navigate to "C:\2010 Office System Developer Resources\Excel2010XLLSDK\INCLUDE" and click "Select Folder". Click OK to set the Additional Include Directories.
- In Configuration Proporties...Linker..Input, edit the "Additional Dependencies" as with the previous step. In the top edit box (the ungreyed one), add the text "C:\2010 Office System Developer Resources\Excel2010XLLSDK\LIB\x64\XLCALL32.LIB". Click OK to set the Additional Dependencies.
- In stdafx.h, add the following lines at the end of the file:
```c
#include <stdlib.h>
#include "xlcall.h"
```
- In HelloWorldXll.cpp add the following lines at the end of the file:
```c
short __stdcall xlAutoOpen()
{
	char *text= "Hello world";
	size_t text_len = strlen(text);
	XLOPER message;
	message.xltype = xltypeStr;
	message.val.str = (char *)malloc(text_len + 2);
	memcpy(message.val.str + 1, text, text_len + 1);
	message.val.str[0] = (char)text_len;
	XLOPER dialog_type;
	dialog_type.xltype = xltypeInt;
	dialog_type.val.w = 2;
	Excel4(xlcAlert, NULL, 2, &message, &dialog_type);
	return 1;
}
```
- In the Solution Explorer, right click the HelloWorldXll and select Add..New Item.
- In the Add New Item dialog, in the tree on the left, select Visual C++... Code. Then select Module-Definition File (.def). Set Name to "HelloWorldXll.def". Click Add.
- Change the contents of HelloWorldXll.def to:
```
EXPORTS
	xlAutoOpen
```

The solution is now ready to build and load using the instructions above.
