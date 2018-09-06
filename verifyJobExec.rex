/* REXX **************************************************************
 *                                                                   *
 * VERIFJOB    This sample REXX will verify the job that it receives *
 *             as parameter and if everything is OK will send a re-  *
 *             port to those e-mail addresses that it will find in   *
 *             the file CUSTOMRS and if there is some error it will  *
 *             collect information about the job and send it to      *
 *             those e-mail addresses found in the file PROGRMRS.    *
 *                                                                   *
 *             On abnormal situations:                               *
 *                                                                   *
 *             - If the user has implemented IEFACTRT exit and VE-   *
 *               RIFJOB is able to find the steps termination report *
 *               in the spool's JESMSGLG corresponding to the job,   *
 *               it will send to the list of programmers this report *
 *                                                                   *
 *             - If either the user has not implemented IEFACTRT in  *
 *               her/his installation or VERIFJOB is not able of     *
 *               finding the report expected, it will search the     *
 *               JESYSMSG spool ddname looking for the system messa- *
 *               ges that has read previously from the file SYSMSGS, *
 *               it will produce a report and send it to the pro-    *
 *               grammers list                                       *
 *                                                                   *
 *             - If there is a JCL error previous to the beginning   *
 *               of any step, VERIFJOB will send the JCL error       *
 *                                                                   *
 * Parameters                                                        *
 *                                                                   *
 *  JOBNAME(parm_jobname)                                            *
 *               Required parameter. Jobname to be looked for in the *
 *               spool                                               *
 *                                                                   *
 *  JOBID(parm_jobid)                                                *
 *               Optional parameter. Jobid corresponding to the pre- *
 *               cise job that we are looking for                    *
 *                                                                   *
 *  REPORT(parm_report)                                              *
 *               Required parameter. Report name to look for         *
 *                                                                   *
 *  STEP(parm_step)                                                  *
 *               Optional parameter. Step name where the report is   *
 *               located                                             *
 *                                                                   *
 *  SUBMITTIME(date_submit time_submit | time_submit)                *
 *               Optional parameter. Date and time of submit. If on- *
 *               ly the time is specified, we assume that the date   *
 *               is the current date. The date must be written using *
 *               the Julian date format YYYY.DDD                     *
 *                                                                   *
 *               We will select the first job with the same name as  *
 *               the JOBNAME parameter and whose date and time of    *
 *               submit are greater or equal to the SUBMITTIME para- *
 *               meter.                                              *
 *                                                                   *
 *               If both JOBID and SUBMITTIME are present. We ignore *
 *               the SUBMITTIME parameter.                           *
 *                                                                   *
 *  MAXCC(parm_maxcc)                                                *
 *               Maximum return code for the entire job. If it is    *
 *               not present, a maximum return code of 0 will be     *
 *               assumed.                                            *
 *                                                                   *
 *               If the return code of the job surpasses the value   *
 *               of the MAXCC parameter, instead of the REPORT, a    *
 *               summary of the execution of the job will be sended  *
 *               to the addresses contained in the PROGRAMRS file    *
 *                                                                   *
 *  VERBOSE                                                          *
 *               Optional parameter. Activates tracing of this REXX  *
 *                                                                   *
 * Files                                                             *
 *                                                                   *
 *  CUSTOMRS                                                         *
 *               File with customers' e-mail addresses and names     *
 *  PROGRMRS                                                         *
 *               File with programmers' e-mail addresses and names   *
 *  SYSMSGS                                                          *
 *               File with system message ids indicating end of step *
 *                                                                   *
 *********************************************************************/
 signal on novalue name error_trap

 debug = 1
 select                               /* Debug and tracing level     */
  when (debug = 1) then trace o       /* 1.- only programmer's says  */
  when (debug = 2) then trace r       /* 2.- trace results           */
  when (debug = 3) then trace i       /* 3.- trace intermediates     */
  when (debug = 4) then trace("?i")   /* 4.- trace interactive       */
  otherwise trace o                   /* default - no trace          */
 end                                  /*                             */

 arg parameter

 call initialize_variables
 call verify_parameters
 call activate_SDSF_REXX_support
 call set_SDSF_special_variables
 call search_job
 call load_configuration

 /*
  * If the customer's report is not found, we will send a summary of
  * of the execution of the job to the programmers for review
  */
 call search_report "CONTINUE" parm_report parm_step
 if report_token = "" then
    report_type = "PROGRAMMER"
 if report_type = "CUSTOMER" then
    call email_report report_token
 else
    call analyze_job currtoken

