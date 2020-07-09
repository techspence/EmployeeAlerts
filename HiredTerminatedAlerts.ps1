<#
    .Synopsis
        A PowerShell script that searches Active Directory for newly created and newly disabled user accounts 
        (e.g. new employees/terminated employees) then sends a slack/email notification.
        

              Name: HiredTerminatedAlerts.ps1
            Author: Spencer Alessi
       Assumptions: 1. Slack App with the Bots feature & functionality enabled and a Bot User OAuth Access Token
                    2. Start date (effective date from the new user form) is added to the Telephones > Notes section
          Modified: 07/09/2020
#>

  
Function LogWrite {
    <#
        .Synopsis
            Creates a new log file if it doesn't already exist, then writes content you pass to the log file 

        .Parameter LogString
            The information you want to output to the log file
        
        .Example
            LogWrite "Send this to the log file."
    #>

    param ([String]$LogString)
    
    ### Log File Environment Variables ###
    $logPath = "C:\scripts\EmployeeAlerts\"
    $logName = "EmployeeAlerts-$(get-date -f yyyy-MM-dd).log"
    $logFile = $logPath + $logName
	
	if (!(Test-Path -Path $logPath)) {
		New-Item -ItemType Directory $logPath
	} 
	else { 
		Add-Content -Path $logFile -Value $LogString
	}
}

<#
########################################## need to do write this better/more stable

Function CompressLogs {
    <#
        .Synopsis
            Compresses all log files older than the $Days variable, then deletes the old log files 
            that were just compressed

        .Parameter Days
            The number of days until you want to compress & remove log files. Default number of days is 7

        .Example
            CompressLogs
            
        .Example
            CompressLogs -Days 30
    #>

<#
	param (
		[Parameter(Mandatory = $false)]
		[Int]$Days
    )
    $logPath = Get-ChildItem -Path $PSScriptRoot
    $logArchiveDestination = Get-Location + "\LogArchive\" + "EmployeeAlertsArchive-$(get-date -f yyyy-MM-dd).zip"
    $lastWrite = (Get-Date).AddDays(-$Days).ToString("MM/dd/yyyy")
    if ($logs = Get-ChildItem -Path $logPath | 
                Where-Object {$_.LastWriteTime -le $lastWrite -and !($_.PSIsContainer) -and $_.FullName -Match ".log"} | 
                Sort-Object LastWriteTime
        ) 
    { 
        $logFilePaths = $logs.FullName
        Compress-Archive -Path $logFilePaths -DestinationPath $logArchiveDestination -CompressionLevel Optimal -Update
        Remove-Item -Path $logFilePaths
    }
}
#>

Function AlertDescription {
    <#
        .Synopsis
            Creates a slack and/or email description message that's contextual to:
                1. If there is 1 or more new/terminated employees found
                2. If the description is going to be a slack notification or an email

        .Parameter Status
            This is the account status and can be either created or disabled

        .Parameter SearchCount
            This is the number of accounts found from searchQuery. The notification description depends on this 
            to send a message that's contextual to the number of accounts found

        .Parameter Type
            This is the type of notification desired and can be either Slack or Email

        .Example
            AlertDescription -Status $searchStatus -SearchCount $searchCount -Type Slack
            
        .Example
            AlertDescription -Status $searchStatus -SearchCount $searchCount -Type Email
    #>
    param (
        [Parameter(Mandatory = $true)]
        [String]$Status,
        
        [Parameter(Mandatory = $true)]
        [Int]$SearchCount,

        [Parameter(Mandatory = $true)]
        [String]$Type
	)
    
    if ($Status -eq "created") {
        if ($SearchCount -gt 1){
            if ($Type -eq "Slack") {
                $description = "*Newly _created_ accounts found.* The following *$SearchCount* Active Directory accounts have been $searchStatus in the last *$Days* days:"
            }

            if ($Type -eq "Email") {
                $description = "<b>Newly <i>created</i> accounts found.</b> The following <b>$SearchCount</b> Active Directory accounts have been $searchStatus in the last <b>$Days</b> days:"
            }
        } elseif ($SearchCount -eq 1) {
            if ($Type -eq "Slack") {
                $description = "*Newly _created_ account found.* The following *$SearchCount* Active Directory account has been $searchStatus in the last *$Days* day:"
            }

            if ($Type -eq "Email") {
                $description = "<b>Newly <i>created</i> account found.</b> The following <b>$SearchCount</b> Active Directory account has been $searchStatus in the last <b>$Days</b> day:"
            }
        }
    } elseif ($Status -eq "disabled") {
        if ($SearchCount -gt 1){
            if ($Type -eq "Slack") {
                $description = "*Newly disabled accounts found.* The following *$SearchCount* Active Directory accounts have been $searchStatus in the last *$Days* days:"
            }

            if ($Type -eq "Email") {
                $description = "<b>Newly <i>disabled</i> accounts found.</b> The following <b>$SearchCount</b> Active Directory accounts have been $searchStatus in the last <b>$Days</b> days:"
            }
        } elseif ($SearchCount -eq 1) {
            if ($Type -eq "Slack") {
                $description = "*Newly disabled account found.* The following *$SearchCount* Active Directory account has been $searchStatus in the last *$Days* day:"
            }

            if ($Type -eq "Email") {
                $description = "<b>Newly <i>disabled</i> account found.</b> The following <b>$SearchCount</b> Active Directory account has been $searchStatus in the last <b>$Days</b> day:"
            }
        }
    }
    
    Return $description
}  
       

