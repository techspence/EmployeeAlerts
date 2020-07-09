<#
    .Synopsis
        A PowerShell script that checks employee information in Active Directory and sends an report with missing information to the Admin.
        
        Employee information this script checks for:
            - Email
            - Phone number and extension
            - Manager
            - Job Title
            - Department 
            - Start Date
            - Office (HQ or Remote)
            - Home Folder

              Name: EmployeeInfoMissing.ps1
            Author: Spencer Alessi
       Assumptions: 
          Modified: 07/09/2020
#>

$searchQuery   = Get-ADUser -Filter * -Properties * -SearchBase "ou=yourOU,ou=yourDOMAIN,dc=yourDOMAIN,dc=com"
$searchCount   = ($searchQuery | Measure-Object).Count

foreach ($employee in $searchQuery) {
  if ($employee.Office) {
    # These people have something in the Office field
    Write-Host "$($employee.Name) - $($employee.Office)"
  } else {
    # These people DON'T have something in the Office field
    Write-Host "$($employee.Name) - $($employee.Office)"
  }

  if ($employee.telephoneNumber) {
    # These people have phone numbers entered
    Write-Host "$($employee.Name) $($employee.telephoneNumber)"
  } else {
    # These people DON'T have phone numbers entered
    Write-Host "$($employee.Name) $($employee.telephoneNumber)"
  }
  
}


