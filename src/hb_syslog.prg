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

procedure Main()

    local nPort:=514 // Porta padrão do Syslog
    local hSocket

    if (!hb_mtvm())
        QOut("Multithread support required.")
        return
    endif

    QOut("Starting Log Server...")
    // Inicia o servidor
    hSocket:=hb_udpds_Start(nPort,"hb_syslog","1")
    if (hSocket==NIL)
        QOut("Error starting log server!")
        return
    endif

    QOut("Log server started on:",NetName(),":",HB_NToS(nPort))
    WAIT "Press ENTER to shut down the server..."

    hb_udpds_Stop(hSocket)

return

/* Server */
static function hb_udpds_Start(nPort,cName,cVersion)

    local hSocket

    if (!Empty(hSocket:=hb_socketOpen(NIL,HB_SOCKET_PT_DGRAM)))
        if hb_socketBind(hSocket,{HB_SOCKET_AF_INET,"0.0.0.0",nPort})
            hb_threadDetach(hb_threadStart(@UDPDS(),hSocket,cName,cVersion))
            return(hSocket)
        endif
        hb_socketClose(hSocket)
    endif

return(NIL)

static function hb_udpds_Stop(hSocket)
return(hb_socketClose(hSocket))

static procedure UDPDS(hSocket,cName,cVersion)

    local cBuffer,nLen,aAddr

    local chb_BChar0:=hb_BChar(0)
    local chb_BChar5:=hb_BChar(5)
    local chb_BChar6:=hb_BChar(6)

    local nStyle:=(HB_LOG_ST_DATE+HB_LOG_ST_ISODATE+HB_LOG_ST_TIME+HB_LOG_ST_LEVEL)
    local nFilPrio:=HB_LOG_DEBUG
    local cFileName:=(cName+".log")
    local nFileSize:=(10*(1024^2))
    local nFileCount:=5

    INIT LOG ON FILE (nFilPrio,cFileName,nFileSize,nFileCount)
    SET LOG STYLE nStyle

    cName:=hb_StrToUTF8(cName)
    cVersion:=iif(HB_ISSTRING(cVersion),hb_StrToUTF8(cVersion),"")

    DO WHILE .T.
        cBuffer:=Space(2000)
        begin sequence with {|oErr|Break(oErr)}
            nLen:=hb_socketRecvFrom(hSocket,@cBuffer,NIL,NIL,@aAddr,1000)
        recover
            nLen:=NIL
        end sequence
        if (nLen==NIL)
            EXIT
        endif
        if (nLen==-1)
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
            if (hb_BLeft(cBuffer,nLen)==chb_BChar5+cName+chb_BChar0)
                begin sequence with __BreakBlock()
                    hb_socketSendTo(hSocket,chb_BChar6+cName+chb_BChar0+cVersion,NIL,NIL,aAddr)
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