finish:
 if connected_smtp = "YES" then do
    call send_command "QUIT"
    call disconnect_from_smtp_server
 end
 rc = isfcalls('OFF')
 exit retcode


/*====================================================================*/
/* Internal REXX subroutines                                          */
/*====================================================================*/

/*--------------------------------------------------------------------*/
/* Initialize the variables used through the REXX progam              */
/*--------------------------------------------------------------------*/
initialize_variables:

 parm_jobname   = ""
 parm_jobid     = ""
 parm_report    = ""
 parm_date      = ""
 parm_time      = ""
 parm_maxcc     = 0
 submit_time    = ""

 retcode        = 0
 currtoken      = ""
 report_type    = "CUSTOMER"
 report_title   = ""
 report_token   = ""
 job_found      = "NO"
 connected_smtp = "NO"
 cell_fmt       = '<font size="2" face="Courier New"><pre>'
 ecell_fmt      = '</pre></font>'

 IEFACTRT_found = "NO"
 start_iefactrt = "--TIMINGS (MINS.)--"
 end_iefactrt   = "TOTAL CPU TIME="

 return


/*--------------------------------------------------------------------*/
/* Subroutine to verify the parameters received and assign values to  */
/* the corresponding REXX variables.                                  */
/*--------------------------------------------------------------------*/
verify_parameters:

 /*
  * Parsing for optional keyword VERBOSE. If it is present, and the
  * REXX variable "debug" was not set, it will be set to the minimum
  * level of debugging
  */
 do ip = 1 to words(parameter)
    if word(parameter,ip) = "VERBOSE" then do
       debug = max(debug,1)
       leave ip
    end
 end

 if debug > 0 then
    say "Verifying parameters..."

 /*
  * Parsing required parameter JOBNAME
  */
 parse var parameter "JOBNAME("parm_jobname")"
 if strip(parm_jobname) = "" then do
    say "Required paremeter JOBNAME(xxxxxxxx) is empty. Quitting."
    retcode = 20
    signal finish
 end

 /*
  * Parsing optional parameter STEP
  */
 parse var parameter "STEP("parm_step")"

 /*
  * Parsing required parameter REPORT
  */
 parse var parameter "REPORT("parm_report")"
 if strip(parm_report) = "" then do
    say "Required paremeter REPORT(xxxxxxxx) is empty. Quitting."
    retcode = 20
    signal finish
 end

 /*
  * Parsing optional parameters JOBID and SUBMITTIME. If both present
  * JOBID takes precedence
  */
 parse var parameter "JOBID("parm_jobid")"
 parse var parameter "SUBMITTIME("submit_time")"

 if strip(parm_jobid) = "" & strip(submit_time) = "" then do
    say "Either 'JOBID' or 'SUBMITTIME' must be specified. Quitting."
    retcode = 20
    signal finish
 end
 if parm_jobid <> "" & submit_time <> "" then do
    say "Warning. JOBID & SUBMITTIME specified. Only considering JOBID"
    submit_time = ""
 end

 /*
  * SUBMITTIME may have date & time or only time. In the later case
  * we consider that the date is the current date
  */
 if submit_time <> "" then do
    if words(submit_time) = 1 then do
       parm_date = left(date("Standard"),4)"."left(date("Julian"),3)
       parm_time = submit_time
    end
    else do
       parm_date = word(submit_time,1)
       parm_time = word(submit_time,2)
    end
 end

 /*
  * Parsing optional parameter MAXCC. Maximum return code
  */
 parse var parameter "MAXCC("parm_maxcc")"
 if strip(parm_maxcc) = "" then
    parm_maxcc = 0

 if datatype(parm_maxcc) <> "NUM" then do
    say "Warning: parameter MAXCC("parm_maxcc") ignored. MAXCC <- 0"
    parm_maxcc = 0
 end

 if debug > 0 then do
    say "The input parameters specified were: "
    say " JOBNAME........: '"parm_jobname"'"
    say " JOBID..........: '"parm_jobid"'"
    say " REPORT.........: '"parm_report"'"
    say " SUBMIT TIME....: '"parm_date parm_time"'"
    say " MAXCC..........: "parm_maxcc
 end

 return


