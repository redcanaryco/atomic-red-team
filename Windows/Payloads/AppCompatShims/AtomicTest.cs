using System;

/*
mkdir C:\Tools
copy AtomicTest.Dll C:\Tools\AtomicTest.dll

C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe /platform:x86 AtomicTest.cs
From Elevated Prompt

sdbinst.exe AtomicShimx86.sdb
AtomicTest.exe
sdbinst -u AtomicShimx86.sdb

*/


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
