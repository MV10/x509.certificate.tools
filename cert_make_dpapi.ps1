[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$password = "",
    [Parameter(Mandatory=$true)][string]$rootDomain = ""
)

$cwd = Convert-Path .
$CerFile = "$cwd\aspnet_dpapi.cer"
$PfxFile = "$cwd\aspnet_dpapi.pfx"

# abort if files exist
if((Test-Path($PfxFile)) -or (Test-Path($CerFile)))
{
    Write-Warning "Failed, aspnet_dpapi already exists in $cwd"
    Exit
}

# settings per https://github.com/aspnet/DataProtection/issues/215#issuecomment-353606494
$cert = New-SelfSignedCertificate `
        -Subject $rootDomain `
        -DnsName $rootDomain `
        -FriendlyName "ASP.NET Data Protection $rootDomain" `
        -NotBefore (Get-Date) `
        -NotAfter (Get-Date).AddYears(10) `
        -CertStoreLocation "cert:CurrentUser\My" `
        -KeyAlgorithm RSA `
        -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" `
        -KeyLength 2048 `
        -KeyUsage KeyEncipherment, DataEncipherment
        # -HashAlgorithm SHA256 `
        # -Type Custom,DocumentEncryptionCert `
        # -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.1")

$store = 'Cert:\CurrentUser\My\' + ($cert.ThumbPrint)  
$securePass = ConvertTo-SecureString -String $password -Force -AsPlainText

Export-Certificate -Cert $store -FilePath $CerFile
Export-PfxCertificate -Cert $store -FilePath $PfxFile -Password $securePass

Write-Host "aspnet_dpapi thumbprint: " $cert.Thumbprint

