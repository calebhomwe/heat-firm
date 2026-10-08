@echo off
chcp 65001 >nul
cd /d "%~dp0.."
set GODOT=C:\Users\caleb\OneDrive\Desktop\Godot_v4.7-stable_win64.exe
"%GODOT%" --headless --path "%cd%" --script "res://tests/run_tests.gd"
if errorlevel 1 goto :fail
"%GODOT%" --headless --path "%cd%" --script "res://tests/test_sim_fixes.gd"
if errorlevel 1 goto :fail
echo ALL TEST GATES PASS
pause
exit /b 0
:fail
echo TEST GATE FAILED
pause
exit /b 1