Function AlertMessage {
    <#
        .Synopsis
            Creates a slack and/or email notification message that's contextual to:
                1. Whether the account(s) found are created or disabled
                2. If the description is going to be a slack notification or an email

        .Parameter Status
            This is the account status and can be either created or disabled

        .Parameter Type
            This is the type of notification desired and can be either Slack or Email

        .Parameter Employee
            This is the current employee record that's found from searchQuery

        .Example
            AlertMessage -Status $searchStatus -Type Slack -Employee $employeeRecord
        
        .Example
            AlertMessage -Status $searchStatus -Type Email -Employee $employeeRecord
    #>
    param (
        [Parameter(Mandatory = $true)]
	    [String]$Status,
        
        [Parameter(Mandatory = $true)]
		[String]$Type,
        
        [Parameter(Mandatory = $true)]
		[PSObject[]]$Employee
    )

    $slackMessage = @()
    $message = @()

    $groups = Get-ADPrincipalGroupMembership $Employee.SamAccountName | Select-Object Name
    $empDisabledDate = Get-AccountDisabledDate -Employee $employeeRecord

    if ($Status -eq "created") {
        $employeeAccountCreated = Get-Date -Date $Employee.created
        
        if ($Type -eq "Slack") {
            $slackMessage = 
            "*Name:* $($Employee.fullname) - $($Employee.title)
            *Department:* $($Employee.department) | *Manager:* $($Employee.manager)
            $($Employee.email) | $($Employee.extension)
            *Start Date:* $($Employee.startdate)
            *Groups:* $($groups.name -join ', ')
            _Created:_ _$($employeeAccountCreated)_`n`n"

            # remove 12 leading spaces to format nicely
            $message = $slackMessage -replace "            ",""
        }
        
        if ($Type -eq "Email") {
            $message = "<b>Name:</b> $($Employee.fullname) - $($Employee.title)<br/>
            <b>Department:</b> $($Employee.department) | <b>Manager:</b> $($Employee.manager)<br/>
            $($Employee.email) | $($Employee.extension)<br/>
            <b>Start Date:</b> $($Employee.startdate)<br/>
            <b>Groups:</b> $($groups.name -join ', ')<br/>
            <i>Created: $($employeeAccountCreated)</i><br/><br/>
            "
        }
    } elseif ($Status -eq "disabled") {
        
        if ($Type -eq "Slack") {
            $slackMessage = 
            "*Name:* $($Employee.fullname) - $($Employee.title)
            *Department:* $($Employee.department)
            _Disabled: $($empDisabledDate)_`n`n"

            # remove 12 leading spaces to format nicely
            $message = $slackMessage -replace "            ",""
        }

        if ($Type -eq "Email") {
            $message = "<b>Name:</b> $($Employee.fullname) - $($Employee.title)<br/>
            <b>Department:</b> $($Employee.department)<br/>
            <i>Disabled: $($empDisabledDate)</i><br/><br/>
            "
        }
    }          

    Return $message
}


Function Get-AccountDisabledDate {
    <#
        .Synopsis
            Obtains the employees AD account disabled date by querying the domain for the userAccountControl attribute, 
            selects LastOriginatingChangeTime and returns the value

        .Parameter Employee
            This is the current employee record that's found from searchQuery

        .Example
            Get-AccountDisabledDate -Employee $employeeRecord
    #>
    param (
        [Parameter(Mandatory = $true)]
		[PSObject[]]$Employee
    )

    $pdc = Get-ADForest | Select-Object -ExpandProperty RootDomain | 
           Get-ADDomain | Select-Object -Property PDCEmulator
    
    $employeeAccountModified = Get-ADuser $Employee.SamAccountName |
                               Get-ADReplicationAttributeMetadata -server $pdc.PDCEmulator |
                               Where-Object {$_.AttributeName -eq "userAccountControl"} |
                               Select-Object LastOriginatingChangeTime

    Return $employeeAccountModified.LastOriginatingChangeTime
}


