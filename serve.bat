@echo off
REM Try to start a simple Python HTTP server on port 8000
where python >nul 2>&1
if %ERRORLEVEL%==0 (
  echo Starting Python server on http://localhost:8000
  python -m http.server 8000
  goto :eof
)
where py >nul 2>&1
if %ERRORLEVEL%==0 (
  echo Starting Python server (py) on http://localhost:8000
  py -3 -m http.server 8000
  goto :eof
)
echo Python not found. Trying npx http-server...
npx http-server -c-1 . -p 8000
pause
