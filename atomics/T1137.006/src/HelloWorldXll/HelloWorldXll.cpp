// HelloWorldXll.cpp : Defines the exported functions for the DLL application.
//

#include "stdafx.h"


short __stdcall xlAutoOpen()
{
	char *text = "Hello world";
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