Function Get-TerminatedAccounts {
    <#
        .Synopsis
            Obtains all active directory accounts (e.g. employees) who are disabled based on the 
            UAC LastOriginatingChangeTime and $potentiallyTerminatedEmployees

        .Parameter Employee
            This is the employee or employees you want to know if have been terminated/disabled or not
        
        .Parameter Days
            Number of days prior to today to check for terminated employees

        .Example
            Get-TerminatedAccounts -Employee $potentiallyTerminatedEmployees
    #>
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$pdEmployee,
        
        [Parameter(Mandatory = $true)]
		[int]$Days
    )

    $disabledEmployee = @()
    $pdc = Get-ADForest | Select-Object -ExpandProperty RootDomain | 
           Get-ADDomain | Select-Object -Property PDCEmulator

    foreach ($emp in $pdEmployee) {
        $disabledDateTime = Get-ADuser $emp.SamAccountName |
                            Get-ADReplicationAttributeMetadata -server $pdc.PDCEmulator |
                            Where-Object {$_.AttributeName -eq "userAccountControl"} |
                            Select-Object LastOriginatingChangeTime
    
        if ($disabledDateTime.LastOriginatingChangeTime -gt (Get-Date).AddDays(-$Days)) {
            $disabledEmployee += $emp
        }
    }

    Return $disabledEmployee
}


Function Get-ADAttribute {
    <#
        .Synopsis
            Obtains attributes from Active Directory for a current employee...gracefully

        .Parameter Employee
            This is the employee or employees you want to know if have been terminated/disabled or not

        .Example
            Get-ADAttribute -Employee $potentiallyTerminatedEmployees
    #>
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Emp,

        [Parameter(Mandatory = $true)]
		[string]$Attribute
    )

    # Error handling for Manager and telePhoneNumber
    # This is needed because I am Splitting on these objects and if there is no value it will error
    try {
        if ($Attribute -eq 'Manager') {
            try {
                $result = (($Emp.$Attribute).Split('CN=')[3]).Split(',')[0]
            } catch {
                $result = "_[No Manager Assigned]_"
            }

        } elseif ($Attribute -eq 'telephoneNumber') {
            try {
                    $result = "x" + ($Emp.$Attribute).Split('x')[1]
            } catch {
                    $result = "_[No Extension Assigned]_"
            }   
        } elseif ($NULL -eq $Emp.$Attribute) {
            $result = "_[No Value Assigned]_"
        } else {
            $result = $Emp.$Attribute
        }
    } catch {
        $result = "Error!" + $_.Exception.Message   
        LogWrite $result   
    } 
    
    Return $result

}

