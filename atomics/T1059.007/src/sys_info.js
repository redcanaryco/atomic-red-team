var objWMIService = GetObject("winmgmts:\\\\.\\root\\cimv2");
var objList = objWMIService.ExecQuery("SELECT * FROM Win32_ComputerSystem");
var objItem = new Enumerator(objList);
for (; !objItem.atEnd(); objItem.moveNext()) {
  var strDomain = objItem.item().Domain;
  var strName = objItem.item().Name;
  var strManu = objItem.item().Manufacturer;
  var strModel = objItem.item().Model;

  WScript.Echo("Domain: " + strDomain);
  WScript.Echo("Computer Name: " + strName);
  WScript.Echo("Manufacturer: " + strManu);
  WScript.Echo("Model: " + strModel);
}
