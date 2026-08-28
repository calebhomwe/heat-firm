@echo off
chcp 65001 >nul
cd /d "%~dp0.."
echo Starting Heat Firm...
"%~dp0..\..\tools\godot\godot.exe" --path "%cd%"
pause
