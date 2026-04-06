$ErrorActionPreference = 'Stop'

$baseUrl = 'http://localhost:4000'
$adminEmail = 'admin@example.com'
$adminPassword = 'ChangeMe123!'

function Assert-Ok($name, $condition) {
  if (-not $condition) {
    throw "$name failed"
  }
  Write-Host "$name passed" -ForegroundColor Green
}

function Curl-Json($curlArgs, $bodyText = $null) {
  if ($null -ne $bodyText) {
    $raw = $bodyText | & curl.exe @curlArgs --data-binary '@-'
  } else {
    $raw = & curl.exe @curlArgs
  }
  if (-not $raw) {
    throw 'Empty response from curl'
  }
  return ($raw | Out-String) | ConvertFrom-Json
}

Write-Host '1. Health check'
$health = Curl-Json @('-s', ($baseUrl + '/health'))
Assert-Ok 'Health check' ($health.success -eq $true)

Write-Host '2. Admin bootstrap endpoint'
$bootstrapBody = '{"confirmCreate":true,"name":"System Admin","email":"admin@example.com","password":"ChangeMe123!"}'
$bootstrapRaw = $bootstrapBody | & curl.exe -s -X POST ($baseUrl + '/admin/bootstrap') -H 'Content-Type: application/json' --data-binary '@-'
if ($bootstrapRaw) {
  $bootstrapResponse = $bootstrapRaw | ConvertFrom-Json
  Write-Host "Bootstrap response: $($bootstrapResponse.message)"
}

Write-Host '3. Admin login'
$loginBody = '{"email":"admin@example.com","password":"ChangeMe123!"}'
$login = Curl-Json @('-s', '-X', 'POST', ($baseUrl + '/auth/login'), '-H', 'Content-Type: application/json') $loginBody
Assert-Ok 'Admin login' ($login.success -eq $true -and $login.data.token)
$token = $login.data.token

Write-Host '4. Register user'
$uniqueEmail = "user$(Get-Random)@example.com"
$registerBody = '{"name":"Curl User","email":"' + $uniqueEmail + '","password":"Password123!"}'
$register = Curl-Json @('-s', '-X', 'POST', ($baseUrl + '/auth/register'), '-H', 'Content-Type: application/json') $registerBody
Assert-Ok 'User register' ($register.success -eq $true)

Write-Host '5. Duplicate register fallback'
$duplicate = $registerBody | & curl.exe -s -X POST ($baseUrl + '/auth/register') -H 'Content-Type: application/json' --data-binary '@-'
Assert-Ok 'Duplicate register fallback' ($duplicate -match 'Email already registered')

Write-Host '6. Create transaction'
$txBody = '{"amount":123.45,"type":"income","category":"Salary","date":"' + (Get-Date).ToString('o') + '","notes":"Curl test"}'
$tx = Curl-Json @('-s', '-X', 'POST', ($baseUrl + '/transactions'), '-H', "Authorization: Bearer $token", '-H', 'Content-Type: application/json') $txBody
Assert-Ok 'Create transaction' ($tx.success -eq $true)
$txId = $tx.data.id

Write-Host '7. List transactions'
$listTx = Curl-Json @('-s', ($baseUrl + '/transactions'), '-H', "Authorization: Bearer $token")
Assert-Ok 'List transactions' ($listTx.success -eq $true)

Write-Host '8. Dashboard summary'
$summary = Curl-Json @('-s', ($baseUrl + '/dashboard/summary'), '-H', "Authorization: Bearer $token")
Assert-Ok 'Dashboard summary' ($summary.success -eq $true)

Write-Host '9. Dashboard trends'
$trends = Curl-Json @('-s', ($baseUrl + '/dashboard/trends'), '-H', "Authorization: Bearer $token")
if ($trends.success -ne $true) {
  Write-Host ($trends | ConvertTo-Json -Depth 10)
}
Assert-Ok 'Dashboard trends' ($trends.success -eq $true)

Write-Host '10. Get users as admin'
$users = Curl-Json @('-s', ($baseUrl + '/users'), '-H', "Authorization: Bearer $token")
Assert-Ok 'List users' ($users.success -eq $true)

Write-Host '11. Update own user'
$me = $login.data.user.id
$updateBody = '{"name":"System Admin Updated"}'
$updated = Curl-Json @('-s', '-X', 'PATCH', ($baseUrl + '/users/' + $me), '-H', "Authorization: Bearer $token", '-H', 'Content-Type: application/json') $updateBody
Assert-Ok 'Update user' ($updated.success -eq $true)

Write-Host '12. Soft delete transaction'
$deleted = Curl-Json @('-s', '-X', 'DELETE', ($baseUrl + '/transactions/' + $txId), '-H', "Authorization: Bearer $token")
Assert-Ok 'Delete transaction' ($deleted.success -eq $true)

Write-Host 'All curl checks passed.' -ForegroundColor Cyan
