try {
    if (Get-Command python -ErrorAction SilentlyContinue) {
        Write-Output "Starting Python server on http://localhost:8000"
        python -m http.server 8000
    } elseif (Get-Command py -ErrorAction SilentlyContinue) {
        Write-Output "Starting Python (py) server on http://localhost:8000"
        py -3 -m http.server 8000
    } else {
        Write-Output "Python not found. Attempting npx http-server..."
        npx http-server -c-1 . -p 8000
    }
} catch {
    Write-Error "Failed to start server: $_"
}
