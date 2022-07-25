using System.Diagnostics;

namespace Console
{
    class Program
    {
        static void Main(string[] args)
        {
            var proc = new ProcessStartInfo();
            proc.UseShellExecute = true;
            proc.WorkingDirectory = @"C:\Windows\System32";
            proc.FileName = @"cmd.exe";
            proc.Arguments = "/c calc.exe";
            proc.WindowStyle = ProcessWindowStyle.Hidden;
            Process.Start(proc);
        }
    }
}
