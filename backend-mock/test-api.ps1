# Test script for Play Extra Battle Mock API

Write-Host "Testing Play Extra Battle Mock API..." -ForegroundColor Green

# Test health endpoint
Write-Host "`n1. Testing Health Endpoint:" -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "http://localhost:4000/api/health" -Method Get
    Write-Host "✅ Health check passed" -ForegroundColor Green
    Write-Host "   Message: $($health.message)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Health check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test rooms endpoint
Write-Host "`n2. Testing Rooms Endpoint:" -ForegroundColor Yellow
try {
    $rooms = Invoke-RestMethod -Uri "http://localhost:4000/api/rooms" -Method Get
    Write-Host "✅ Rooms endpoint working" -ForegroundColor Green
    Write-Host "   Available rooms: $($rooms.rooms.Count)" -ForegroundColor Cyan
    foreach ($room in $rooms.rooms) {
        Write-Host "   - $($room.roomId): $($room.name) (${$room.minStake}-${$room.maxStake})" -ForegroundColor White
    }
} catch {
    Write-Host "❌ Rooms test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test creating a round
Write-Host "`n3. Testing Round Creation:" -ForegroundColor Yellow
try {
    $roundData = @{
        roomId = "10-100"
        deadline = [int64]((Get-Date).AddMinutes(5).ToUniversalTime() - (Get-Date "1970-01-01")).TotalMilliseconds
        minStake = 10
        maxStake = 100
    } | ConvertTo-Json

    $round = Invoke-RestMethod -Uri "http://localhost:4000/api/rounds" -Method Post -Body $roundData -ContentType "application/json"
    Write-Host "✅ Round created successfully" -ForegroundColor Green
    Write-Host "   Round ID: $($round.round.id)" -ForegroundColor Cyan
    Write-Host "   Room: $($round.round.roomId)" -ForegroundColor Cyan
    
    $global:testRoundId = $round.round.id
} catch {
    Write-Host "❌ Round creation failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🎉 API Test Complete!" -ForegroundColor Green
Write-Host "Mock backend is ready for Play Extra integration." -ForegroundColor White
