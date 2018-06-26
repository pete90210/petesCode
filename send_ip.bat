@echo off
setlocal enabledelayedexpansion
set maxcc=0

call:display_help %1
if %ret%==1 goto:fin

set loopctr=0
set TDM1=TDM1.RTP.RALEIGH.IBM.COM
set RAL6=RALVS6.RALEIGH.IBM.COM

if /i x%1==x (
	set do_forever=YES
	set sleepsec=300
) else (
	set do_forever=NO
	set sleepsec=3
	set nt=%1
	set numtries=%1
	
	REM Strip leading zeroes else it is octal
	:nextbyte
	set ntb2=!numtries:~1,1!
	if not x!ntb2!==x (
		set ntb1=!numtries:~0,1!
		if !ntb1!==0 (
			set numtries=!numtries:~1,99!
			goto:nextbyte
		) 
	)
	REM Don't be a knucklehead
	if !numtries!==0 set numtries=1
	echo !numtries!|findstr /xr "[0-9]* 0" >nul || (
		echo Invalid arg %1 : must be valid numeric
		call:display_help_uncond
		exit /b
	)	
) 
	
REM echo numtries !numtries! & exit/b

:loop
set /a loopctr+=1

call:getIP
set maxcc=%ERRORLEVEL%

if !maxcc!==0 ( 
	echo Sending %IBMVPNIPADDR% at DATE[%DATE%] TIME[%TIME%]
	echo %IBMVPNIPADDR%    pete.laptop   Sent %date% %time%>C:\IBMVPNIPADDR
	FTP -s:C:\Users\zebr@channel\build\dos-funcs\send_ip_ftp_cmds.txt 	     !TDM1! 1>NUL 2>NUL
	FTP -s:C:\Users\zebr@channel\build\dos-funcs\send_ip_ftp_cmds_ralvs6.txt !RAL6! 1>NUL 2>NUL
	del C:\IBMVPNIPADDR
) else (
	echo Not connected: DATE[%DATE%] TIME[%TIME%]
)

if !do_forever!==NO if !loopctr! geq !numtries! goto:fin

call:sleep !sleepsec!
goto :loop

:fin
( 
endlocal
exit /b %maxcc%
)


:display_help

set ret=0
if x%1==x goto:eof
if %1==? set help=YES
if %1==/? set help=YES
if %1==\? set help=YES
if /i %1==help set help=YES
if /i %1==/help set help=YES
if /i %1==\help set help=YES
if not !help!==YES goto:eof
set ret=1

:display_help_uncond

echo.   SEND_IP [number-of-attempts]
echo. 	    number-of-attempts ...... numeric: try to send the IP address this many times
echo.                                      with a 3 second sleep between iterations.
echo.                                      Exit when it is sent successfully.
echo.                             	
echo.	If no arg is passed, run forever with 300 second sleep between iterations.
echo.        Keep sending if successful or not.                 
goto:eof                  		







:getIP host ret -- record this computers IBM VPN IP address
@echo off
setlocal enabledelayedexpansion
set ip=*NotResolved*
for /f "tokens=2,* delims=:. " %%a in ('"ipconfig|find "IPv4 Address""') do (
	set ipw=%%b
	set ip2=!ipw:~0,2!
	REM Find only IPaddrs beginning with "9." which is IBM VPN  05/2014 PB
	if "!ip2!"=="9." set ip=!ipw! 
)  
(
ENDLOCAL 
SETX IBMVPNIPADDR %ip% /M 1>NUL
SET IBMVPNIPADDR=%ip%
REM 					DEADBEEF
if %ip:~0,1%==* (set cc=3735928559) else (set cc=0)
exit /b %cc% 
)  



:sleep seconds -- waits some seconds before returning
::             -- seconds [in]  - number of seconds to wait
@ECHO OFF
FOR /l %%a in (%~1,-1,1) do (ping -n 2 -w 1 127.0.0.1>NUL)
EXIT /b                                                                      