@echo off
REM ============================================================
REM ADAMS Adamspy 批处理运行 wrapper（通用模板）
REM 用法：run_adams.bat <script.py>
REM   例：run_adams.bat C:\work\my_model.py
REM 依赖：本机已装 MSC Adams 2020，按需修改下方 ADAMS_HOME。
REM 结果：脚本 print 输出写入 %ADAMS_HOME%\common\aview.log
REM ============================================================
setlocal

REM ---- 修改为你的 Adams 安装目录 ----
set "ADAMS_HOME=C:\Program Files\MSC.Software\Adams\2020_711253"

REM ---- 参数解析 ----
set "SCRIPT=%~1"
if "%SCRIPT%"=="" (
    echo 用法: run_adams.bat ^<script.py^>
    exit /b 1
)
if not exist "%SCRIPT%" (
    echo 错误: 脚本不存在 "%SCRIPT%"
    exit /b 1
)

REM ---- 生成 View 命令文件 ----
set "WORKDIR=%TEMP%\adams_run_%RANDOM%"
mkdir "%WORKDIR%" 2>nul
set "BATCHCMD=%WORKDIR%\batch.cmd"
> "%BATCHCMD%" echo file python read file="%SCRIPT%"

REM ---- 切到 common 目录调用 mdi.bat（批处理模式）----
cd /d "%ADAMS_HOME%\common"
call mdi.bat aview ru-st b "%BATCHCMD%"

REM ---- 清理临时文件 ----
rmdir /s /q "%WORKDIR%" 2>nul

echo.
echo 运行完成。日志见 "%ADAMS_HOME%\common\aview.log"
endlocal
