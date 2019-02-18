#NoEnv
#SingleInstance Force
#Persistent
SetWorkingDir %A_ScriptDir%

if not A_IsAdmin
{
   Run *RunAs "%A_ScriptFullPath%" %1%;
   ExitApp
}

;if (A_Is64bitOS)
;   OS_is := "64-bit"
;else
;    OS_is := "32-bit, which has only a single registry view"

Gui Add, Button, x10 y10 w106 h50, 刷新

Gui Add, Button, hWndrun x382 y10 w106 h50, 运行
Gui Add, Button, hWndstop x502 y10 w106 h50, 停止

Gui Add, Button, hWndinstall x835 y10 w106 h50, 安装
Gui Add, Button, hWnduninstall x955 y10 w106 h50, 卸载

Gui Add, Text, x10 y78 w20 h20, ID:
Gui Add, Edit, hWndmyid x40 y75 w300 h20 +ReadOnly, myid
Gui Add, Text, x350 y78 w320 h20, 将左侧编辑框中的ID复制后提供给远程协助者
Gui Add, CheckBox, vMyCheckboxhost x862 y75 w60 h20 , 内网
Gui Add, CheckBox, vMyCheckboxprotocol x922 y75 w60 h20 , tcp

Gui, Add, ListView, x10 y105 w1050 h300, Name                   |Description                        |state    |StartMode    |ProcessId|PathName
ranid := RandomPass("Ww",20)
IfNotExist, %A_WorkingDir%\bin\usrid.ini
    IniWrite, %ranid%, %A_WorkingDir%\bin\usrid.ini, USER, userid
IniRead, OutputVar, %A_WorkingDir%\bin\usrid.ini, USER, userid
if OutputVar{
    GuiControl,, myid, %OutputVar%
}else{
    IniWrite, %ranid%, %A_WorkingDir%\bin\usrid.ini, USER, userid
    IniRead, OutputVar, %A_WorkingDir%\bin\usrid.ini, USER, userid
    GuiControl,, myid, %OutputVar%
}
    
check_proclist()
refresh_proclist()
Gui, Show,, 服务管理面板
Return

GuiEscape:
GuiClose:
    ExitApp

; 不要编辑这行之前的内容!

check_proclist() {
installflag = 0
for service in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Service WHERE Name='user_frpc_service'")
    installflag := 1

    
;MsgBox, %installflag%
if installflag {
    GuiControl, Enable, 运行
    GuiControl, Enable, 停止
    GuiControl, Enable, 卸载
    GuiControl, Disable, 安装
}else{
    GuiControl, Disable, 运行
    GuiControl, Disable, 停止
    GuiControl, Disable, 卸载
    GuiControl, Enable, 安装
}

}

refresh_proclist() {
LV_Delete()
;for service in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Service WHERE Name like '%user_frpc_service%'")
    ;LV_Add("", service.Name,service.Description,service.state,service.StartMode,service.ProcessId,service.PathName)

for service in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Service WHERE Name='user_frpc_service'")
    LV_Add("", service.Name,service.Description,service.state,service.StartMode,service.ProcessId,service.PathName)
    ;LV_ModifyCol()
for service in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Service WHERE Name='anydesk'")
    LV_Add("", service.Name,service.Description,service.state,service.StartMode,service.ProcessId,service.PathName)
}

install_proclist() {
Run "%A_WorkingDir%\bin\frpcservice.exe" install, %A_WorkingDir%\bin, hide,
Run "%A_WorkingDir%\bin\anydesk.exe" --install "%A_WorkingDir%\bin\anydesk" --silent, %A_WorkingDir%\bin, hide,
Run %comspec% /c "echo Pa88word | anydesk.exe --set-password", %A_WorkingDir%\bin, hide,
sleep 1000
Run %comspec% /c "sc stop anydesk", %A_WorkingDir%, hide,
Run %comspec% /c "sc config AnyDesk start= demand", %A_WorkingDir%\bin, hide,


}

uninstall_proclist() {
Run %comspec% /c "sc stop user_frpc_service", %A_WorkingDir%, hide,
Run %comspec% /c "sc stop anydesk", %A_WorkingDir%, hide,
sleep 1000
Run "%A_WorkingDir%\bin\frpcservice.exe" uninstall, %A_WorkingDir%\bin, hide,
Run %comspec% /c "anydesk --silent --remove", %A_WorkingDir%\bin, hide,
}

;生成32位UUID
GUID(){
    shellobj := ComObjCreate("Scriptlet.TypeLib")
    ret := shellobj.GUID
    uuid := RegExReplace(ret,"(\{|\}|-)","") ;去掉花括号和-
    return uuid
}

JSONPOST(url, Encoding = "",postData=""){ ;网址，编码, post JSON数据
    hObject:=ComObjCreate("WinHttp.WinHttpRequest.5.1")
    Try
    {
        hObject.Open("POST",url,False)
        hObject.SetRequestHeader("Content-Type", "application/json")
        hObject.Send(postData)
    }
    catch e
        return -1
 
    if (Encoding && hObject.ResponseBody)
    {
        oADO := ComObjCreate("adodb.stream")
        oADO.Type := 1
        oADO.Mode := 3
        oADO.Open()
        oADO.Write(hObject.ResponseBody)
        oADO.Position := 0
        oADO.Type := 2
        oADO.Charset := Encoding
        return oADO.ReadText(), oADO.Close()
    }
    return hObject.ResponseText
}

