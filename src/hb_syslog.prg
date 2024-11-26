/*
    hb_syslog.prg
    Released to Public Domain.
    compile: hbmk2.exe hb_syslog.prg -ohb_syslog.exe xhb.hbc -mt
    ref.: ./github/core/contrib/hbmisc/udpds.prg
*/

#include "xhb.ch"
#include "hblog.ch"
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

procedure Main()

    local nPort as numeric:=514 // Porta padrão do Syslog
    local phSocket as pointer

    if (!hb_mtvm())
        QOut("Multithread support required.")
        return
    endif

    Hb_SetCodePage("UTF8")

    QOut("Starting Log Server...")
    // Inicia o servidor
    phSocket:=hb_udpds_Start(nPort,"hb_syslog","1")
    if (phSocket==NIL)
        QOut("Error starting log server!")
        return
    endif

    QOut("Log server started on:",NetName(),":",HB_NToS(nPort))
    WAIT "Press ENTER to shut down the server..."

    hb_udpds_Stop(phSocket)

return

/* Server */
static function hb_udpds_Start(nPort as numeric,cName as character,cVersion as character)

    local phSocket as pointer

    if (!Empty(phSocket:=hb_socketOpen(NIL,HB_SOCKET_PT_DGRAM)))
        if hb_socketBind(phSocket,{HB_SOCKET_AF_INET,"0.0.0.0",nPort})
            hb_threadDetach(hb_threadStart(@UDPDS(),phSocket,cName,cVersion))
            return(phSocket)
        endif
        hb_socketClose(phSocket)
    endif

return(NIL)

static function hb_udpds_Stop(phSocket as pointer)
return(hb_socketClose(phSocket))

static procedure UDPDS(phSocket as pointer,cName as character,cVersion as character)

    local aAddr as array

    local cBuffer as character
    local cFileName as character:=(cName+".log")

    local chb_BChar0 as character:=hb_BChar(0)
    local chb_BChar5 as character:=hb_BChar(5)
    local chb_BChar6 as character:=hb_BChar(6)

    local nStyle as numeric:=(HB_LOG_ST_DATE+HB_LOG_ST_ISODATE+HB_LOG_ST_TIME+HB_LOG_ST_LEVEL)
    local nFilPrio as numeric:=HB_LOG_DEBUG
    local nFileSize as numeric:=(10*(1024^2))
    local nFileCount as numeric:=5

    local uLen as usual /*ANYTYPE*/

    INIT LOG ON FILE (nFilPrio,cFileName,nFileSize,nFileCount)
    SET LOG STYLE nStyle

    cName:=hb_StrToUTF8(cName)
    cVersion:=iif(HB_ISSTRING(cVersion),hb_StrToUTF8(cVersion),"")

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
            else
                /*
                 * LOG:
                */
                begin sequence with __BreakBlock()
                    cBuffer:=allTrim(hb_StrReplace(cBuffer,{hb_eol()=>""}))
                    LOG cBuffer PRIORITY nFilPrio
                end sequence
            endif
        endif
    end while

    CLOSE LOG

return