/*--------------------------------------------------------------------*/
/* In order to use REXX with SDSF is mandatory to add a host command  */
/* environment prior to any other SDSF host environment commands      */
/*--------------------------------------------------------------------*/
activate_SDSF_REXX_support:

 /*
  * Turn on SDSF "host command environment"
  */
 rc_isf = isfcalls("ON")
 select
  when rc_isf = 00 then return
  when rc_isf = 01 then msg_isf = "Query failed, environment not added"
  when rc_isf = 02 then msg_isf = "Add failed"
  when rc_isf = 03 then msg_isf = "Delete failed"
  otherwise do
    msg_isf = "Unrecognized Return Code from isfCALLS(ON): "rc_isf
  end
 end

 if rc_isf <> 00 then do
    say "Error adding SDSF host command environment." msg_isf
    retcode = rc_isf * 10
    signal finish
 end

 return


/*--------------------------------------------------------------------*/
/* Set SDSF special variables to customize information retrieval      */
/*--------------------------------------------------------------------*/
set_SDSF_special_variables:

 isfprefix = parm_jobname          /* Only those jobs that matches    */
 isfowner  = "*"                   /* Owner does not care             */
 command   = "ST"                  /* SDSF panel STATUS               */

 return


/*--------------------------------------------------------------------*/
/* Search the job received by parameter using the tabular display     */
/* provided by the SDSF Status panel                                  */
/*--------------------------------------------------------------------*/
search_job:

 if debug > 0 then
    opts_sdsf = "(VERBOSE ALTERNATE DELAYED)"
 else
    opts_sdsf = "(ALTERNATE DELAYED)"

 call exec_sdsf "0 ISFEXEC ST" opts_sdsf
 do ij = 1 to JNAME.0

    if RETCODE.ij = "" then do                         /* Not ended */
       if JOBID.ij = parm_jobid then
          leave ij
       else
          iterate
    end

    if parm_jobid <> "" then do
       if JOBID.ij = parm_jobid then
          job_found = "YES"
    end

    if submit_time <> "" then do
       if later_time(parm_date,parm_time,DATER.ij,TIMER.ij) = 1 then
          job_found = "YES"
    end

    if job_found = "YES" then do
      currtoken = TOKEN.ij
      job_found = "YES"
      leave ij
    end

 end

 if job_found = "NO" then do
    say;say
    say "*"copies("=",78)"*"
    say "*"center(parm_jobname "not found in spool. Try later.",78)"*"
    say "*"copies("=",78)"*"
    say;say
    retcode = 8
    signal finish
 end

 if debug > 0 then do
    say "Job found in JES spool"
    say " JOB............: "JNAME.ij JOBID.ij
    say " STARTED-ENDED..: "DATEE.ij TIMEE.ij "-" DATEN.ij TIMEN.ij
    say " Max-RC.........: "RETCODE.ij
 end

 /*
  * Test if the maximum return code of the job is greater or equal than
  * the parameter MAXCC
  */
 if word(RETCODE.ij,1) = "CC" & word(RETCODE.ij,2) <= parm_maxcc then do
    say " Parameter MAXCC: "parm_maxcc "(OK)"
    report_type  = "CUSTOMER"
    report_title = "Report" parm_report ,
                   "from " JNAME.ij"-"JOBID.ij ,
                   "("DATEN.ij"-"TIMEN.ij")"
 end
 else do
    say " Parameter MAXCC: "parm_maxcc ". Job Max-RC:" RETCODE.ij
    say " Condition not satisfied. The programmers must be notified"
    report_type  = "PROGRAMMER"
    report_title = "Error report of the job" ,
                   JNAME.ij"-"JOBID.ij ,
                   "("DATEN.ij"-"TIMEN.ij")"
 end

 return


