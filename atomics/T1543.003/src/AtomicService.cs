using System;
using System.Collections;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.ServiceProcess;

// c:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe AtomicService.cs
// sc create AtomicService binPath= "C:\AtomicRedTeam\atomics\T1543.003\bin\AtomicService.exe"
// sc start AtomicService
// sc stop AtomicSerivce
// sc delete AtomicSerivce
// May require Administrator privileges


namespace AtomicService
{
	public class Service1 : System.ServiceProcess.ServiceBase
	{

		private System.ComponentModel.Container components = null;

		public Service1()
		{

			InitializeComponent();

		}

		// The main entry point for the process
		static void Main()
		{
			System.ServiceProcess.ServiceBase[] ServicesToRun;

			ServicesToRun = new System.ServiceProcess.ServiceBase[] { new AtomicService.Service1()};

			System.ServiceProcess.ServiceBase.Run(ServicesToRun);
		}


		private void InitializeComponent()
		{
			//
			// Service1
			//
			this.ServiceName = "AtomicService";


		}

		protected override void Dispose( bool disposing )
		{
			if( disposing )
			{
				if (components != null)
				{
					components.Dispose();
				}
			}
			base.Dispose( disposing );
		}


		protected override void OnStart(string[] args)
		{

		}


		protected override void OnStop()
		{

		}
		protected override void OnContinue()
		{

		}
	}
}
