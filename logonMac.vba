[PCOMM SCRIPT HEADER]
LANGUAGE=VBSCRIPT
DESCRIPTION=
[PCOMM SCRIPT SOURCE]
OPTION EXPLICIT
autECLSession.SetConnectionByName(ThisSessionName)


    function readFile(sPath)
        const forReading = 1
        dim objFSO, objFile, sData
        set objFSO = createobject("Scripting.FileSystemObject")
        set objFile = objFSO.openTextFile(sPath, ForReading)
        sData = ""
        do until objFile.atEndOfStream
            sData = sData & objFile.readLine & vbCrLf
        loop
        objFile.close
        set objFile = nothing
        set objFSO = nothing
        readFile = sData
    end function

REM This line calls the macro subroutine
subSub1_

sub subSub1_()
   autECLSession.autECLOIA.WaitForInputReady
   autECLSession.autECLPS.SendKeys "userid@xx.xx.xx.com"
   autECLSession.autECLOIA.WaitForInputReady
   autECLSession.autECLPS.SendKeys "[enter]"

   autECLSession.autECLPS.Wait 30000

   autECLSession.autECLOIA.WaitForInputReady
   autECLSession.autECLPS.SendKeys "pppppppp"
   autECLSession.autECLOIA.WaitForInputReady
   autECLSession.autECLPS.SendKeys "[enter]"

   autECLSession.autECLPS.WaitForAttrib 3,14,"04","3c",3,10000

   autECLSession.autECLPS.WaitForCursor 3,15,10000

   autECLSession.autECLOIA.WaitForAppAvailable

   autECLSession.autECLOIA.WaitForInputReady
   autECLSession.autECLPS.SendKeys "amazon-AWS"
   autECLSession.autECLOIA.WaitForInputReady
   autECLSession.autECLPS.SendKeys "[enter]"

   autECLSession.autECLPS.WaitForAttrib 1,26,"00","3c",3,10000

   autECLSession.autECLPS.WaitForCursor 2,1,10000

   autECLSession.autECLOIA.WaitForAppAvailable

   autECLSession.autECLOIA.WaitForInputReady
   autECLSession.autECLPS.SendKeys "uuuuuuuu"
   autECLSession.autECLOIA.WaitForInputReady
   autECLSession.autECLPS.SendKeys "[enter]"

   autECLSession.autECLPS.WaitForAttrib 8,19,"0c","3c",3,10000

   autECLSession.autECLPS.WaitForCursor 8,20,10000

   autECLSession.autECLOIA.WaitForAppAvailable

   autECLSession.autECLOIA.WaitForInputReady
   autECLSession.autECLPS.SendKeys "xxxxxxxx"
   autECLSession.autECLOIA.WaitForInputReady
   autECLSession.autECLPS.SendKeys "[enter]"

   autECLSession.autECLPS.WaitForAttrib 10,5,"00","3c",3,10000

   autECLSession.autECLPS.Wait 5688

   autECLSession.autECLOIA.WaitForAppAvailable

   autECLSession.autECLOIA.WaitForInputReady
   autECLSession.autECLPS.SendKeys "[enter]"
end sub