/*--------------------------------------------------------------------*/
/* Subroutine to analyze the job's execution. If it founds the sec-   */
/* tion formatted by the SMF exit IEFACTRT, then sends it, else tries */
/* to find the messages that system writes on JESYSMSG signaling the  */
/* end of a step.                                                     */
/*    ...                                                             */
/*    IEF373I STEP/stepname/START ...                                 */
/*    IEF374I STEP/stepname/STOP ...                                  */
/*    ...                                                             */
/*--------------------------------------------------------------------*/
analyze_job:

 parse arg currtoken

 /*
  * We will send the job summary to the programmers, not the customers
  */
 drop mail.to.
 do ix = 1 to programmer.0
    parse var programmer.ix mail.to.address.ix mail.to.name.ix
    mail.to.address.ix = strip(mail.to.address.ix)
    mail.to.name.ix    = strip(mail.to.name.ix)
 end
 mail.to.address.0 = programmer.0
 mail.to.name.0    = programmer.0

 /*
  * If the installation has implemented IEFACTRT we will send the
  * IEFACTRT report in JESMSGLG to the programmers.
  */
 call search_report "CONTINUE" "JESMSGLG" ""
 if report_token <> "" then do
    call locate_IEFACTRT_section report_token
    if IEFACTRT_found = "YES" then do
       call connect_to_smtp_server
       call send_email_message
    end
    return
 end

 /*
  * We have not found the IEFACTRT section, we must scan the JESYSMSG
  * file looking for any of the messages that we have read from the
  * file SYSMSGS
  */
 call search_report "CONTINUE" "JESYSMSG" ""
 if report_token <> "" then do
    call locate_system_messages report_token
    call connect_to_smtp_server
    call send_email_message
 end

 return


/*--------------------------------------------------------------------*/
/* Load configuration files                                           */
/*--------------------------------------------------------------------*/
load_configuration:

 drop mail.
 call load_mail_parms
 call load_customers
 call load_programmers
 call load_system_messages

 return


/*--------------------------------------------------------------------*/
/* Search por a ddname (report) in the job's spool                    */
/*--------------------------------------------------------------------*/
search_report:

 parse arg sr_option reportdd step_name
 say sr_option reportdd step_name

 /*
  * The option VERBOSE tells SDSF that it must add diagnostic messages
  * to ISFMSG2. stem variable. The ddnames returned by ISFACT will be
  * prefixed with a "J" character
  */
 if debug > 0 then
    opts_sdsf = "(VERBOSE PREFIX J)"
 else
    opts_sdsf = "(PREFIX J)"

 call exec_sdsf "0 ISFACT ST TOKEN('"currtoken"') PARM(NP ?)" opts_sdsf
 do ddname = 1 to JDDNAME.0
    /*
     * Look for received parameter
     */
    if JDDNAME.ddname = reportdd then do
       if step_name = "" | JPROCS.ddname = step_name then do
          report_token = jtoken.ddname
          leave ddname
       end
    end
 end

 if report_token = "" then do
    say;say
    say "*"copies("=",78)"*"
    say "*"center("Report "reportdd" not found in job spool",78)"*"
    say "*"copies("=",78)"*"
    say;say
    if sr_option = "CANCEL" then do
       retcode = 12
       signal finish
    end
 end

 return


