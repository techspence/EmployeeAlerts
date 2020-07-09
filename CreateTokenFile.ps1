# Save a secure string such as email account credentials or Oath token to a file
$secureString     = Read-Host -AsSecureString -Prompt "Enter the string you wish to secure"
$secureTokenText  = ConvertFrom-SecureString -SecureString $secureString
Set-Content token.txt $secureTokenText