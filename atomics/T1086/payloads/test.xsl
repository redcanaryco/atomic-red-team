<?xml version='1.0'?>
<stylesheet
xmlns="http://www.w3.org/1999/XSL/Transform" xmlns:ms="urn:schemas-microsoft-com:xslt"
xmlns:user="placeholder"
version="1.0">
<output method="text"/>
	<ms:script implements-prefix="user" language="JScript">
	<![CDATA[
	var r = new ActiveXObject("WScript.Shell").Run("powershell -c \"write-host -ForegroundColor Cyan $(Get-Date -Format s) 'Download Cradle test success!';Read-Host -Prompt 'Press Enter to continue'\"");
	]]> </ms:script>
</stylesheet>