RandomPass(kind:="Wwd",length:=8){
;kind:类型 W大写 w小写 d数字 可以组合 length:长度
char := [1,2,3,4,5,6,7,8,9,"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",0,1,2,3,4,5,6,7,8,9]
char[0] := 0 ;定义数组
option := kind
kind = 0 ;必须先赋值  不然后面的加法无效
kind := InStr(option,"W",1) ? kind+100 : kind ;InStr区分大小写
kind := InStr(option,"w",1) ? kind+10 : kind
kind := InStr(option,"d") ? kind+1 : kind
;判断类型并设置随机数最小最大值
if kind=111
    min:=0,max:=61
else if kind=110
    min:=10,max:=61
else if kind=11
    min:=0,max:=35
else if kind=101
    min:=36,max:=71
else if kind=1
    min:=0,max=9
else if kind=10
    min:=10,max=35
else if kind=100
    min:=36,max=61
loop % length
{
Random, l, %min%, %max%
str .= char[l]
}
return str
}

save_frpcini(){

frphost = vpn.symid.com
frpport = 15443
frpprotocol = kcp
GuiControlGet, MyCheckboxhost
if MyCheckboxhost {
    frphost = 172.30.0.187
    frpport = 5443
}
GuiControlGet, MyCheckboxprotocol
if MyCheckboxprotocol {
    frpprotocol = tcp
}

FileDelete, %A_WorkingDir%\bin\frpc.ini
sleep 100
FileAppend, ,%A_WorkingDir%\bin\frpc.ini

IniRead, userid, %A_WorkingDir%\bin\usrid.ini, USER, userid

IniWrite, 127.0.0.1, %A_WorkingDir%\bin\frpc.ini, common, admin_addr
IniWrite, 7412, %A_WorkingDir%\bin\frpc.ini, common, admin_port
IniWrite, false, %A_WorkingDir%\bin\frpc.ini, common, login_fail_exit
IniWrite, %frphost%, %A_WorkingDir%\bin\frpc.ini, common, server_addr
IniWrite, %frpport%, %A_WorkingDir%\bin\frpc.ini, common, server_port
IniWrite, BWYJVj2HYhVtdGZL, %A_WorkingDir%\bin\frpc.ini, common, token
IniWrite, %frpprotocol%, %A_WorkingDir%\bin\frpc.ini, common, protocol

IniWrite, tcp, %A_WorkingDir%\bin\frpc.ini, %userid%-frpc-api, type
IniWrite, 127.0.0.1, %A_WorkingDir%\bin\frpc.ini, %userid%-frpc-api, local_ip
IniWrite, 7412, %A_WorkingDir%\bin\frpc.ini, %userid%-frpc-api, local_port
IniWrite, false, %A_WorkingDir%\bin\frpc.ini, %userid%-frpc-api, use_encryption
IniWrite, true, %A_WorkingDir%\bin\frpc.ini, %userid%-frpc-api, use_compression
IniWrite, 0, %A_WorkingDir%\bin\frpc.ini, %userid%-frpc-api, remote_port


IniWrite, stcp, %A_WorkingDir%\bin\frpc.ini, %userid%-anydesk, type
IniWrite, Pa88word, %A_WorkingDir%\bin\frpc.ini, %userid%-anydesk, sk
IniWrite, 127.0.0.1, %A_WorkingDir%\bin\frpc.ini, %userid%-anydesk, local_ip
IniWrite, 7070, %A_WorkingDir%\bin\frpc.ini, %userid%-anydesk, local_port
IniWrite, false, %A_WorkingDir%\bin\frpc.ini, %userid%-anydesk, use_encryption
IniWrite, true, %A_WorkingDir%\bin\frpc.ini, %userid%-anydesk, use_compression

}


Button安装:   
    ;msgbox,运行按钮。
install_proclist()
sleep 1000
check_proclist()
sleep 100
refresh_proclist()

return

Button卸载:   
    ;msgbox,运行按钮。
uninstall_proclist()
sleep 1000
check_proclist()
sleep 100
refresh_proclist()

return


Button刷新:   
    ;msgbox,运行按钮。

refresh_proclist()
sleep 200
check_proclist()
return

Button运行:   
    ;msgbox,运行按钮。
save_frpcini()
sleep 100
Run %comspec% /c "sc start user_frpc_service", %A_WorkingDir%, hide,
Run %comspec% /c "sc start anydesk", %A_WorkingDir%, hide,

sleep 2000
refresh_proclist()
return

Button停止:   
    ;msgbox,运行按钮。
Run %comspec% /c "sc stop user_frpc_service", %A_WorkingDir%, hide,
Run %comspec% /c "sc stop anydesk", %A_WorkingDir%, hide,
sleep 100
FileDelete, %A_WorkingDir%\bin\frpc.ini
sleep 2000
refresh_proclist()  
return