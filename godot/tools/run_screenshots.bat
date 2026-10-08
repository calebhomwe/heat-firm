@echo off
chcp 65001 >nul
cd /d "%~dp0.."
echo Capturing screenshots (window opens briefly)...
"C:\Users\caleb\OneDrive\Desktop\Godot_v4.7-stable_win64.exe" --path "%cd%" --script "res://tools/qa/screenshot_matrix.gd"
echo Exit code: %ERRORLEVEL%
pause