Function Get-EmployeeRecords {
    <#
        .Synopsis
            This is the main function of this script that calls all the above functions. This function sets 
            slack variables, queries Active Directory, creates and sends the description and notification messages, 
            sends a delayed new employee welcome email, and cleans up the log files.

        .Parameter Status
            This is the employee's employment status, which is found from searchQuery and can be 
            either hired or terminated

        .Parameter Days
            This is the number of days prior to today you want to check for new employees

        .Parameter Email
            Set Email to $false if you do not want to send an email notification

        .Example
            Get-EmployeeRecords -Status hired -Days 1 -Email $true -ErrorAction SilentlyContinue 2>&1 | Out-Null
        
        .Example
            Get-EmployeeRecords -Status terminated -Days 1 -Email $true -ErrorAction SilentlyContinue  2>&1 | Out-Null
    #>
	param (
		[Parameter(Mandatory = $true)]
		[string]$Status,

		[Parameter(Mandatory = $true)]
		[int]$Days,

        [Parameter(Mandatory = $false)]
		[bool]$Email
	)

    begin {

        ### Slack Channel where notifications will be sent
        $channel = "ChannelID" 

        ### DON'T EDIT ###
        $searchQuery = $NULL
        $employee = @()
        $employeeRecord = @()
        $slackAlertMessage = @()
        $emailAlertMessage = @()
        $payload = $NULL
        $p = $NULL
    }

    process {

        if ($Status -eq "hired") {
            $userName = "New Employee Alert"
            $iconEmoji = ":new:"

            # Note: In newer versions of PowerShell you can put this variable declaration on multiple lines which may make it easier to read. Representing it here on 1 line for compatability
            # If using PowerShell 4.0 or older it needs to be on 1 line
            $searchQuery = Get-ADUser -Filter * -Properties * -SearchBase "ou=yourOU,ou=yourDOMAIN,dc=yourDOMAIN,dc=com" | Where-Object {$_.whenCreated -gt (Get-Date).AddDays(-$Days)}
            $searchStatus = "created"
            $searchCount = ($searchQuery | Measure-Object).Count

            $slackAlertDescription = AlertDescription -Status $searchStatus -SearchCount $searchCount -Type Slack
            $emailAlertDescription = AlertDescription -Status $searchStatus -SearchCount $searchCount -Type Email
        }

        if ($Status -eq "terminated") {
            $userName = "Terminated Employee Alert"
            $iconEmoji = ":no_pedestrians:"

            # Note: In newer versions of PowerShell you can put this variable declaration on multiple lines which may make it easier to read. Representing it here on 1 line for compatability
            # If using PowerShell 4.0 or older it needs to be on 1 line
            $potentiallyTerminatedEmployees = Get-ADUser -Filter {(Enabled -eq $False)} -Properties * -SearchBase "ou=yourOU,ou=yourDOMAIN,dc=yourDOMAIN,dc=com" | Where-Object {$_.whenChanged -gt (Get-Date).AddDays(-$Days)}
            $searchQuery = Get-TerminatedAccounts -pdEmployee $potentiallyTerminatedEmployees -Days $Days
            $searchStatus = "disabled"
            $searchCount = ($searchQuery | Measure-Object).Count

            $slackAlertDescription = AlertDescription -Status $searchStatus -SearchCount $searchCount -Type Slack
            $emailAlertDescription = AlertDescription -Status $searchStatus -SearchCount $searchCount -Type Email
        }

        if ($NULL -ne $searchQuery) {
            
            # Create New Employee Alert/Terminated Employee Alert section in log file
            $date = Get-Date -UFormat "%D %R"
            LogWrite "###########################################################`n#################### $date #######################`n"
            LogWrite "** $userName **`n"

            Foreach ($employee in $searchQuery){

                try {
                    $employeeRecord = [PSCustomObject]@{
                        fullname          = Get-ADAttribute -Emp $employee -Attribute Name
                        title             = Get-ADAttribute -Emp $employee -Attribute Title
                        department        = Get-ADAttribute -Emp $employee -Attribute Department
                        manager           = Get-ADAttribute -Emp $employee -Attribute Manager
                        email             = Get-ADAttribute -Emp $employee -Attribute mail
                        extension         = Get-ADAttribute -Emp $employee -Attribute telephoneNumber
                        SamAccountName    = Get-ADAttribute -Emp $employee -Attribute SamAccountName
                        modified          = Get-ADAttribute -Emp $employee -Attribute whenChanged
                        created           = Get-ADAttribute -Emp $employee -Attribute whenCreated
                        startdate         = Get-ADAttribute -Emp $employee -Attribute info
                    }
                } catch {
                    $errorMessage = $_.Exception.Message
                    LogWrite "Error getting Employee Active Directory Attributes!`n$errorMessage"
                }                

                if ($Status -eq "hired") {
                    $searchStatus = "created"

                    # Record new employee name and AD account creation date to log file
                    LogWrite " - Name: $($employeeRecord.fullname)`n   Created: $($employeeRecord.created)`n"

                    $slackAlertMessage = AlertMessage -Status $searchStatus -Type Slack -Employee $employeeRecord
                    $emailAlertMessage = AlertMessage -Status $searchStatus -Type Email -Employee $employeeRecord
                }

                if ($Status -eq "terminated") {
                    $searchStatus = "disabled"

                    # Record terminated employee name and AD account disabled date to log file
                    LogWrite " - Name: $($employeeRecord.fullname)`n   Disabled: $(Get-AccountDisabledDate -Employee $employeeRecord)`n"

                    $slackAlertMessage = AlertMessage -Status $searchStatus -Type Slack -Employee $employeeRecord
                    $emailAlertMessage = AlertMessage -Status $searchStatus -Type Email -Employee $employeeRecord
                }
                
                $formattedSlackMessage += $slackAlertMessage
                $formattedEmailMessage += $emailAlertMessage
            }

            try {
                $p = [ORDERED]@{
                    username = $userName
                  icon_emoji = $iconEmoji
                     channel = $channel
                        text = $slackAlertDescription
                      blocks = @(
                          @{
                              type = "section"
                              text = @{
                                  type = "mrkdwn"
                                  text = $slackAlertDescription
                              }
                          }
                          @{
                              type = "section"
                              text = @{
                                  type = "mrkdwn"
                                  text = $formattedSlackMessage
                              }
                          }
                          <# Uncomment this code to send notifications with a photo of new employees
                          @{
                              type = "image"
                              title = @{
                                  type = "plain_text"
                                  text = "Example Image"
                              }
                              image_url = "https://urltoyourimage.com"
                              alt_text = "Example Image"
                          }
                          #>
                          @{
                              type = "divider"
                          }
                      )
                }
            } catch {
                $errorMsg = "!!!! An error has occurred with the payload: Exception - $($_.Exception.Message)`n"
                LogWrite $errorMsg
                Send-MailMessage `
                -To 'you@youremail.com' `
                -From 'alerts@youremail.com' `
                -Subject "Error occured in the Employee Alerts script: Slack Payload" `
                -Body $errorMsg `
                -SmtpServer mail.yourdomain.com
                break;
            }
            
            # Make sure to get the -Depth correct or it could cause issues
            # Such as adding strange 'null' values
            $payload = $p | ConvertTo-Json -Depth 3

            $params = @{
                Uri         = 'https://slack.com/api/chat.postMessage'
                Headers     = @{ 'Authorization' = "Bearer $token" }
                Method      = 'POST'
                Body        = $payload
                ContentType = 'application/json'
            }
            
            # Send the slack notification
            try {
                Invoke-RestMethod @params
                LogWrite "   Slack notification sent sucessfully.`n"
            } catch {
                if ($_.Exception.Message) {
                    $errorMsg = "!!!! An error has occurred with Invoke-RestMethod: Exception - $($_.Exception.Message)`n"
                    LogWrite $errorMsg
                    Send-MailMessage `
                    -To 'you@youremail.com' `
                    -From 'alerts@youremail.com' `
                    -Subject "Error occured in the Employee Alerts script: Slack Notification" `
                    -Body $errorMsg `
                    -SmtpServer mail.yourdomain.com
                    break;
                }
            }
            
            # Send the email notification
            if ($Email -eq $true){
                Send-MailMessage `
                -To 'you@youremail.com' `
                -From 'alerts@youremail.com' `
                -Subject "Newly $searchStatus Accounts Found in the last $Days days" `
                -BodyAsHtml "$emailAlertDescription<br/><br/>$formattedEmailMessage" `
                -SmtpServer mail.yourdomain.com
                LogWrite "   Email notification sent sucessfully.`n"
            }

        # Schedule a new employee welcome email
            # Developed but not yet tested or implemented
            # Planning to implement in the future
            # ScheduleWelcomeEmail -From "alerts@youremail.com" -To "you@youremail.com" -Subject "another test?" -Body "this is a test" -SendDate "9/20/19 15:50"
        
        } else {
            # Used for debug
            # LogWrite "No $Status employees found."
        }
    }

    end {    
        # Archive & delete log files older than 30 days
        try {
            # Not working very good yet
            # CompressLogs -Days 30
        } catch {
            if ($_.Exception.Message) {
                $errorMsg = "!!!! An error has occurred with CompressLogs: Exception - $($_.Exception.Message)`n"
                LogWrite $errorMsg
                Send-MailMessage `
                -To 'you@youremail.com' `
                -From 'alerts@youremail.com' `
                -Subject "Error occured in the Employee Alerts script: CompressLogs" `
                -Body $errorMsg `
                -SmtpServer mail.yourdomain.com
                break;
            }
        }
    }

}

# Use CreateTokenFile.ps1 to create a secure email token file

# Reading the token from the secure file
# This will fail if the user who runs the script IS NOT the same as the user who created the secure token file
try {
    $authToken = Get-Content "c:\scripts\EmployeeAlerts\token.txt" | ConvertTo-SecureString -ErrorAction Stop
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($authToken)            
    $token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
} catch {
    $errorMsg = "!!!! An error has occurred when importing the token: Exception - $($_.Exception.Message)`n"
    LogWrite $errorMsg
    Send-MailMessage `
    -To 'you@youremail.com' `
    -From 'alerts@youremail.com' `
    -Subject "Error occured in the Employee Alerts script: Token Import" `
    -Body $errorMsg `
    -SmtpServer mail.yourdomain.com
    break;
}

# Slack alerts are default. Set -Email $true to send email alert as well
Get-EmployeeRecords -Status hired -Days 1 -Email $false -ErrorAction SilentlyContinue 2>&1 | Out-Null
Get-EmployeeRecords -Status terminated -Days 1 -Email $false -ErrorAction SilentlyContinue  2>&1 | Out-Null