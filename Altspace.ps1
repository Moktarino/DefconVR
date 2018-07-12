# This script creates AltspaceVR events.


#Example: ./Altspace.ps1 -UserMail "Moktarino@gmail.com" -EventTitle "An Automated Event!" -EventDesc "This event was created by CLI!"


param (
    [string]$UserMail,
    [string]$UserPass = $( Read-Host "Input password, please"),
    [string]$SpaceTemplateID = "610347610863042764",
    [string]$EventTitle,
    [string]$EventDesc,
    [string]$StartTime = ((Get-Date).addMinutes(15)),
    [string]$EndTime = ((Get-Date).AddMinutes((75))),
    [string]$EventType = "private",
    [string]$TwitterTags,
    [string]$YoutubeID,
    [string]$ChannelID,
    [string]$Domains,
    [string]$ProxyAddress
    )

If ($ProxyAddress) {
    $Proxy = $True
    }


$LoginUrl = "https://account.altvr.com/users/sign_in"
$EventsUrl = 'https://account.altvr.com/events'
$NewEventUrl = 'https://account.altvr.com/events/new'
$WebFormBoundary = "---WebKitFormBoundary$(Get-Random -Minimum 0 -Maximum 10000)"
$UserTZOffset = 420
$utf8 = '✓'

Function New-MultipartFormContent ([string]$Name, [string]$Value){
    $StringHeader = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new("form-data")
    $KeyName = $Name
    if ($Name -match "img:") {
        $KeyName = $Name.split(":")[1]
        $stringHeader.Name = "`"$KeyName`""
        $StringHeader.FileName = '""'
        }
    $StringHeader.Name = "`"$KeyName`""
    $StringContent = [System.Net.Http.StringContent]::new($Value)
    if ($Name -match "img:") {
        $StringContent.Headers.ContentType = 'application/octet-stream'
        }
    else {
        $StringContent.Headers.ContentType = $Null
        }
    $StringContent.Headers.ContentDisposition = $stringHeader
    Return $stringContent
}

if ($Proxy) {
    $AuthTokenResponse = Invoke-WebRequest -Uri $LoginUrl -SessionVariable Session -Proxy $ProxyAddress -SkipCertificateCheck
    } 
else {
    $AuthTokenResponse = Invoke-WebRequest -Uri $LoginUrl -SessionVariable Session
    }


$AuthToken = $AuthTokenResponse.InputFields | Where-Object {$_.name -eq 'authenticity_token' } | Select-Object -ExpandProperty value

$Body = @{
    utf8 = $utf8
    authenticity_token = $AuthToken
    'user[tz_offset]' = $UserTZOffset
    'user[email]' = $UserMail
    'user[password]' = $UserPass
    'user[remember_me]' = 1;
    }
if ($Proxy) {
    Invoke-WebRequest -Uri $LoginUrl -Method Post -Body $Body -WebSession $Session -Proxy $ProxyAddress -SkipCertificateCheck | Out-Null
    $UserIDResponse = Invoke-WebRequest -Uri $EventsUrl -WebSession $Session -Proxy $ProxyAddress -SkipCertificateCheck
    }
else {
    Invoke-WebRequest -Uri $LoginUrl -Method Post -Body $Body -WebSession $Session | Out-Null
    $UserIDResponse = Invoke-WebRequest -Uri $EventsUrl -WebSession $Session
    }

$UserID = $UserIDResponse.Links | Where-Object {$_.href -match 'user_profile'} | % { $_.href.split('/')[2]}
$EventStartTime = Get-Date $StartTime -Format "yyyy-MM-dd hh:mm tt -0700"
$EventEndTime = Get-Date $EndTime -Format "yyyy-MM-dd hh:mm tt -0700"

$AuthTokenResponse2 = Invoke-WebRequest -Uri $NewEventUrl -WebSession $Session
$AuthToken = $AuthTokenResponse2.InputFields | Where-Object {$_.name -eq 'authenticity_token' } | Select-Object -ExpandProperty value

$PostData = [ordered]@{
    "utf8" = $utf8
    "authenticity_token" = $AuthToken
    "event[created_by_user_id]" = $UserID
    "event[name]" = $EventTitle
    "event[description]" = $EventDesc
    "event[start_time]" = $EventStartTime
    "event[end_time]" = $EventEndTime
    "event[event_type]" = $EventType
    "event[channel_id]" = $ChannelID
    "img:event[image]" = ''
    "event[remove_image]" = 0
    "event[use_image_for_banner_image]" = 0
    "img:event[banner_image]" = ''
    "event[remove_banner_image]" = 0
    "event[youtube_video_id]" = $YoutubeID
    "event[twitter_tags]" = $TwitterTags
    "event[default_primary_enclosure_url]" = ''
    "event[use_tile_image_for_primary_display]" = 0
    "event[admin_lock_all]" = 1
    "event[role_list]" = ''
    "event[group_id]" = ''
    "event[tagline]" = ''
    "event[domains]" = $Domains
    "commit" = 'Create Event'
    "event[default_primary_display_url]" = $PrimaryDisplayUrl
    "event[space_template_id]" = $SpaceTemplateID
    }

$multipartContent = [System.Net.Http.MultipartFormDataContent]::new($WebFormBoundary)

Foreach ($Key in $PostData.Keys) {
    $Content = $Null
    $Content = New-MultipartFormContent -Name $Key -Value $PostData[$Key]
    $multipartContent.add($Content)
    }


$Headers = @{
    'Accept' = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8"
    'Accept-Encoding' = "gzip, deflate, br"
    'Accept-Language' = "en-US,en;q=0.9"
    }

$EventCreateResponse = $Null
if ($Proxy) {
    $EventCreateResponse = Invoke-WebRequest -Headers $Headers -Uri $EventsUrl -Method Post -Body $multipartContent -Proxy $ProxyAddress -SkipCertificateCheck -WebSession $Session
    } 
else {
    $EventCreateResponse = Invoke-WebRequest -Headers $Headers -Uri $EventsUrl -Method Post -Body $multipartContent -WebSession $Session
    }

$EventID = $EventCreateResponse.Links | Where-Object {$_.href -match "calendar"} | % { $_.href.split("/")[2]}

Write-Host "https://account.altvr.com/events/$EventID"
