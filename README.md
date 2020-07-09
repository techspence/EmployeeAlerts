# EmployeeAlerts
A series of scripts used to monitor employee Active Directory accounts and send alerts about important events or information.

**HiredTerminatedAlerts.ps1** - A PowerShell script that searches Active Directory for newly created and newly disabled user accounts (e.g. new employees/terminated employees) then sends a slack/email notification.

## Installation

### Create a Slack App

1. If you are not already signed in, sign into Slack here https://slack.com/signin
2. Navigate to https://api.slack.com/
3. Click **Start Building**
4. Enter an **App Name** and select your **Slack Workspace**
5. Click **Create App**

### Customize
1. Click Basic Information
2. Scroll to the bottom section called **Display Information**
3. Give your app a name and a short description
4. You may also change the background color of the App Preview as well as include your own App Icon
5. Click **Save Changes**

### Collaborators
1. Click Collaborators
2. Start typing a collaborators name, then click on their name
3. Add anyone you think might need to administer or manage the app

### Create a Bot & Bot User
1. Click **Basic Information** > **Add features and functionality** > **Bots**
2. Click **Add a Bot User**
3. The defaults are typically fine here, but if you wish, change the Display name and Default username
4. Enable **Always Show My Bot as Online**
5. Click **Add Bot User**

### Permissions & Scope
1. Click **OAuth & Permissions**
2. Scroll down to the **Scopes** section
3. If not already there add the following **Bot Token Scopes**:
    - chat:write - Send messages as your bot
    - chat:write:customize - Send messages as your bot with a customized username and avatar
    - users:write - Set presence for your bot

### Restrict API Token Usage
1. Click **Basic Information** > **Add features and functionality** > **Permissions**
2. Click **Add a new IP address range**
3. Enter your public IP then click **Add**
4. Click **Save IP address ranges**

### Install App to Workspace
1. Click **Basic Information** > **Add features and functionality** > **Permissions**
2. Click **Install App to Workspace**
3. A dialog is shown that describes what the App will be able to view and what the Bot User will be able to do
4. Review this page and if OK, click **Allow**
5. You now see that an *OAuth Access Token* and a **Bot User OAuth Access Token** (this is what we will use for our script) has been generated

### Clone Repo and Create Secure Token File
1. Clone this repository or download the files and place them in your scripts folder
2. Launch powershell as the user that will run this script
4. Naviage to the folder you placed the script into
4. Create a secure token file by running `.\CreateTokenFile.ps1`
5. Copy and paste your **Bot User OAuth Access Token** which was obtained from step 5 in the previous section
    - Your token is now saved in a secure file called `token.txt`
    - *Note: OAuth Access tokens are secrets and should be treated as such*

### Secure the Token File
1. After creating the secure token file right click on `token.txt` and click Properties
2. Click the **Security** -> **Advanced**
3. Click **Disable inheritance**
4. Click **Convert inherited permissions into explicit permissions on this object**
5. Remove all Principals except: System, Administrators and the account the script is run as
6. Click **OK**

### Add Log on as a Batch
1. Press **Ctrl + r** to get a run box
2. Enter **secpol.msc** then press Enter
3. Navigate to **Local Policies** -> **User Rights Assignment**
4. Find the policy **Log on as a batch job** and double click to open
5. Click **Add User or Group...**
6. Add the user who will be running this script, then click **OK**

### Add Slack Channel ID
1. Edit `HiredTerminatedAlerts.ps1`
2. Search for `$channel` and change the value to `YourChannelID`
    - _Note: This is the channel ID for the `alerts` channel_

**If you do not know the slack channel ID or if you want to change channels**
1. Login to your slack instance via a browser using https://yourworkspacename.slack.com
2. Click on your desired channel
3. The series of numbers and letters at the end of the URL after the `/` is the channel ID

## Secure File Note
- In order to run this script as a task you must first create a secure token file using the same account that's going to run the script.
    
    - To create a secure token file, use `CreateTokenFile.ps1`
    
    - This means you can’t just copy the ‘secure token file’ to other machines and reuse it, nor access it from an account that did not create the secure file.
    
    - Also, in order for DAPI (& this script) to work, the GPO setting Network Access: Do not allow storage of passwords and credentials for network authentication 
        must be set to Disabled (or not configured).  Otherwise the encryption key will only last for the lifetime of the user session (i.e. upon user logoff or a 
        machine reboot, the key is lost and it cannot decrypt the secure string text)


## Planned Features
- **Alert When Specific Employee Information is Missing**
This script would look for specific employee information in Active Directory and sends an alert when said information has been found.

- **Schedule a Welcome Email to All Employees**
I have code pre-built that can be used to schedule an email to be sent once a new employee is found. It has not been tested yet.