/*

 _      _                          _
| |__  | |__      ___  _   _  ___ | |  ___    __ _     _ __   _ __   __ _
| '_ \ | '_ \    / __|| | | |/ __|| | / _ \  / _` |   | '_ \ | '__| / _` |
| | | || |_) |   \__ \| |_| |\__ \| || (_) || (_| | _ | |_) || |   | (_| |
|_| |_||_.__/    |___/ \__, ||___/|_| \___/  \__, |(_)| .__/ |_|    \__, |
                       |___/                 |___/    |_|           |___/

    hb_syslog.prg: Released to Public Domain.
    --------------------------------------------------------------------------------------
    ref.: ./github/harbour-core/contrib/xhb/hblog.ch
          ./github/harbour-core/contrib/xhb/hblog.prg
          ./github/harbour-core/contrib/xhb/hblognet.prg
    --------------------------------------------------------------------------------------
    compile: ~/naldodj-hb/bin/cygwin/gcc/hbmk2.exe hb_syslog.prg -ohb_syslog.exe xhb.hbc -mt -compr=max
    --------------------------------------------------------------------------------------
    ref.: ./github/core/contrib/hbmisc/udpds.prg
    --------------------------------------------------------------------------------------
    TODO:
        +Install as service ref.: c:\github\core\contrib\hbnetio\utils\hbnetio\_winsvc.prg
        +.ini configuration
        +IPV6 Suport
        +Other Log Types: FILE*,CONSOLE,MONITOR,SYSLOG,EMAIL,DEBUG,DBF
            ref.: F:\cygwin64\home\marin\naldodj-hb\contrib\xhb\hblog.ch
                  F:\cygwin64\home\marin\naldodj-hb\contrib\xhb\hblog.prg
                  F:\cygwin64\home\marin\naldodj-hb\contrib\xhb\hblognet.prg
    --------------------------------------------------------------------------------------

*/

#include "std.ch"
#include "inkey.ch"

#include "xhb.ch"

#include "hbver.ch"
#include "hblog.ch"
#include "hbinkey.ch"
#include "hbcompat.ch"
#include "hbsocket.ch"

#require "xhb"
#require "hbmisc"

/* Keeping it tidy */
#pragma -w3
#pragma -es2

/* Optimizations */
#pragma -km+
#pragma -ko+

REQUEST HB_MT
REQUEST HB_CODEPAGE_UTF8EX

procedure Main(...)

    local aArgs as array:=hb_AParams()

    local cAddr as character
    local cName as character
    local cVersion as character
    local cParam as character
    local cArgName as character

    local idx as numeric
    local nKey as numeric
    local nPort as numeric
    local nFileSize as numeric
    local nFileSizeType as numeric
    local nAddrFamily as numeric

    local phSocket as pointer

    if (!hb_mtvm())
        QOut("Multithread support required.")
        return
    endif

    hb_setCodePage("UTF8")
    hb_cdpSelect("UTF8EX")

    if (;
         (Empty(aArgs));
         .or.;
         Lower(aArgs[1])=="-h";
         .or.;
         Lower(aArgs[1])=="--help";
    )
      ShowHelp(nil,aArgs)
      return
    endif

    for each cParam in aArgs

      if (!Empty(cParam))

         if ((idx:=At("=",cParam))==0)
            cArgName:=Lower(cParam)
            cParam:=""
         else
            cArgName:=Left(cParam,idx-1)
            cParam:=SubStr(cParam,idx+1)
         endif

         do case
            case (cArgName=="-n")
               cName:=cParam
            case (cArgName=="-p")
               nPort:=val(cParam)
            case (cArgName=="-v")
               cVersion:=cParam
            case (cArgName=="-s")
               nFileSize:=val(cParam)
            case (cArgName=="-st")
               nFileSizeType:=val(cParam)
            otherwise
               ShowHelp("Unrecognized option:"+cArgName+iif(Len(cParam)>0,"="+cParam,""))
               return
         endcase
      endif
    next each

    hb_default(@cName,"hb_syslog")
    hb_default(@cVersion,"1")
    hb_default(@nPort,514)// Porta padrão do Syslog
    hb_default(@nFileSize,1)
    hb_default(@nFileSizeType,2)

    QOut("Starting Log Server...")
    // Inicia o servidor
    nAddrFamily:=HB_SOCKET_AF_INET
    cAddr:="0.0.0.0"
    phSocket:=hb_udpds_Start(cName,cVersion,nAddrFamily,cAddr,nPort,nFileSize,nFileSizeType)
    if (phSocket==NIL)
        QOut("Error starting log server!")
        return
    endif

    QOut("Log server ["+cName+"] started on:",NetName(),":",hb_NToS(nPort))

    QOut("Press <CTRL+Q> to shut down the server...")

    while (.T.)
        nKey:=Inkey(0.1,hb_bitOr(INKEY_ALL,HB_INKEY_GTEVENT))
        if (nKey==HB_K_CTRL_Q)
            exit
        endif
        hb_idleSleep(0.1)
    end while

    hb_udpds_Stop(phSocket,nAddrFamily,cAddr,nPort)

    return

