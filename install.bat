@echo off
echo Starting Chatbot Project installation...
powershell -Command "& {Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/qazasd2518995/chatbot-project/main/setup.ps1' -OutFile '%TEMP%\setup.ps1'; powershell -ExecutionPolicy Bypass '%TEMP%\setup.ps1'}"
pause
