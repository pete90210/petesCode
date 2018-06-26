setlocal enabledelayedexpansion

cls

pushd "C:\Users\zebr@channel\build\BAT programs\V3"

REM set g.0PTPRODNM=ZDMF
REM set g.0PTPROD=GZD
REM set g.0PTVER=325
REM set g.0PTDISGEN=+1
REM set g.0PTLOGDS=/LOG.TXT

set g.0PTPRODNM=TDMF
set g.0PTPROD=GTD
set g.0PTVER=540
set g.0PTDISGEN=+1
set g.0PTLOGDS=/LOG.TXT


set g.0PTBLDTYP=PROD
set g.0PTBLDTYP=PTFS

start /I/WAIT bldexe %g.0PTPRODNM% %g.0PTPROD% %g.0PTVER% %g.0PTBLDTYP% %g.0PTDISGEN% %g.0PTLOGDS%


popd

ENDLOCAL

exit/b