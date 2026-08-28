@echo off
chcp 65001 >nul
cd /d "%~dp0.."
"%~dp0..\..\tools\godot\godot.exe" --headless --path "%cd%" -s "res://tests/run_tests.gd"
echo Exit code: %ERRORLEVEL%
pause
