@echo off
cd /d %~dp0

frpc -c frpc.ini

pause