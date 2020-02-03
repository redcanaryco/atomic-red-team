using System;
using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;

// Most basic DLL Example 



public class T1127 : Task
{
	public override bool Execute()
	{
		Console.WriteLine(this.MyProperty);
		Console.WriteLine("Boom!");
		return true;
	}

	public string MyProperty { get; set; }
}
