Set objWMIService = GetObject( "winmgmts:\\.\root\cimv2" )
Set objList = objWMIService.ExecQuery( "Select * from Win32_ComputerSystem" )

For Each objItem in objList
        strDomain = objItem.Domain
	strName = objItem.Name
	strManu = objItem.Manufacturer
	strModel = objItem.Model
	
	WScript.Echo "Domain: " & strDomain
        WScript.Echo "Computer Name: " & strName
	WScript.Echo "Manufacturer: " & strManu
	WScript.Echo "Model: " & strModel
Next
