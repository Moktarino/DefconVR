# This script creates AltspaceVR events.

#Ex: ./Altspace.ps1 -usermail "moktarino@gmail.com" -userpass "hunter2" -EventTitle "An event made from the CLI!" -EventDesc "An event made from the CLI!" -EnclosureUrl "https://altspacevr.github.io/AltspaceSDK/examples/aframe/basic.html"

param (
    [string]$UserMail,
    [string]$UserPass = $( Read-Host "Input password, please"),
    [string]$SpaceTemplateID = "498711918106641253",
    [string]$EventTitle,
    [string]$EventDesc,
    [string]$EventType = "private",
    [DateTime]$StartTime = ((Get-Date).addMinutes(-1)),
    [DateTime]$EndTime = ((Get-Date).AddMinutes((60))),
    [string]$TwitterTags,
    [string]$YoutubeID,
    [string]$ChannelID,
    [string]$Domains,
    [string]$ProxyAddress = $Null,
    [string]$ImageFile,
    [string]$BannerImage,
    [string]$EnclosureUrl,
    [switch]$UseImageForBannerImage,
    [switch]$UseTileImageForPrimaryDisplay,
    [string]$RoleList,
    [string]$TagLine,
    [string]$GroupID
    )

    $DebugPreference = "Continue"
If ($ProxyAddress) {$Proxy = $True} else {$Proxy = $False}
$Session = $Null
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
Write-Debug "Login Auth Token: $AuthToken"
$Body = @{
    utf8 = $utf8
    authenticity_token = $AuthToken
    'user[tz_offset]' = $UserTZOffset
    'user[email]' = $UserMail
    'user[password]' = $UserPass
    'user[remember_me]' = 1;
    }

Write-Debug ($Body | Out-String)
if ($Proxy) {
    Invoke-WebRequest -Uri $LoginUrl -Method Post -Body $Body -WebSession $Session -Proxy $ProxyAddress -SkipCertificateCheck | Out-Null
    $UserIDResponse = Invoke-WebRequest -Uri $EventsUrl -WebSession $Session -Proxy $ProxyAddress -SkipCertificateCheck
    }
else {
    $LoginResponse = Invoke-WebRequest -Uri $LoginUrl -Method Post -Body $Body -WebSession $Session | Out-Null
    $UserIDResponse = Invoke-WebRequest -Uri $EventsUrl -WebSession $Session
    }

$UserID = $UserIDResponse.Links | Where-Object {$_.href -match 'user_profile'} | % { $_.href.split('/')[2]}
Write-Debug "UserID: $UserID"
If (!$UserID) {
    Throw "Failed to login: $($LoginResponse | Out-string)"
    Break
}
$EventStartTime = Get-Date $StartTime -Format "yyyy-MM-dd hh:mm tt -0700"
$EventEndTime = Get-Date $EndTime -Format "yyyy-MM-dd hh:mm tt -0700"


if ($Proxy) {
    $AuthTokenResponse2 = Invoke-WebRequest -Uri $NewEventUrl -WebSession $Session -Proxy $ProxyAddress -SkipCertificateCheck
}
else {
    $AuthTokenResponse2 = Invoke-WebRequest -Uri $NewEventUrl -WebSession $Session
}

$AuthToken2 = $AuthTokenResponse2.InputFields | Where-Object {$_.name -eq 'authenticity_token' } | Select-Object -ExpandProperty value

Write-Debug "Event Create Auth Token: $AuthToken2"

If ($UseImageForBannerImage) {[int]$UseImageForBannerImage = 1} else {[int]$UseImageForBannerImage = 0}
if ($UseTileImageForPrimaryDisplay) {[int]$UseTileImageForPrimaryDisplay = 1} else {[int]$UseTileImageForPrimaryDisplay = 0}

