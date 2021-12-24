# AppCert DLLs

## Usage
* Build the solution
* Move the DLL to an arbitrary location
* Create the `AppCert` value in `HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\AppCertDlls` with the path to the DLL.
* Reboot and launch Microsoft Edge. A console window should appear and confirm that the test is successful or dsplay errors. The validation text file will be dropped in C:\Users\Public\appcert.txt.
