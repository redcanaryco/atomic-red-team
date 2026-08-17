using System;

namespace AtomicRedTeam
{
    // Simple, benign .NET console application used only to trigger
    // the AppDomainManager load path for Atomic Red Team test T1574.014.
    // Performs no file, registry, network, or persistence actions itself.
    public class TriggerApp
    {
        public static void Main(string[] args)
        {
            Console.WriteLine("AtomicRedTeam T1574.014 TriggerApp executed successfully.");
        }
    }
}
