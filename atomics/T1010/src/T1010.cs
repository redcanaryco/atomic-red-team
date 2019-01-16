using System;
using System.Collections.Generic;
using System.Diagnostics;

/*
Author: Tony Lambert, Twitter: @ForensicITGuy
License: MIT License
Step One:
C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe T1010.cs
Step Two:
T1010.exe
*/

namespace WindowLister
{
    class Lister 
    {
        static List<string> ListMainWindowTitles()
        {
            List<string> windowTitlesList = new List<string>();

            Process[] processlist = Process.GetProcesses();

            foreach (Process process in processlist)
            {
                string titleOutputLine;

                if (!String.IsNullOrEmpty(process.MainWindowTitle))
                {
                    titleOutputLine = "Process: " + process.ProcessName + " ID: " + process.Id + " Main Window title: " + process.MainWindowTitle;
                    windowTitlesList.Add(titleOutputLine);
                }
            }

            return windowTitlesList;
        }

        static void Main(string[] args) 
        {
            List<string> windowTitlesList = ListMainWindowTitles();
            windowTitlesList.ForEach(i => Console.Write("{0}\n", i));
        }
    }
}