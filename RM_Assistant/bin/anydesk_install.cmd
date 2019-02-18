@echo off
cd /d %~dp0
anydesk --install "%cd%\anydesk" --silent
echo Pa88word | anydesk.exe --set-password
sc config AnyDesk start= demand