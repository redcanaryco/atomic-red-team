using System;
using System.IO;
using System.Globalization;

namespace AtomicRedTeam
{
    // Benign AppDomainManager used solely to demonstrate the
    // AppDomainManager execution-flow-hijack mechanism (T1574.014)
    // in a safe, non-destructive way. On initialization it writes a
    // single marker file containing an ISO 8601 timestamp and takes
    // no other action.
    public class AtomicAppDomainManager : AppDomainManager
    {
        public override void InitializeNewDomain(AppDomainSetup appDomainInfo)
        {
            base.InitializeNewDomain(appDomainInfo);

            try
            {
                string tempPath = Environment.GetEnvironmentVariable("TEMP");
                if (string.IsNullOrEmpty(tempPath))
                {
                    tempPath = Path.GetTempPath();
                }

                string markerPath = Path.Combine(tempPath, "T1574.014_AppDomainManager_Atomic.txt");
                string timestamp = DateTime.UtcNow.ToString("o", CultureInfo.InvariantCulture);
                string content = "AtomicRedTeam T1574.014 AppDomainManager executed at " + timestamp;

                File.WriteAllText(markerPath, content);
            }
            catch
            {
                // Intentionally swallow exceptions - this is a benign
                // detection-test artifact and must never interfere with
                // the host application's normal startup.
            }
        }
    }
}
