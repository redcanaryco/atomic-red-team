; This script demonstrates obfuscation techniques and suspicious behaviors

; Hide the AutoIt window
#NoTrayIcon

; Delay execution to avoid detection
Sleep(2000)

; Randomize variable names and function calls to evade static analysis
Local $s = "calc"
Local $x = "o"
Local $y = "i"
Local $z = "e"
Local $t = "r"
Local $a = "c"
Local $b = "t"
Local $c = "x"
Local $d = "e"
Local $e = "u"
Local $f = "a"
Local $g = "s"

; Create variables to store command strings
Local $command1 = $s & $x & $y & $z & $t & $a & $b & $c & $d & $e & $f & $g
Local $command2 = $s & $t & $y & $a & $c & $t

; Mimic the launch of a potentially malicious process
Run("powershell -Command ""Start-Process -FilePath 'calc.exe' -WindowStyle Hidden""", "", @SW_HIDE)

; Generate random delays between commands to avoid pattern detection
Sleep(Random(1000, 3000))

; Exit the script to avoid further detection
Exit
