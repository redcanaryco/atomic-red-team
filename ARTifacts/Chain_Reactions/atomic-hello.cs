using System;

// C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe atomic-hello.cs
// Expected Output:  Hello from Atomic Red Team! \n Press Enter To Close.

public class Program
{
    public static void Main()
    {
        Console.WriteLine("Hello from Atomic Red Team! \n Press Enter To Close.");
        Console.ReadLine();
    }
}