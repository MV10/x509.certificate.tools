# Outputs the thumbprint for each .cer file in the current directory

$certList = Get-ChildItem -Path . -Attributes !Directory,!Directory+Hidden -Filter *.cer
foreach ($certFile in $certList) 
{
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $cert.Import($certFile.FullName)
    Write-Host $cert.Thumbprint " ... " $certFile.Name
}
