using System;

// C:\Users\subTee\Downloads\Shims>c:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe /platform:x86 AtomicTest.cs
// From Elevated Prompt
// sdbinst.exe AtomicShim.sdb 

public class AtomicTest
{
	public static void Main()
	{	
		Console.WriteLine("Boom!");
	}
	
	public static bool Thing()
	{
		Console.WriteLine("Things!");
		return true;
	}
}