$PostData = [ordered]@{
    "utf8" = $utf8
    "authenticity_token" = $AuthToken2
    "event[created_by_user_id]" = $UserID
    "event[name]" = $EventTitle
    "event[description]" = $EventDesc
    "event[start_time]" = $EventStartTime
    "event[end_time]" = $EventEndTime
    "event[event_type]" = $EventType
    "event[channel_id]" = $ChannelID
    #"img:event[image]" = ''
    "event[remove_image]" = 0
    "event[use_image_for_banner_image]" = $UseImageForBannerImage
    #"event[use_image_for_banner_image]" = 0
    #"img:event[banner_image]" = ''
    "event[remove_banner_image]" = 0
    "event[youtube_video_id]" = $YoutubeID
    "event[twitter_tags]" = $TwitterTags
    "event[default_primary_enclosure_url]" = $EnclosureUrl
    "event[use_tile_image_for_primary_display]" = $UseTileImageForPrimaryDisplay
    #"event[use_tile_image_for_primary_display]" = 0
    "event[admin_lock_all]" = 0
    }

$PostData2 = [ordered]@{
    "event[admin_lock_all]" = 1
    "event[role_list]" = $RoleList
    "event[group_id]" = $GroupID
    "event[tagline]" = $TagLine
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
Foreach ($Key in $PostData2.Keys) {
    $Content = $Null
    $Content = New-MultipartFormContent -Name $Key -Value $PostData2[$Key]
    $multipartContent.add($Content)
    }

If ($ImageFile) {
    $FileName = Get-Item $ImageFile | Select-Object -ExpandProperty Name
    $ImageType = $FileName.split(".")[1]
    $FileStream = [System.IO.FileStream]::new($ImageFile, [System.IO.FileMode]::Open)
    $fileHeader = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new("form-data")
    $fileHeader.Name = "event[image]"
    $fileHeader.FileName = $FileName
    $fileContent = [System.Net.Http.StreamContent]::new($FileStream)
    $fileContent.Headers.ContentDisposition = $fileHeader
    $fileContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("image/$ImageType")
    $multipartContent.Add($fileContent)
    }
Else {
    $Content = $Null
    $Content = New-MultipartFormContent -Name "event[image]" -Value ""
    $multipartContent.add($Content)
}
If ($BannerImage) {
    $FileName = Get-Item $BannerImage | Select-Object -ExpandProperty Name
    $ImageType = $FileName.split("\.")[1]
    $FileStream = [System.IO.FileStream]::new($BannerImage, [System.IO.FileMode]::Open)
    $fileHeader = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new("form-data")
    $fileHeader.Name = "event[banner_image]"
    $fileHeader.FileName = $FileName
    $fileContent = [System.Net.Http.StreamContent]::new($FileStream)
    $fileContent.Headers.ContentDisposition = $fileHeader
    $fileContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("image/$ImageType")
    $multipartContent.Add($fileContent)
}
else {
    $Content = $Null
    $Content = New-MultipartFormContent -Name "event[banner_image]" -Value ""
    $multipartContent.add($Content)
}


$Headers = @{
    'Accept' = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8"
    'Accept-Encoding' = "gzip, deflate, br"
    'Accept-Language' = "en-US,en;q=0.9"
    'Cache-Control' = 'max-age=0'
    'Connection' = 'keep-alive'
    }

$EventCreateResponse = $Null
if ($Proxy) {
    $EventCreateResponse = Invoke-WebRequest -Headers $Headers -Uri $EventsUrl -Method Post -Body $multipartContent -Proxy $ProxyAddress -SkipCertificateCheck -WebSession $Session
    }
else {
    $EventCreateResponse = Invoke-WebRequest -Headers $Headers -Uri $EventsUrl -Method Post -Body $multipartContent -WebSession $Session
    }

$EventID = $EventCreateResponse.Links | Where-Object {$_.href -match "calendar"} | % { $_.href.split("/")[2]}
If (!$EventID) {
    Throw "Failed to create event: $($EventCreateResponse.rawcontent | more)"
    Break
}
Write-Host "https://account.altvr.com/events/$EventID"
