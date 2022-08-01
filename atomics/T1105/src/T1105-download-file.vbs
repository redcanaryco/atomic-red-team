Set objWinHttp = CreateObject("WinHttp.WinHttpRequest.5.1") 
URL = "https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/LICENSE.txt" 
objWinHttp.open "GET", URL, False 
objWinHttp.send ""
Dim BinaryStream
Set BinaryStream = CreateObject("ADODB.Stream")
BinaryStream.Type = 1
BinaryStream.Open
BinaryStream.Write objWinHttp.responseBody
BinaryStream.SaveToFile "Atomic-License.txt", 2
