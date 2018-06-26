@echo on

setlocal enabledelayedexpansion

REM -----------------------------------------------------------
REM Build Distribution Executable ------- May 8, 2014  PB
REM - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
REM Note -Must include both the 32 and 64 bit SFX extractors 
REM       using the WINRAR GUI (can't find a command switch) 
REM -----------------------------------------------------------

cls

set _modnm="%~f0"
call:logwrite "Enter module: %_modnm%"
set maxcc=0

set PTPRODNM=%1
set PTPROD=%2
set PTVER=%3
set PTBLDTYP=%4
set PTDISGEN=%5

set prodnm=%PTPRODNM%
set prod=%PTPROD%
set ver=%PTVER%
set bldtyp=%PTBLDTYP%
set disgen=%PTDISGEN%
set fmid=H!prod!!ver!

if /i %prod%==GTD set prod_short=T
if /i %prod%==GTD set prod_short_lc=t
if /i %prod%==GZD set prod_short=Z
if /i %prod%==GZD set prod_short_lc=z
if /i %prod%==GED set prod_short=E
if /i %prod%==GED set prod_shortlc=e

REM tolower not working on 1 byte input field and I can't even find the routine  PB 10/2014

REM call:tolower !prod_short! prod_short_lc
REM echo prod_short=!prod_short!
REM echo prod_short_lc=!prod_short_lc! %prod_short_lc%

set maxcc=0
set do_bkup=YES
set do_pause=NO
set do_FTP=YES
set raropt=a -sfx -ep
set xcpyopt=/I/K/Q/Y/H/X/F
set rmtdirbase=/DMSdata/www/html/en/support
REM Checksum must match last line comment in GZDRECON exec
SET GZDRECON_CHECKSUM=FFF899940AD64212B5

set blddir=c:\Users\zebr@channel\build
set prodrel_dir=%blddir%\product-files\%prodnm%\%ver%

if not exist !prodrel_dir! mkdir !prodrel_dir! || (set _symptom= 01 & goto :fail)
 
PUSHD !prodrel_dir!

call:genlogfilename logds

if %do_bkup%==YES ( 
	REM Back everything up for now
	xcopy ..\..\zbuildARCH\*	..\..\zbuildARCH2 		/D/E%xcpyopt%
	xcopy ..\*					..\..\zbuildARCH 		/D/E%xcpyopt%
)

SET zoshost=tdm1.rtp.raleigh.ibm.com
call:logwrite "z/OS FTP host is %zoshost%"

if /I "%bldtyp%"=="PROD" (
	set bldflg=P
	set ziptrsZOS='TDMS2.H%prod%%ver%.%prod_short%0%ver%PRD.DATA'
	set zipnm=%prodnm%%ver%
	set ziptrsPC=!zipnm!
	SET GZDRECON_dir=..\..\..\GZDRECON_cksum_%GZDRECON_CHECKSUM%
	set zipmaintxtZOS='TDMS2.!fmid!.MAINT.TXT'
	set zipmaintxtPC=Maintenance.txt.fromzos
	set ftpgetcmd2=get !zipmaintxtZOS! !zipmaintxtPC!

) else if /I "%bldtyp%"=="PTFS" (
	set bldflg=T
	set ziptrsZOS='TDMS2.H%prod%%ver%.%prod_short%0%ver%PTF.DATA'
	set zipnm=!prod_short_lc!%ver%ptfs
	set ziptrsPC=!prod_short_lc!%ver%_PTFs_Data
	
) else (
	if "%bldtyp%"=="" (
		set m=Arg1 is omitted
	) else (
		set m=Arg1 %bldtyp% is invalid
	)
	call:logwrite "*************************************************************************"
	call:logwrite "**** SEVERE ERROR: !m!- Build Type must be PROD or PTFS"
	call:logwrite "**************************************************************************"
	set maxcc=1
	goto:fin0
)

set oldgen=00
for /F "tokens=2 delims=-" %%f in ('DIR /b/a:d %zipnm%-* ^|findstr /R "%zipnm%-[0-9][0-9] "') do (
set oldgen=%%f
)

set /a newgen=oldgen+1
if %newgen% LEQ 9 (
	REM Convert gen# 0-9 to 00-09
	set newgen=0%newgen%
	set newgen=!newgen:~-2!
)

set oldzipexe=%zipnm%-%oldgen%.exe
set newzipexe=%zipnm%-%newgen%.exe

set olddir=%zipnm%-%oldgen%
set oldzip=%olddir%\%oldzipexe%
set newdir=%zipnm%-%newgen%
set newzip=%newdir%\%newzipexe%

call:logwrite "__________Build Gen____________"
call:logwrite "Current .............. %oldgen%"
call:logwrite "New .................. %newgen%"

call:logwrite "__________Variables____________"
call:logwrite "zipnm 			!zipnm!"
call:logwrite "olddir 			!olddir!"
call:logwrite "oldzip 			!oldzip!"
call:logwrite "oldzipexe		!oldzipexe!"
call:logwrite "newdir 			!newdir!"
call:logwrite "newzip 			!newzip!"
call:logwrite "newzipexe		!newzipexe!"
call:logwrite "ziptrsPC 		!ziptrsPC!"

set ftpgetcmd1=get !ziptrsZOS! !ziptrsPC!

if exist !newdir! (
	rmdir /S/Q !newdir! || (set _symptom= 15 & goto :fail)
	call:logwrite "!newdir! removed: rc [%ERRORLEVEL%]"
)

if !bldflg!==P (
REM Product regen
	REM +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	REM Unzip the prior generation's zip to the new generation's directory.
	REM GZDRECON, TSOBATCH, TAPEBLD, and the PDF documentation
	REM files rarely change.  Also, using this technique means we don't need 
	REM to remember any PDF file names, which are completely different across		
	REM products and product releases.
	REM +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	REM First up, make sure we have a good source zip
	ECHO Validate source zip file: !oldzip!
	WINrar t !oldzip! || (set _symptom= 02 & goto :fail)

	REM Now bring in all the previous files...
	WINrar e !oldzip! !newdir!\ || (set _symptom= 03 & goto :fail)

	if exist !newdir!\GZDRECON del !newdir!\GZDRECON

) else mkdir !newdir!

REM +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
REM Next delete the tersed file so that if the FTP fails we do not
REM build with the previous generation's tersed file.  RC checking
REM from the FTP command is not working. <<< 09/18/2014  PB
REM +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

if exist !newdir!\!zipnm! del !newdir!\!zipnm!

if %do_pause%==YES PAUSE

if %do_FTP%==YES (
	set ftpcmds=!olddir!\ftpcmds.txt

	echo open %zoshost% > !ftpcmds!
	echo user PDB00 >> !ftpcmds!
	echo qaws10qa >> !ftpcmds!
	echo bin >> !ftpcmds!
	echo hash >> !ftpcmds!
	echo lcd !newdir! >> !ftpcmds!
	echo !ftpgetcmd1! >> !ftpcmds!
	if NOT "!ftpgetcmd2!"=="" ( 
		echo ascii >> !ftpcmds!
		echo !ftpgetcmd2! >> !ftpcmds!
	)	
	echo QUIT >> !ftpcmds!

	REM FTP speed up more than 600% w/ overrides:
	set ftpsw=-x:65536 -r:65536 -b:32 -w:393216

	call:logwrite "FTP to !zoshost!"
	FTP -n -s:!ftpcmds! !ftpsw! || (set _symptom= 04 & goto :fail)

	DEL !ftpcmds! || (set _symptom= 05 & goto :fail)
	
) else (
	set msg=FTP tersed z/OS file has been skipped
	echo !msg!
	call:logwrite !msg!
)



cd !newdir!

REM Append new Maintenance.txt records and delete zos ftp file
if NOT "!ftpgetcmd2!"=="" (
	copy Maintenance.txt+Maintenance.txt.fromzos Maintenance.txt.work
	del Maintenance.txt
	del Maintenance.txt.fromzos
	rename Maintenance.txt.work Maintenance.txt
)

REM WinRAR parms: (raropt local variable)
REM		  a ...... Add to archive
REM               t ...... Test archive integrity
REM               v ...... Verbose list
REM		 -sfx .... Generate SelF-eXecuting archive
REM		 -df ..... Delete source Files after archiving
REM		 -ep ..... Don't extract path names
REM		 -rn ..... Rename only

if !bldflg!==P (
REM Product regen
	if %do_pause% ==YES pause
	
	rar -df %raropt% !newzipexe! Maintenance.txt		|| (set _symptom= 06 & goto :fail)
	rar     %raropt% !newzipexe! GZDRECON %GZDRECON_dir%\ 	|| (set _symptom= 07 & goto :fail)
	rar -df %raropt% !newzipexe! TAPEBLD   			|| (set _symptom= 08 & goto :fail)
	rar -df %raropt% !newzipexe! *.pdf 			|| (set _symptom= 09 & goto :fail)
	rar -df %raropt% !newzipexe! TSOBATCH  			|| (set _symptom= 10 & goto :fail)
	
) else (
REM PTF file regen
	REM Non-standard obsolete name is deleted
	if exist !newdir!\v%ver%_PTFs_Data del !newdir!\v%ver%_PTFs_Data
	if %do_pause%==YES pause
) 

rar -df %raropt% !newzipexe! !ziptrsPC!	|| (set _symptom= 11 & goto :fail)
REM rar rn !newzipexe! !ziptrsPC! !perm_ziptrsPC! || (set _symptom= 12 & goto :fail)

REM Test the new Executable and do a verbose list.
rar t !newzipexe! || (set _symptom= 13 & goto :fail)
rar v !newzipexe! || (set _symptom= 14 & goto :fail)

call:logwrite "***********************************************************"
call:logwrite "* New executable generated successfully:"
call:logwrite "* !newzip!" 
call:logwrite "***********************************************************"


:fin

POPD
call:logwrite "Exit module %_modnm% rc[%MAXCC%]"
endlocal & exit/b %maxcc%




:fail

call:logwrite "**************************************************************************"
call:logwrite "**** SEVERE ERROR: RAR or Shell Command Failure: SYMPTOM [%_symptom%]"
call:logwrite "**************************************************************************"
set maxcc=1
goto :fin




:compute_zipnm_suffix

echo on
setlocal enabledelayedexpansion
set zipnm=%1
set disgen=%2
set filenm=%3
set xx=%disgen%
if not %xx:~0,1%==+ (set xx=!zipnm!-%2.txt) else (
	set incr=%xx:~1,9% 
	set found=0
	for /F "tokens=2 delims=-." %%f in ('DIR /b %zipnm%-*.txt ^|findstr /R "%zipnm%-[0-9][0-9][.]txt"') do (
		set found=1
		set zipsfx=%%f
	)
	if !found!==0 set zipsfx=-1
	set /a zipsfx=zipsfx+incr
	if !zipsfx! leq 9 set zipsfx=0!zipsfx!
	set xx=!zipnm!-!zipsfx!.txt
) 
 
endlocal & set %filenm%=%xx%

goto :eof




REM FTP to Linux


nixhost=d25lhttp002.con.can.ibm.com
nixuser=samaxwel
nixstring=lnn10mgn

:randfilenm
set ftpcmds=%temp%\t%random%.txt
if exist !ftpcmds! goto:randfilenm

REM Do the PTF file

set verbyt1=%ver:~0,1%
if !bldflg!==P (set lnode=!verbyt1!%ver%) else (set lnode=data)
call:tolower %prodnm% prodnm_lc

if %prodnm%==TDMF (set osnode=/zos/) else (set osnode=/)

set rmtdir=!rmtdirbase!/%prodnm_lc/v!verbyt1!.!osnode!.!lnode!

echo open %host% > !ftpcmds!
echo user %user% >> !ftpcmds!
echo %string% >> !ftpcmds!
echo bin >> !ftpcmds!
echo hash >> !ftpcmds!
echo lcd !newdir! >> !ftpcmds!
echo cwd !rmtdir! >> !ftpcmds!
echo put !newzipexe! !newzipexe! >> !ftpcmds!
echo QUIT >> !ftpcmds!

set ftpsw=-x:65536 -r:65536 -b:32 -w:393216
FTP -n -s:!ftpcmds! !ftpsw!
DEL !ftpcmds!

goto:eof





:genlogfilename
setlocal enabledelayedexpansion
for /f "tokens=1-4 delims=/ " %%g in ('DATE/T') do (
	set dw=%%g & set dm=%%h & set dd=%%i & set yy=%%j 
)
REM Magic blank eraser
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
if not exist %logdir% mkdir %logdir% || (set _symptom=20 & goto :fail & echo fail)
set logfile=DMSBLD.txt
set log=%1
set logfq=%prodrel_dir%\%logdir%\%logfile%
echo ============================== %dw% %dm%/%dd%/%yy% ============================================= >> %logfq%
endlocal & echo %logfq% !logfq! & set %log%=%logfq% & SET "DMSBLD_LOG=%logfq%" & call:logwrite "Log Initialized"

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

