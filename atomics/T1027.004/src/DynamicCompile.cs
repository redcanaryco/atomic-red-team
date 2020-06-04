using Microsoft.CSharp;
using System.CodeDom.Compiler;
using System.Reflection;


namespace T1027_004_DynamicCompile
{
    class Program
    {
        static void Main(string[] args)
        {
            CSharpCodeProvider provider = new CSharpCodeProvider();
            CompilerParameters parameters = new CompilerParameters();
            parameters.GenerateInMemory = true;
            parameters.ReferencedAssemblies.Add("System.dll");

            CompilerResults results = provider.CompileAssemblyFromSource(parameters, GetCode());

            var cls = results.CompiledAssembly.GetType("DynamicNS.DynamicCode");
            var method = cls.GetMethod("DynamicMethod", BindingFlags.Static | BindingFlags.Public);
            method.Invoke(null, null);
        }

        static string[] GetCode()
        {
            return new string[]
            {
                @"using System;
 
                namespace DynamicNS
                {
                    public static class DynamicCode
                    {
                        public static void DynamicMethod()
                        {
                            Console.WriteLine(""T1027.004 Dynamic Compile"");
                        }
                    }
                }"
            };
        }
    }
}
