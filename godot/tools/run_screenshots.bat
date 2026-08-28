@echo off
chcp 65001 >nul
cd /d "%~dp0.."
echo Capturing screenshots (window opens briefly)...
"%~dp0..\..\tools\godot\godot.exe" --path "%cd%" --script "res://tools/qa/screenshot_matrix.gd"
echo Exit code: %ERRORLEVEL%
pause
