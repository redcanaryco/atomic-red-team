#include <IOKit/kext/KextManager.h>

#include <CoreFoundation/CoreFoundation.h>
#include <stdio.h>

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "usage: %s <kext-path>\n", argv[0]);
        return 2;
    }

    CFStringRef path = CFStringCreateWithCString(
        kCFAllocatorDefault, argv[1], kCFStringEncodingUTF8);
    if (path == NULL) return 2;

    CFURLRef url = CFURLCreateWithFileSystemPath(
        kCFAllocatorDefault, path, kCFURLPOSIXPathStyle, true);
    if (url == NULL) {
        CFRelease(path);
        return 2;
    }

    OSReturn result = KextManagerLoadKextWithURL(url, NULL);
    printf("KextManagerLoadKextWithURL returned 0x%08x\n",
           (unsigned int)result);

    CFRelease(url);
    CFRelease(path);
    return 0;
}
