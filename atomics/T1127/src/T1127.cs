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
            Console.Writeline(this.MyProperty);
            Console.WriteLine("Boom!");
            return true;
        }

        public string MyProperty { get; set; }
    }
}
