@echo off
chcp 65001 >nul
cd /d "%~dp0.."
echo Starting Heat Firm...
"C:\Users\caleb\OneDrive\Desktop\Godot_v4.7-stable_win64.exe" --path "%cd%"
pause
