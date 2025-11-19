@echo off
cd /d "%~dp0backend"
echo Starting Backend Server...
node src/server.js
pause