/*--------------------------------------------------------------------*/
/* Subroutine to locate the output from the SMF exit IEFACTRT in the  */
/* JESMSGLG ddname. In this sample we expect that the format of the   */
/* output lines as the unmodified version of the exit in SYS1.SAMPLIB,*/
/* so we look for the character string "--TIMINGS (MINS.)--".         */
/*--------------------------------------------------------------------*/
locate_IEFACTRT_section:

 parse arg ieftoken

 t = 0
 call exec_sdsf "0 ISFACT ST TOKEN('"ieftoken"') PARM(NP SA)"
 do kx = 1 to isfddname.0
    "EXECIO * DISKR" isfddname.kx "(OPEN FINIS STEM spool.)"
    if rc <> 0 then call error_reading_spool isfddname.kx
    do ief = 1 to spool.0
       if pos(start_iefactrt, spool.ief) > 0 then do
          IEFACTRT_found = "YES"
          call create_report_header
       end
       /*
        * If section found, store each line in the message body text, if
        * it belongs to the the section a '-' character as first charac-
        * ter of the third word, as the SYS1.SAMPLIB(IEFACTRT) does
        *
        * 15.37.51 JOB25151  -         (SELECT)
        * 15.37.51 JOB25151  -JOBNAME  (SELECT)
        * 15.37.51 JOB25151  -ABEND01  (SELECT)
        * 15.37.51 JOB25151  IEF404I   (NO)
        * 15.37.51 JOB25151  -ABEND01  (SELECT)
        * 15.37.51 JOB25151  $HASP395  (NO)
        *
        */
       if IEFACTRT_found = "YES" then do
          if left(word(spool.ief,3),1) = "-" then do
             if t = 1 then
                t = 2
             else
                t = 1
             ief_line = substr(spool.ief,21)
             call store_line '<tr class=t't'>',
                             '<td><pre>',
                             cell_fmt||ief_line||ecell_fmt,
                             '</pre></td>'
                             '</tr>'
          end
       end
       if pos(end_iefactrt, spool.ief) > 0 then
          leave ief
    end
    if IEFACTRT_found = "YES" then
       call create_report_footer
 end

 return


/*--------------------------------------------------------------------*/
/*                                                                    */
/*--------------------------------------------------------------------*/
locate_system_messages:

 parse arg msgtoken

 t = 0
 header_done = "NO"
 call exec_sdsf "0 ISFACT ST TOKEN('"msgtoken"') PARM(NP SA)"
 do kx = 1 to isfddname.0
    "EXECIO * DISKR" isfddname.kx "(OPEN FINIS STEM spool.)"
    if rc <> 0 then call error_reading_spool isfddname.kx
    do imsg = 1 to spool.0
       msg_found = "NO"
       do smsg = 1 to sysmsg.0
          if word(spool.imsg,1) = sysmsg.smsg then
             msg_found = "YES"
             leave smsg
       end
       if msg_found = "YES" & header_done = "NO" then do
          if header_done = "NO" then do
             call create_report_header
             header_done = "YES"
          end
          if t = 1 then
             t = 2
          else
             t = 1
          msg_line = substr(spool.imsg,10)
          call store_line '<tr class=t't'>',
                          '<td><pre>'msg_line'</pre></td></tr>'
       end
    end
    if header_done = "YES" then
       call create_report_footer
 end

 return


/*--------------------------------------------------------------------*/
/*                                                                    */
/*--------------------------------------------------------------------*/
email_report:

 parse arg ddtoken

 t = 0
 call exec_sdsf "0 ISFACT ST TOKEN('"ddtoken"') PARM(NP SA)"
 do kx = 1 to isfddname.0
    "EXECIO * DISKR" isfddname.kx "(OPEN FINIS STEM spool.)"
    if rc <> 0 then call error_reading_spool isfddname.kx
    call create_report_header
    do lx = 1 to spool.0
       if t = 1 then
          t = 2
       else
          t = 1
       call store_line '<tr class=t't'><td><pre>',
                        spool.lx'</pre></td></tr>'
    end
    call create_report_footer
 end
 call connect_to_smtp_server
 call send_email_message

 return


/*--------------------------------------------------------------------*/
/*                                                                    */
/*--------------------------------------------------------------------*/
create_report_header:

 mail.text.line.0 = 0
 call store_line '<html>'
 call store_line '<head>'
 call store_line '<title>'report_title'</title>'
 call store_line '</head>'
 call store_line '<body>'
 call store_line '<style type="text/css">'
 call store_line 'body {'
 call store_line ' padding: 0px;'
 call store_line ' margin: 0px;'
 call store_line '}'
 call store_line 'table.report {'
 call store_line ' font-family: "Courier New", Courier, mono;'
 call store_line ' font-size: 9pt;'
 call store_line ' display: table;'
 call store_line ' table-layout: fixed;'
 call store_line '}'
 call store_line 'tbody { display: table-row-group }'
 call store_line 'tr { display: table-row }'
 call store_line 'tr.t1 td {'
 call store_line ' background-color: #ddddff;'
 call store_line ' color: black;'
 call store_line '}'
 call store_line 'tr.t1 td {'
 call store_line ' background-color: #ffeeee;'
 call store_line ' color: black;'
 call store_line '}'
 call store_line '</style>'
 call store_line '<table border=0 class=report>'
 call store_line '<tbody>'

 return


