using System;
using System.Runtime.InteropServices;

class Program
{
    // Import the necessary Windows functions from user32.dll and kernel32.dll
    [DllImport("user32.dll")]
    static extern int GetKeyboardLayoutList(int nBuff, IntPtr[] lpList);

    [DllImport("user32.dll")]
    static extern IntPtr GetKeyboardLayout(uint idThread);

    [DllImport("kernel32.dll")]
    static extern uint GetUserDefaultUILanguage();

    [DllImport("kernel32.dll")]
    static extern uint GetSystemDefaultUILanguage();

    [DllImport("kernel32.dll")]
    static extern uint GetUserDefaultLangID();

    [DllImport("kernel32.dll")]
    static extern uint GetCurrentThreadId();

    static void Main(string[] args)
    {
    
        // Get and display the active keyboard layout
        IntPtr activeLayout = GetKeyboardLayout(GetCurrentThreadId());
        string output = "\nActive Keyboard Layout (Function: GetKeyboardLayout):\n";
        output += "---------------------------------------------------\n";
        output += activeLayout.ToString("x8") + "\n";
    
        // Get and display keyboard layouts
        int numberOfLayouts = GetKeyboardLayoutList(0, null);
        IntPtr[] layoutList = new IntPtr[numberOfLayouts];
        GetKeyboardLayoutList(numberOfLayouts, layoutList);

        output += "\nDetected Keyboard Layouts (Function: GetKeyboardLayoutList):\n";
        output += "-----------------------------------------------------------\n";
        foreach (var layout in layoutList)
        {
            output += layout.ToString("x8") + "\n";
        }

        // Get and display user default UI language
        uint userDefaultUILanguage = GetUserDefaultUILanguage();
        output += "\nUser Default UI Language (Function: GetUserDefaultUILanguage):\n";
        output += "-------------------------------------------------------------\n";
        output += userDefaultUILanguage.ToString("x8") + "\n";

        // Get and display system default UI language
        uint systemDefaultUILanguage = GetSystemDefaultUILanguage();
        output += "\nSystem Default UI Language (Function: GetSystemDefaultUILanguage):\n";
        output += "-----------------------------------------------------------------\n";
        output += systemDefaultUILanguage.ToString("x8") + "\n";

        // Get and display user default language ID
        uint userDefaultLangID = GetUserDefaultLangID();
        output += "\nUser Default Language ID (Function: GetUserDefaultLangID):\n";
        output += "---------------------------------------------------------\n";
        output += userDefaultLangID.ToString("x8") + "\n";

        // Write to the console
        Console.WriteLine(output);
    }
}