$Proxy = $True

$UserMail = "moktarino@gmail.com"
$UserPass = "hunter2"
$SpaceTemplateID = "610347610863042764"
$PrimaryDisplayUrl = " https://drive.google.com/file/d/1yPT-e22cf0FlUlOFx0mTp5l8hH_wSoil/view"
$EventType = "private"

$ProxyAddress = "http://127.0.0.1:8888"
$StartTime = Get-Date "08/11/2018 23:30:00"
$EndTime = Get-Date "08/12/2018 23:30:00"

$Random = Get-Random -Minimum 100 -Maximum 300
$EventTitle = "EventTitle---$Random"
$EventDesc = "EventDesc---$Random"

$LoginUrl = "https://account.altvr.com/users/sign_in"
$EventsUrl = 'https://account.altvr.com/events'
$NewEventUrl = 'https://account.altvr.com/events'
$WebFormBoundary = '----WebKitFormBoundaryL9Ti2e9QJY9rguEW'
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

$PostData = [ordered]@{
    "utf8" = $utf8
    "authenticity_token" = $AuthToken
    "event[created_by_user_id]" = $UserID
    "event[name]" = $EventTitle
    "event[description]" = $EventDesc
    "event[start_time]" = $EventStartTime
    "event[end_time]" = $EventEndTime
    "event[event_type]" = $EventType
    "event[channel_id]" = ''
    "img:event[image]" = ''
    "event[remove_image]" = 0
    "event[use_image_for_banner_image]" = 0
    "img:event[banner_image]" = ''
    "event[remove_banner_image]" = 0
    "event[youtube_video_id]" = ''
    "event[twitter_tags]" = ''
    "event[default_primary_enclosure_url]" = ''
    "event[use_tile_image_for_primary_display]" = 0
    "event[admin_lock_all]" = 0
    }

$PostData2 = [ordered]@{
    "event[admin_lock_all]" = 1
    "event[role_list]" = ''
    "event[group_id]" = ''
    "event[tagline]" = ''
    "event[domains]" = ''
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

$Headers = @{
    'Accept' = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8"
    'Accept-Encoding' = "gzip, deflate, br"
    'Accept-Language' = "en-US,en;q=0.9"
    'Origin' = "https://account.altvr.com"
    'Referer' = "https://account.altvr.com/events/new"
    'Upgrade-Insecure-Requests' = 1
    'DNT' = 1
    'Cache-Control' = 'max-age=0'
    'Connection' = 'keep-alive'
    'User-Agent' = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.99 Safari/537.36'
    }

if ($Proxy) {
    $EventCreateResponse = Invoke-WebRequest -Headers $Headers -Uri $NewEventUrl -Method Post -Body $multipartContent -Proxy $ProxyAddress -SkipCertificateCheck -WebSession $Session
    } 
else {
    $EventCreateResponse = Invoke-WebRequest -Headers $Headers -Uri $NewEventUrl -Method Post -Body $multipartContent -WebSession $Session
    }
$EventCreateResponse