/*--------------------------------------------------------------------*/
/*                                                                    */
/*--------------------------------------------------------------------*/
create_report_footer:

 call store_line '</tbody>'
 call store_line '</table>'
 call store_line '</body>'
 call store_line '</html>'

 return


/*--------------------------------------------------------------------*/
/*                                                                    */
/*--------------------------------------------------------------------*/
send_email_message:

 rcpts = ""
 do ir = 1 to mail.to.address.0

    rcpts = rcpts mail.to.name.ir" <"mail.to.address.ir">,"
 end
 rcpts = left(rcpts,length(rcpts)-1)

 call receive_data     /* we read the welcome message of the server */
 call send_command 'HELO ibm'
 call send_command 'MAIL FROM: <'strip(mail.from.address)'>'
 call send_command 'RCPT TO: <'strip(mail.to.address.1)'>'
 call send_command 'DATA'
 call send_line 'Date: ' date() time()
 call send_line 'From: 'mail.from.name' <'strip(mail.from.address)'>'
 call send_line 'To: 'rcpts

/*
  * If there is any subject loaded from the configuration file,
  * we will use it.
  */
 if mail.subject = "" then
    call send_line 'Subject: ' report_title
 else
    call send_line 'Subject: ' mail.subject

 call send_line 'MIME-Version: 1.0'
 call send_line 'Content-Type: text/html; charset="iso-8859-1"'
 call send_line 'Content-Transfer-Encoding: quoted-printable'
 call send_line ""

 /* send DATA */
 do num = 1 to mail.text.line.0
    call send_line mail.text.line.num
 end

 call send_command "."

return


/*--------------------------------------------------------------------*/
/* Store one line in the e-mail stem variable                         */
/*--------------------------------------------------------------------*/
store_line:

 parse arg line_text

 if debug > 0 then
    say line_text

 ly = mail.text.line.0
 ly = ly + 1
 mail.text.line.ly = line_text
 mail.text.line.0  = ly

 return


/*--------------------------------------------------------------------*/
/* Decide if read datetime is later than the parameter datetime       */
/*--------------------------------------------------------------------*/
later_time:

 parse arg parm_date, parm_time, read_date, read_time

 if parm_date < read_date then
    return 1

 if parm_date = read_date then
    if parm_time < read_time then
       return 1

 return 0


/*--------------------------------------------------------------------*/
/* Load mail configuration parameters                                 */
/*--------------------------------------------------------------------*/
load_mail_parms:

 "EXECIO * DISKR MAILPARM (OPEN FINIS STEM mailparm."
 if rc <> 0 then do
    say "Error" rc "reading MAILPARM file"
    retcode = 16
    signal finish
 end

 /*-------------------------------------------------------------------*/
 /* Load stem mail. with configuration values                         */
 /*-------------------------------------------------------------------*/
 mail.subject = ""
 do im = 1 to mailparm.0
    wparm = mailparm.im
    parm  = word(translate(wparm," ","="),1)
    poseq = pos("=",mailparm.im)
    if poseq > 0 then do
       text_value = substr(mailparm.im, poseq + 1)
       interpret "mail."parm" = '"strip(text_value)"'"
    end
 end

 return


/*--------------------------------------------------------------------*/
/* Load customers e-mails from CUSTOMER file                          */
/*--------------------------------------------------------------------*/
load_customers:

 "EXECIO * DISKR CUSTOMRS (OPEN FINIS STEM customer."
 if rc <> 0 then do
    say "Error" rc "reading CUSTOMRS file"
    retcode = 16
    signal finish
 end

 /*
  * Split each customer line into an email address and a name
  */
 do ic = 1 to customer.0
    parse var customer.ic mail.to.address.ic mail.to.name.ic
    mail.to.address.ic = strip(mail.to.address.ic)
    mail.to.name.ic    = strip(mail.to.name.ic)
 end
 mail.to.address.0 = customer.0
 mail.to.name.0    = customer.0

 return


