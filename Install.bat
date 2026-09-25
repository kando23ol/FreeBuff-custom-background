@echo off
rem Freebuff video background - one-click installer.
rem Windows SmartScreen may warn: this is an unsigned local script.
rem It only edits the Freebuff app's index.html on this PC. Nothing is downloaded.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Apply.ps1" %*
echo.
pause