/* Server */
static function hb_udpds_Start(cName as character,cVersion as character,nAddrFamily as numeric,cAddr as character,nPort as numeric,nFileSize as numeric,nFileSizeType as numeric)

    local phSocket as pointer

    if (!Empty(phSocket:=hb_socketOpen(NIL,HB_SOCKET_PT_DGRAM)))
        if (hb_socketBind(phSocket,{nAddrFamily,cAddr,nPort}))
            hb_threadDetach(hb_threadStart(@UDPDS(),phSocket,cName,cVersion,nFileSize,nFileSizeType))
            return(phSocket)
        endif
        hb_socketClose(phSocket)
    endif

    return(NIL)

static function hb_udpds_Stop(phSocket as pointer,nAddrFamily as numeric,cAddr as character,nPort as numeric)
    hb_socketSendTo(phSocket,"_E_X_I_T_",NIL,NIL,{nAddrFamily,cAddr,nPort})
    hb_idleSleep(0.5)
    return(hb_socketClose(phSocket))

static procedure UDPDS(phSocket as pointer,cName as character,cVersion as character,nFileSize as numeric,nFileSizeType as numeric)

    local aAddr as array

    local cBuffer as character
    local cFileName as character:=(cName+".log")

    local chb_BChar0 as character:=hb_BChar(0)
    local chb_BChar5 as character:=hb_BChar(5)
    local chb_BChar6 as character:=hb_BChar(6)

    local nKoef as numeric
    local nStyle as numeric:=(HB_LOG_ST_DATE+HB_LOG_ST_ISODATE+HB_LOG_ST_TIME+HB_LOG_ST_LEVEL)
    local nSeverity as numeric:=HB_LOG_DEBUG
    local nFileCount as numeric:=5

    local uLen as usual /*ANYTYPE*/

    nKoef:=if((nFileSizeType==1),1,if((nFileSizeType==2),1024,(1024^2)))
    nFileSize:=(nFileSize*nKoef)

    INIT LOG ON FILE (nSeverity,cFileName,nFileSize,nFileCount)
    SET LOG STYLE (nStyle)

    cName:=hb_StrToUTF8(cName)
    cVersion:=iif(hb_IsString(cVersion),hb_StrToUTF8(cVersion),"")

    while (.T.)
        cBuffer:=Space(2000)
        begin sequence with {|oErr|Break(oErr)}
            uLen:=hb_socketRecvFrom(phSocket,@cBuffer,NIL,NIL,@aAddr,1000)
        recover
            uLen:=NIL
        end sequence
        if (uLen==NIL)
            EXIT
        endif
        if (uLen==-1)
            if (hb_socketGetError()!=HB_SOCKET_ERR_TIMEOUT)
                CLOSE LOG
                return
            endif
        else
            /*
              * Communication protocol:
              *   Broadcast request: ENQ,ServerName,NUL
              *   Server response: ACK,ServerName,NUL,Version
              */
            if (hb_BLeft(cBuffer,uLen)==chb_BChar5+cName+chb_BChar0)
                begin sequence with __BreakBlock()
                    hb_socketSendTo(phSocket,chb_BChar6+cName+chb_BChar0+cVersion,NIL,NIL,aAddr)
                end sequence
            elseif (Left(cBuffer,9)=="_E_X_I_T_")
                EXIT
            else
                /*
                 * LOG:
                */
                nSeverity:=getSeverity(@cBuffer,nSeverity)
                begin sequence with __BreakBlock()
                    cBuffer:=allTrim(hb_StrReplace(cBuffer,{hb_eol()=>""}))
                    LOG cBuffer PRIORITY nSeverity
                end sequence
            endif
        endif
    end while

    CLOSE LOG

    return

