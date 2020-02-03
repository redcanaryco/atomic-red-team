using System;
using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;

// Most basic DLL Example 

namespace MyTasks
{
    public class SimpleTask : Task
    {
        public override bool Execute()
        {
            Console.WriteLine("Boom!");
            return true;
        }

        public string MyProperty { get; set; }
    }
}
