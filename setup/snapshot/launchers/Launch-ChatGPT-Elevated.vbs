' Launch the unpacked ChatGPT/Codex app as administrator.
' --do-not-de-elevate prevents Chromium from dropping the admin token.
Set sh = CreateObject("WScript.Shell")
exe = "D:\data\ChatGPT-unpacked\app\ChatGPT.exe"
dir = "D:\data\ChatGPT-unpacked\app"
Set shell = CreateObject("Shell.Application")
shell.ShellExecute exe, "--do-not-de-elevate", dir, "runas", 1