/*--------------------------------------------------------------------*/
/* Load programmers e-mails from PROGRAMMER file                      */
/*--------------------------------------------------------------------*/
load_programmers:

 "EXECIO * DISKR PROGRMRS (OPEN FINIS STEM programmer."
 if rc <> 0 then do
    say "Error" rc "reading PROGRMRS file"
    retcode = 16
    signal finish
 end

 return


/*--------------------------------------------------------------------*/
/* Load system messages that indicate end of JCL step                 */
/*--------------------------------------------------------------------*/
load_system_messages:

 "EXECIO * DISKR SYSMSGS (OPEN FINIS STEM sysmsg."
 if rc <> 0 then do
    say "Error" rc "reading SYSMSGS file"
    retcode = 16
    signal finish
 end

 return


/*--------------------------------------------------------------------*/
/* Subroutine to notify an error reading an spool dataset             */
/*--------------------------------------------------------------------*/
error_reading_spool:

 arg spool_ddname

 say ">>>"
 say ">>>  Error reading spool dataset dd:" spool_ddname
 say ">>>"
 retcode = 20
 signal finish

 return


/*--------------------------------------------------------------------*/
/* Subroutine to execute an SDSF REXX command testing its return code */
/*--------------------------------------------------------------------*/
exec_sdsf:

 parse arg max_SDSF_rc exec_SDSF_command

 /*
  * Drop SDSF msg standard variable in order to not get confused by
  * any previous value
  */
 if symbol("ISFMSG") = "VAR" then
    drop isfmsg

 sdsf = "OK"
 address SDSF exec_SDSF_command
 rc_SDSF = rc
 if (max_SDSF_rc = "*") then
    return rc_SDSF

 if (rc_SDSF  > max_SDSF_rc | rc_SDSF < 0) then do
    call SDSF_msg_rtn exec_SDSF_command
    sdsf = "KO"
 end

 return 0


/*--------------------------------------------------------------------*/
/* Subroutine to list SDSF error messages                             */
/*--------------------------------------------------------------------*/
SDSF_msg_rtn:

 parse arg exec_SDSF_command

 say ">>>" exec_SDSF_command
 /*
  * The isfmsg variable must contain a short message
  */
 if isfmsg <> "" then
    say ">>>" isfmsg

 /*
  * The isfmsg2 stem contains additional descriptive
  * error messages
  */
 if datatype(isfmsg2.0) "NUM" then do
    do ierr = 1 to isfmsg2.0
      say ">>>" isfmsg2.ierr
    end
 end

 say ">>>"

 return


/*--------------------------------------------------------------------*/
/* Send one line of data to the SMTP server                           */
/*--------------------------------------------------------------------*/
send_command:

 parse arg parm_line

 call send_line parm_line
 call receive_data
 if smtp_rc = 250 | ,
    smtp_rc = 221 | ,
    smtp_rc = 251 | ,
    smtp_rc = 354 then
    nop
 else do
    say smtp_data_received
    upper parm_line
    if strip(parm_line) <> "QUIT" then do
       retcode = smtp_rc
       signal finish
    end
 end

 return


/*--------------------------------------------------------------------*/
/* Send one line of data to the SMTP server                           */
/*--------------------------------------------------------------------*/
send_line:

 parse arg line_text

 line_text = line_text || x2c(25)
 socktxt = exec_socket("0", "Send", smtp_socket, line_text)

 if (debug > 0) then do
    total_length = length(line_text)
    say 'sent....: ' substr(line_text, 1, total_length - 1)
 end

 return


/*--------------------------------------------------------------------*/
/* Receive one line of data from the SMTP server                      */
/*--------------------------------------------------------------------*/
receive_data:

 buffer_size        = 8192
 smtp_rc            = -1
 smtp_data_received = ""
 do forever
    socktxt = exec_socket("0", "Recv", smtp_socket, buffer_size)
    parse var socktxt data_length data_received
    if data_length = 0 then
       leave
    smtp_data_received = smtp_data_received || data_received
    if c2x(right(smtp_data_received,1)) = 25 then do
       smtp_rc = word(smtp_data_received, 1)
       leave
    end
 end

 if (debug > 0) then do
    total_length = length(smtp_data_received)
    say 'received:' substr(smtp_data_received, 1, total_length - 2)
 end

 return


