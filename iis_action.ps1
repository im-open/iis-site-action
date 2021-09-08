Param(
    [parameter(Mandatory = $true)]
    [ValidateSet( 'start', 'stop', 'restart')]
    [string]$action,
    [parameter(Mandatory = $true)]
    [string]$server,
    [parameter(Mandatory = $true)]
    [string]$website_name,
    [parameter(Mandatory = $true)]
    [string]$user_id,
    [parameter(Mandatory = $true)]
    [SecureString]$password,
    [parameter(Mandatory = $true)]
    [string]$cert_path
)

$display_action = 'IIS Website'
$title_verb = (Get-Culture).TextInfo.ToTitleCase($action)

$display_action += " $title_verb"
$past_tense = "ed"
switch ($action) {
    "start" {}
    "restart" { break; }
    "stop" { $past_tense = "ped"; break; }
}
$display_action_past_tense = "$display_action$past_tense"

Write-Output "$display_action\: $website_name"

$credential = [PSCredential]::new($user_id, $password)
$so = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck

Write-Output "Importing remote server cert..."
Import-Certificate -Filepath $cert_path -CertStoreLocation 'Cert:\LocalMachine\Root'

$script = {
    # Relies on WebAdministration Module being installed on the remote server
    # This should be pre-installed on Windows 2012 R2 and later
    # https://docs.microsoft.com/en-us/powershell/module/?term=webadministration

    $website = Get-IISSite -Name $Using:website_name
    if (!$website) {
        Return 1
        Exit
    }

    if ($Using:action -eq 'stop' -or $Using:action -eq 'restart') {
        Stop-IISSite -Name $Using:website_name -Confirm:$false
    }

    if ($Using:action -eq 'start' -or $Using:action -eq 'restart') {
        Start-IISSite -Name $Using:website_name
    }

    Return 0
}

$script_result = Invoke-Command -ComputerName $server `
    -Credential $credential `
    -UseSSL `
    -SessionOption $so `
    -ScriptBlock $script

If ($script_result -and $script_result -eq 1) {
    Write-Output "IIS Site Action Error"
}
else {
    Write-Output "$display_action_past_tense."
}
Exit $script_result