static function getSeverity(cBuffer as character,nDefaultSeverity as numeric)

    local cPriority as character

    local nAT,nPriority,nFacility,nSeverity as numeric

    if ("<"$Left(cBuffer,1))
        nAT:=AT(">",cBuffer)
        cPriority:=SubStr(cBuffer,2,nAT-2)
        nAT+=1
        /*PRI = (Facility * 8) + Severity*/
        nPriority:=Val(cPriority)
        /*
            Facility    Valor   Significado
            kern        0       Kernel messages
            user        1       User-level messages
            mail        2       Mail system
            daemon      3       System daemons
            auth        4       Security/authorization
            syslog      5       Syslog messages
            lpr         6       Print system
            news        7       Network news subsystem
            local0      16      Local use 0 (default)
            local1      17      Local use 1
            local2      18      Local use 2
            local3      19      Local use 3
            local4      20      Local use 4
            local5      21      Local use 5
            local6      22      Local use 6
            local7      23      Local use 7
            ---------------------------------------
            Facility = PRI // 8
            Facility = 134 // 8 = 16
        */
        nFacility:=Int(nPriority/8)
        HB_SYMBOL_UNUSED(nFacility)
        /*----------------------------------
            Severity = PRI % 8
            Severity = 134 % 8 = 6
        */
        nSeverity:=Int(nPriority%8)
        switch (nSeverity)
        case 0 //Emerg
        case 1 //Alert
        case 2 //Crit
            if (nSeverity==0)
                cBuffer:=Stuff(cBuffer,nAT,0,"/<Emerg> ")
            elseif (nSeverity==1)
                cBuffer:=Stuff(cBuffer,nAT,0,"/<Alert> ")
            else
                cBuffer:=Stuff(cBuffer,nAT,0,"/<Crit> ")
            endif
            nSeverity:=HB_LOG_CRITICAL
            exit
        case 3 //Err
            nSeverity:=HB_LOG_ERROR
            exit
        case 4 //Warning
            nSeverity:=HB_LOG_WARNING
            exit
        case 5 //Notice
        case 6 //Info
            if (nSeverity==5)
                cBuffer:=Stuff(cBuffer,nAT,0,"/<Notice> ")
            else
                cBuffer:=Stuff(cBuffer,nAT,0,"/<Info> ")
            endif
            nSeverity:=HB_LOG_INFO
            exit
        case 7 //Debug
            cBuffer:=Stuff(cBuffer,nAT,0,"/<Debug> ")
            nSeverity:=HB_LOG_DEBUG
            exit
        otherwise
            nSeverity:=nDefaultSeverity
        endswitch
    else
        nSeverity:=nDefaultSeverity
    endif

return(nSeverity) as numeric

static procedure ShowSubHelp(xLine as anytype,/*@*/nMode as numeric,nIndent as numeric,n as numeric)

   DO CASE
      CASE xLine == NIL
      CASE hb_IsNumeric( xLine )
         nMode := xLine
      CASE hb_IsEvalItem( xLine )
         Eval( xLine )
      CASE hb_IsArray( xLine )
         IF nMode == 2
            OutStd( Space( nIndent ) + Space( 2 ) )
         ENDIF
         AEval( xLine, {| x, n | ShowSubHelp( x, @nMode, nIndent + 2, n ) } )
         IF nMode == 2
            OutStd( hb_eol() )
         ENDIF
      OTHERWISE
         DO CASE
            CASE nMode == 1 ; OutStd( Space( nIndent ) + xLine + hb_eol() )
            CASE nMode == 2 ; OutStd( iif( n > 1, ", ", "" ) + xLine )
            OTHERWISE       ; OutStd( "(" + hb_ntos( nMode ) + ") " + xLine + hb_eol() )
         ENDCASE
   ENDCASE

   RETURN

static function HBRawVersion()
   return(;
       hb_StrFormat( "%d.%d.%d%s (%s) (%s)";
      ,hb_Version(HB_VERSION_MAJOR);
      ,hb_Version(HB_VERSION_MINOR);
      ,hb_Version(HB_VERSION_RELEASE);
      ,hb_Version(HB_VERSION_STATUS);
      ,hb_Version(HB_VERSION_ID);
      ,"20"+Transform(hb_Version(HB_VERSION_REVISION),"99-99-99 99:99"));
   ) as character

static procedure ShowHelp(cExtraMessage as character,aArgs as array)

   local aHelp as array
   local nMode as numeric:=1

   if (Empty(aArgs).or.(Len(aArgs)<=1).or.(Empty(aArgs[1])))
      aHelp:={;
         cExtraMessage;
         ,"hb_syslog ("+hb_ProgName()+") "+HBRawVersion();
         ,"Copyright (c) 2024-"+hb_NToS(Year(Date()))+", "+hb_Version(HB_VERSION_URL_BASE);
         ,"";
         ,"Syntax:";
         ,"";
         ,{hb_ProgName()+" [options]"};
         ,"";
         ,"Options:";
         ,{;
              "-h or --help Show this help screen";
             ,"-n=<name>    Specify the name of the server (default: hb_syslog)";
             ,"-p=<port>    Specify the port number (default: 514)";
             ,"-v=<version> Specify the server version (default: 1)";
             ,"-s=<log file size> Specify the log file size (default: 1)";
             ,"-st=<log file size type> Specify the log file size type: 1=Bytes, 2=MegaBytes, 3=GigaBytes (default: 2).";
         };
         ,"";
      }
   else
      ShowHelp("Unrecognized help option")
      return
   endif

   /* using hbmk2 style */
   aEval(aHelp,{|x|ShowSubHelp(x,@nMode,0)})

   return
