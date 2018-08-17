function Disable-SslVerification
{
    if (-not ([System.Management.Automation.PSTypeName]"TrustEverything").Type)
    {
        Add-Type -TypeDefinition  @"
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;
public static class TrustEverything
{
    private static bool ValidationCallback(object sender, X509Certificate certificate, X509Chain chain,
        SslPolicyErrors sslPolicyErrors) { return true; }
    public static void SetCallback() { System.Net.ServicePointManager.ServerCertificateValidationCallback = ValidationCallback; }
    public static void UnsetCallback() { System.Net.ServicePointManager.ServerCertificateValidationCallback = null; }
}
"@
    }
    [TrustEverything]::SetCallback()
}
function Enable-SslVerification
{
    if (([System.Management.Automation.PSTypeName]"TrustEverything").Type)
    {
        [TrustEverything]::UnsetCallback()
    }
}
# The cloud server should be connected for this function to work
Function Get-vAppTemplateShadowVMs(
[Parameter(Mandatory=$true)][string]$vAppTemplate,    # Provide the name of the vapp template
[Parameter(Mandatory=$true)][string]$cloud,           #Provide the name of the cloud not the path
[string]$ApiVersion = '5.5'
)
{
Disable-SslVerification
$mySessionID = ($Global:DefaultCIServers).SessionID
#$ApiVersion = 5.5
$Headers = @{ "x-vcloud-authorization" = $mySessionID; "Accept" = 'application/*+xml;version=' + $ApiVersion }

$vapp_Template = Get-CIVAppTemplate -Name $vAppTemplate
$URI = $vapp_Template.Href
$response = Invoke-RestMethod -Method GET -Uri $URI -Headers $Headers
$vms = $response.VAppTemplate.Children.Vm
$myarray = @{}
foreach($vm in $vms) {
$vmid = $vm.id.Split(':')[3]
$vm_name = $vm.name
$VM_URI = 'https://'+$cloud+'/api/vAppTemplate/vm-'+$vmid+'/shadowVms'
$response = Invoke-RestMethod -Method GET -Uri $VM_URI -Headers $Headers
if ($response.ShadowVMReferences.VMReference)
 {
  if(!$response.ShadowVMReferences.VMReference.Count)
  {
  $myarray.Add($vm_name,1)
  }
  else {
    $myarray.Add($vm_name,$response.ShadowVMReferences.VMReference.Count)
   }
 }

 else
 {
 $myarray.Add($vm_name,0)
 }
}

($myarray.Values | Measure-Object -Sum).Sum

}