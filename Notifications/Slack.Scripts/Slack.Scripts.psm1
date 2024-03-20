function Send-PSUSlackNotification {
    <#
    .SYNOPSIS
    Send a notification to Slack
    
    .DESCRIPTION
    Send a notification to Slack from triggers in PowerShell Universal.
    
    .PARAMETER Data
    The trigger data. Generated by PowerShell Universal.

    .PARAMETER Job
    The trigger data. Generated by PowerShell Universal.
    #>
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "Data")]
        $Data,
        [Parameter(Mandatory = $true, ParameterSetName = "Job")]
        $Job
    )

    if ($SlackWebhookUrl -eq $null) {
        throw "Please create a variable called `SlackWebhookUrl` with the value of your Slack Webhook URL"
    }

    $Text = ""
    $Header = ""

    if ($Job) {
        if ($Job.Triggered) {
            $Text = "The job was triggered by **$($Job.Trigger)**"
        }
        elseif ($Job.ScheduleId -ne 0) {
            $Text = "The job run on schedule <$ApiUrl/admin/automation/schedules|$($Job.Schedule)>"
        }
        else {
            $Text = "The job was run manually by $($Job.Identity.Name)"
        }

        if ($Job.Environment -ne $Null) {
            $Text += " in the $($Job.Environment) environment"
        }

        if ($Job.Credential -ne $null) {
            $Text += " as $($Job.Credential)"
        }

        if ($Job.ComputerName -ne $null) {
            $Text += " on $($Job.ComputerName)"
        }

        $Header = "[$($Job.Id)] $($Job.ScriptFullPath) $($Job.Status.ToString())"
    }

    if ($Text -eq "") {
        Write-Warning "Unknown trigger type."
        return
    }

    $SlackData = @{
        blocks = @(
            @{
                type = "header"
                text = @{
                    type = "plain_text"
                    text = $Header
                }
            }
            @{
                type      = "section"
                text      = @{
                    type = "mrkdwn"
                    text = $Text
                }
                accessory = @{
                    type      = "button"
                    text      = @{
                        type = "plain_text"
                        text = "View Job"
                    }
                    value     = "viewjob"
                    url       = "$ApiUrl/admin/automation/jobs/$($Job.Id)"
                    action_id = "button-action"
                }
            }
        )
    }

    Invoke-RestMethod -Uri $SlackWebhookUrl -Method Post -Body ($SlackData | ConvertTo-Json -Depth 10) -ContentType "application/json"

}