/*--------------------------------------------------------------------*/
/* Connect to the remote server using parameters stored in profile    */
/*--------------------------------------------------------------------*/
connect_to_smtp_server:

 /*-------------------------------------------------------------------*/
 /* Initialize TCP/IP REXX environment                                */
 /*-------------------------------------------------------------------*/
 tcpident = mvsvar("SYSNAME") || strip(random(0, 999))
 tcpident = exec_socket("0", "Initialize", tcpident, 50)
 if sockrc = 0 then do
    if debug > 0 then do
       parse var tcpident subtskid maxdesc service
       if debug > 0 then do
          socktxt = exec_socket("0", "Version")
          say "Socket Version.......: " socktxt
          say "Substask identifier..: " word(subtskid, 1)
          say "Maximum descriptors..: " maxdesc
          say "Service name.........: " service
       end
    end
 end

 /*
  * Get a new socket
  */
 smtp_socket = exec_socket("0","Socket")
 if debug > 0 then do
    say "Socket number........: " smtp_socket
 end

 /*
  * Server expects ASCII text
  */
 socktxt = exec_socket("0","Setsockopt",,
                           smtp_socket,,
                           "SOL_SOCKET",,
                           "SO_ASCII",,
                           "ON")

 /*
  * Finally, connect to the SMTP server
  */
 socktxt = exec_socket("0","Connect",,
                           smtp_socket,,
                           "AF_INET" 25 mail.smtp)
 if debug > 0 then do
    say "SMTP server:port.....: " mail.smtp":25"
    say "Socket connected !!!"
 end
 connected_smtp = "YES"

 return


/*--------------------------------------------------------------------*/
/* Disconnect from the server                                         */
/*--------------------------------------------------------------------*/
disconnect_from_smtp_server:

 socktxt = exec_socket("*","Shutdown", smtp_socket, "BOTH")
 if debug > 0 then do
    say "SMTP server:port.....: " mail.smtp":25"
    say "Socket disconnected !!!"
 end
 socktxt = exec_socket("*","Terminate", subtskid)

 return


/*--------------------------------------------------------------------*/
/* Subroutine to call TCP/IP socket functions and analyze results     */
/*--------------------------------------------------------------------*/
exec_socket:

  socksigl = sigl
  max_sockets_rc = Arg(1)
  sockfunc = Arg(2)
  arg1     = Arg(3)
  arg2     = Arg(4)
  arg3     = Arg(5)
  arg4     = Arg(6)

  sockcall = socket(sockfunc,arg1,arg2,arg3,arg4)
  parse var sockcall sockrc sockres
  tmp_sockets_rc = sockrc

  /*
   * The process will be cancelled only if the caller cares about the
   * return code
   */
  if max_sockets_rc <> '*' then do
     /*
      * If there is any communications problem, store message in log
      */
     if tmp_sockets_rc <> 0 then do
        upper sockfunc
        tcperr = "TCP/IP" sockfunc "error "sockrc"" sockres
        say copies("-", 70)
        say socksigl":" strip("SOURCELINE"(socksigl))
        say "TCP/IP socket error" sockrc "in line" socksigl
        say tcperr
        say copies("-", 70)
     end
     /*
      * May we continue?
      */
     if tmp_sockets_rc < 0 | tmp_sockets_rc > max_sockets_rc then do
        retcode = sockrc
        signal finish
     end
  end

 return sockres


/*--------------------------------------------------------------------*/
/* Subroutine to trap REXX error messages and exit gracefully         */
/*--------------------------------------------------------------------*/
ERROR_TRAP:

 say ""
 say ">>> Rexx error" rc "in line" sigl
 say ">>>" "SOURCELINE"(sigl)
 say ""

 if rc <> 0 then do
    retcode = rc
    if rc > 0 then say sigl':' errortext(error_rc)
    signal finish
 end

 retcode = 99
 signal finish
