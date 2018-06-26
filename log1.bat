



:genlogfilename
setlocal enabledelayedexpansion
for /f "tokens=1-4 delims=/ " %%g in ('DATE/T') do (
	set dw=%%g & set dm=%%h & set dd=%%i & set yy=%%j 
)
set dw=%dw: =%
set dm=%dm: =%
set dd=%dd: =%
set yy=%yy: =%
for /f "tokens=1-3 delims=: " %%g in ('TIME/T') do (
	set hh=%%g & set mm=%%h & set ap=%%i
)
set hh=%hh: =%
set mm=%mm: =%
set ap=%ap: =%

set logdir=LOG_%dm%-%yy%
if not exist %logdir% mkdir %logdir% || goto :fail
set logfile=DMSBLD.txt
set log=%1
set logfq=%prodrel_dir%\%logdir%\%logfile%
echo ============================== %dw% %dm%/%dd%/%yy% ============================================= >> %logfq%
endlocal & echo %logfq% !logfq! & set %log%=%logfq% & SET "DMSBLD_LOG=%logfq%"

goto:eof






:logwrite 
setlocal enabledelayedexpansion
for /f "tokens=1-3 delims=: " %%g in ('TIME/T') do (
	set hh=%%g & set mm=%%h & set ap=%%i
)
set hh=%hh: =%
set mm=%mm: =%
set ap=%ap: =%
set str=%1
for /f "useback tokens=*" %%a in ('%1') do set str=%%~a
echo %hh%:%mm% %ap% - %str% >> %DMSBLD_LOG%
endlocal
goto:eof



:fail
exit /b %ERRORLEVEL%

