#include <IOKit/kext/KextManager.h>

int main(int argc, char *argv[])
{
	CFStringRef path = CFStringCreateWithCString(kCFAllocatorDefault, "/Library/Extensions/SoftRAID.kext", kCFStringEncodingUTF8);
	CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, path, kCFURLPOSIXPathStyle, true);
	OSReturn result  = KextManagerLoadKextWithURL(url, NULL);
}
