Write-Host "Starting AI Logistics Control Tower..." -ForegroundColor Cyan
$env:PYTHONPATH = "e:\Sugar Spot\Planning tool\backend"
& "C:\Users\NC26467-HARSH\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe" -m uvicorn app.main:app --app-dir "e:\Sugar Spot\Planning tool\backend" --host 0.0.0.0 --port 8000
