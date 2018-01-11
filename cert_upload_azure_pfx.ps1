[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$password = "",
    [Parameter(Mandatory=$true)][string]$pfxFilename = "",
    [Parameter(Mandatory=$true)][string]$keyVaultName = "",
    [Parameter(Mandatory=$true)][string]$secretName = ""
)

$cwd = Convert-Path .
$pfxFile = "$cwd\$pfxFilename.pfx"

# abort when file not found
if(!(Test-Path($pfxFile)))
{
    Write-Warning "Failed, $pfxFilename.pfx not found $cwd"
    Exit
}

# force Azure login, if needed
function CheckLogin
{
    $needLogin = $true
    Try 
    {
        $content = Get-AzureRmContext
        if ($content) 
        {
            $needLogin = ([string]::IsNullOrEmpty($content.Account))
        } 
    } 
    Catch 
    {
        if ($_ -like "*Login-AzureRmAccount to login*") 
        {
            $needLogin = $true
        } 
        else 
        {
            throw
        }
    }

    if ($needLogin)
    {
        Login-AzureRmAccount
    }
}

CheckLogin

# load the PFX
$flag = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable
$coll = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection 
$coll.Import($pfxFile, $password, $flag)

# export to byte array
$type = [System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12
$bytes = $coll.Export($type)

# base64 encode
$base64 = [System.Convert]::ToBase64String($bytes)
$value = ConvertTo-SecureString -String $base64 -AsPlainText –Force

# send it to Azure KeyVault
$type = 'application/x-pkcs12'
Set-AzureKeyVaultSecret -VaultName $keyVaultName -Name $secretName -SecretValue $value -ContentType $type
