@echo off
title Ping table
setlocal enabledelayedexpansion
chcp 850>nul


REM *************************************************

REM Количество отправляемых эхо-запросов по умолчанию (максимум 20)
set default_echo_count=1

REM Название файла со списком хостов
set "file_config=%CD%\pinghosts.cfg"

REM Поиск с учетом регистра (on/off)
set sensitive_search=on

REM Режим поиска (R-регулярка, L-дословно)
set findstr_mode=L

REM for /f "tokens=1-6" %%a in ('mode con ^| find "Columns"') do set /a columns=%%b
REM if "!columns!" lss "115" mode con cols=115 lines=40

REM Размеры окна командной строки при открытии (столбцы, строки)
REM MODE 115, 30

REM *************************************************

REM Проверка существования файла с конфигом
REM Название конфига начинается также как и у батника
REM в конце приписывается "_conf.cfg"
REM Получаем название этого файла 
REM for %%a in ("%0") do set "file_name=%%~na"

REM Получаем название конфига
REM set "file_config=%CD%\!file_name!_conf.cfg"
REM set "file_config=%CD%\pinghosts.cfg"
if not exist %file_config% (
	echo Fatal Error:
	echo The configuration file was not found!
	echo.
	pause
	exit
)

set init=0

REM Проверка корректности записей (ip) в конфиге
for /f "eol=# tokens=1-3" %%a in (%file_config%) do (
	if "%%b" equ ""  call:E_parse  %%a
	set "line=%%a %%b %%c"
	
	if "%%c" neq "" (
		set /a c=%%c
		if "!c!" equ "0" call:E_parse !line!
	)

	for /f "tokens=1-4 delims=0123456789" %%a in ("%%b") do (
		set "dots=%%a%%b%%c%%d"
		set cnt=1
		for /l %%i in (1,1,3) do (
			set x=!dots:~%%i!
			if defined x set /a cnt+=1
		)
		if not !cnt! equ 3 call:E_parse !line!
	)

	for /f "tokens=1-4 delims=." %%a in ("%%b") do (
		if "%%a" equ "" call:E_parse !line!
		if "%%b" equ "" call:E_parse !line!
		if "%%c" equ "" call:E_parse !line!
		if "%%d" equ "" call:E_parse !line!
		set o1=%%a
		set o2=%%b
		set o3=%%c
		set o4=%%d
		for /l %%i in (1,1,4) do (
			if %%i equ 1 if !o%%i! equ 0 call:E_parse !line!
			set octet=!o%%i!
			set first_sym=!octet:~0,1!
			set rest_sym=!octet:~1!
			if defined rest_sym if "!first_sym!" equ "0" call:E_parse !line!
			set /a octet=!octet!
			if !octet! gtr 255 call:E_parse !line!
		)
	)
	set init=1
)
set line= &set cnt= &set dots=
set octet= &set first_sym= &set rest_sym=
set o1= &set o2= &set o3= &set o4=

goto init
:E_parse
echo Fatal Error:
echo Incorrect data in the line:    "%1  %2  %3".
echo.
pause
exit


REM ######################################## INIT
:init
if "!init!" equ "0" (
	echo Error: No data in !file_config! &echo.
	pause
	exit
)

set /a default_echo_count=!default_echo_count!
if "!default_echo_count!" equ "0" (
	set default_echo_count=4
)

if "!sensitive_search!" equ "off" (
	REM без учета регистра
	set sens_mode=/I
)

if "!findstr_mode!" neq "L" (
	if "!findstr_mode!" neq "R" (
		set findstr_mode=L
	)
)

REM ######################################## START
:start
REM set msg=
set findstr_template=
set echo_count_once=
REM set action=

set /p "cmd=command: "
if not defined cmd goto start
if "!cmd!" equ "quit" goto quit

REM Разбор введенной команды
for /f "tokens=1-3" %%a in ("!cmd!") do (
	if "%%a" equ "ping" (
		set action=!cmd!
		set cmd=ping

	) else if "%%a" equ "cls" (
		if "%%b" neq "" ( set "msg=Error: Unknown command." )

	) else 	if "%%a" equ "regexp" (
		if "%%b" equ "on" (
			set findstr_mode=R
			set "msg=Ok: Regular expression search mode is ENABLED."
		) else if "%%b" equ "off" (
			set findstr_mode=L
			set "msg=Ok: Regular expression search mode is DISABLED."
		) else if "%%b" equ "mode" (
			if "!findstr_mode!" equ "L" set "msg=Notice: Search strings literally (L)."
			if "!findstr_mode!" equ "R" set "msg=Notice: Search strings as regular expressions (R)."
		) else (
			set cmd=help_regexp
		)
	
	) else if "%%a" equ "sens" (
		if "%%b" equ "on" (
			set sens_mode=
			set "msg=Ok: Sensitive search mode ENABLED."
		) else if "%%b" equ "off" (
			set sens_mode=/I
			set "msg=Ok: Sensitive search mode DISABLED."
		) else if "%%b" equ "mode" (
			if "!sens_mode!" equ "" set "msg=Notice: Case sensitive search."
			if "!sens_mode!" equ "/I" set "msg=Notice: Case inensitive search."	
		) else (
			set cmd=help_sens
		)

	) else if "%%a" equ "count" (
		if "%%b" neq "" (
			if "%%b" equ "0" (
				set echo_count=
				set "msg=Ok: Number of echo requests reset."
			) else (
				set /a echo_count=%%b
				if "!echo_count!" equ "0" (
					set "msg=Error: Incorrect number of echo requests."
				) else (
					set "msg=Ok: Number of echo requests set !echo_count!."
					set echo_count=%%b
				)
			)
		) else (
			set cmd=help_count
		)

	) else if "%%a" equ "echo" (
		if "%%b" neq "" set findstr_template=%%b
		if "%%c" neq "" (
			set /a num=%%c
			if "!num!" equ "0" (
				set "msg=Error: The count must be a digit/number greater than zero. &echo."
			)
			if "!num!" gtr "0" set echo_count_once=!num!
			set num=
		)
		if "%%b" equ "" set cmd=help_echo

	) else if "%%a" equ "list" (
		if "%%b" neq "" set findstr_template=%%b
		if "%%b" equ "" set cmd=help_list

	) else if "%%a" equ "help" (
		set cmd=help
	) else (
		set "msg=Error: Unknown command."
	)
)

if defined msg (
	echo !msg! &echo.
	set msg=
	goto start
)

goto !cmd!

:cls
cls
goto start

REM ######################################## ECHO
:echo
for %%i in (
"+----------------------------------------------------+-----------------+-----------+-------------------+-----+"
"|                       Host                         |      IPv4       | snt - rcv | min - max - time  | TTL |"
"+----------------------------------------------------+-----------------+-----------+-------------------+-----+"
)do echo.%%~i

call:func_foo func_echo

echo +----------------------------------------------------+-----------------+-----------+-------------------+-----+
set cmd=&set host=&set ip=&set snt=&set rcv=&set ttl=
set max_time=&set min_time=&set time=&set count=&
echo.
goto start

REM ######################################## LIST
:list
for %%i in (
"+----------------------------------------------------+-----------------+-------+"
"|                       Host                         |      IPv4       | Count |"
"+----------------------------------------------------+-----------------+-------+"
)do echo.%%~i

call:func_foo func_list

echo +----------------------------------------------------+-----------------+-------+
set cmd=&set host=&set ip=&set count=&
echo.
goto start

REM ######################################## PING
:ping
!action!
set cmd=&set action
echo.
goto start

REM ######################################## CALL FOO
:func_foo:
for /f "delims=, tokens=1-9" %%a in ("!findstr_template!") do (	
	if "%%a" neq "" set x1=%%a
	if "%%b" neq "" set x2=%%b
	if "%%c" neq "" set x3=%%c
	if "%%d" neq "" set x4=%%d
	if "%%e" neq "" set x5=%%e
	if "%%f" neq "" set x6=%%e
	if "%%g" neq "" set x7=%%e
	if "%%h" neq "" set x8=%%e
	if "%%i" neq "" set x9=%%e

	for /l %%i in (1,1,9) do (
		if "!x%%i!" neq "" (
			set findstr_template=!x%%i!
			call:%1 !findstr_mode! !findstr_template! !sens_mode!
		)
	)
	
	if defined x1 set x1=
	if defined x2 set x2=
	if defined x3 set x3=
	if defined x4 set x4=
	if defined x5 set x5=
	if defined x6 set x6=
	if defined x7 set x7=
	if defined x8 set x8=
	if defined x9 set x9=
)
goto :eof

REM ######################################## CALL ECHO
:func_echo
for /f "eol=# tokens=1-3" %%a in ('findstr /%1 %3 "%2" %file_config%') do (
	set host=%%a
	set ip=%%b
	set "count=%%c"	
	
	if "!count!" equ "" set count=!default_echo_count!
	if "!echo_count!" neq "" set count=!echo_count!
	if "!echo_count_once!" neq "" set count=!echo_count_once!
	if !count! gtr 20 set count=20		

	set ttl=0
	set /a time=0
	set min_time=0
	set max_time=0
	set /a snt=!count!
	set /a rcv=0

	for /f "tokens=1-6" %%a in ('ping -n !count! !ip! ^| find /I "TTL="') do (
		REM Получаем TTL и rcv (количество полученных ответов)
		set x=%%f
		set x=!x:~4!
		set ttl=!x!
		set /a rcv+=1

		REM Получаем время (общее, максимальное, минимальное)
		set x=%%e
		set x=!x:~5,-2!
		if !min_time! equ 0 set min_time=!x!
		if !max_time! equ 0 set max_time=!x!
		if !x! lss !min_time! set min_time=!x!
		if !x! geq !max_time! set max_time=!x!
		set /a time+=!x!
	)
	REM Получаем среднее время
	set /a time=!time!/!count!

	REM Убираем лишние символы или добавляем пробелы (чтобы таблица не поплыла)
	for /l %%i in (1,1,8) do (
		if %%i equ 1 set /a max_length=50 &set cell=!host!
		if %%i equ 2 set /a max_length=15 &set cell=!ip!
		if %%i equ 3 set /a max_length=5  &set cell=!time!
		if %%i equ 4 set /a max_length=4  &set cell=!min_time!
		if %%i equ 5 set /a max_length=4  &set cell=!max_time!
		if %%i equ 6 set /a max_length=3  &set cell=!snt!
		if %%i equ 7 set /a max_length=3  &set cell=!rcv!
		if %%i equ 8 set /a max_length=3  &set cell=!ttl!
		
		REM Убираем лишние символы (если > max_length)
		for /l %%i in (0,1,!max_length!) do (
			set x=!cell:~%%i!
			if defined x set /a sym+=1
			if %%i equ !max_length! (
				set cell=!cell:~0,%%i!
			)
		)

		REM Добавляем пробелы (если нужно)
		set /a "rest_sym=!max_length!-!sym!"
		set space=_
		for /l %%i in (1,1,!rest_sym!) do (set space=!space!_)
		set "space=!space:_= !"
		set cell=!cell!!space!
		set sym=
		set rest_sym=
		set space=

		if %%i equ 1 set host=!cell!
		if %%i equ 2 set ip=!cell!
		if %%i equ 3 set time=!cell!
		if %%i equ 4 set min_time=!cell!
		if %%i equ 5 set max_time=!cell!
		if %%i equ 6 set snt=!cell!
		if %%i equ 7 set rcv=!cell!
		if %%i equ 8 set ttl=!cell!
		set cell=
		set max_length=
	)
	echo ^| !host!^| !ip!^| !snt!  !rcv!^| !min_time! !max_time! !time!^| !ttl!^|
)
goto :eof

REM ######################################## CALL LIST
:func_list
for /f "eol=# tokens=1-3" %%a in ('findstr /%1 %3 "%2" %file_config%') do (
	set host=%%a
	set ip=%%b

	if "%%c" neq "" (
		set count=%%c
	) else (
		set count=!default_echo_count!
	)

	if !count! gtr 20 set count=20
	
	REM Убираем лишние символы или добавляем пробелы (чтобы таблица не поплыла)
	for /l %%i in (1,1,3) do (
		if %%i equ 1 set /a max_length=50 &set cell=!host!
		if %%i equ 2 set /a max_length=15 &set cell=!ip!
		if %%i equ 3 set /a max_length=2  &set cell=!count!
	
		REM Убираем лишние символы (если > max_length)
		for /l %%i in (0,1,!max_length!) do (
			set x=!cell:~%%i!
			if defined x set /a sym+=1
			if %%i equ !max_length! (
				set cell=!cell:~0,%%i!
			)
		)

		REM Добавляем пробелы (если нужно)
		set /a "rest_sym=!max_length!-!sym!"
		set space=_
		for /l %%i in (1,1,!rest_sym!) do (set space=!space!_)
		set "space=!space:_= !"
		set cell=!cell!!space!
	
		if %%i equ 1 set host=!cell!
		if %%i equ 2 set ip=!cell!
		if %%i equ 3 set count=!cell!

		set sym=
		set rest_sym=
		set space=
		set cell=
		set max_length=
	)
	echo ^| !host!^| !ip!^|  !count!  ^|
)
goto :eof

REM ######################################## HELP
:help
:help_echo
for %%i in (
""
"    echo [exp,exp,...] [count] - host availability check."
""
"          exp         Literally/regular expression or IP address"
"                      for search in file config (max 9 expression)."
"          count       One-time number of echo requests to send"
)do echo.%%~i
echo.
if "!cmd!" equ "help_echo" set cmd=&goto start

:help_list
for %%i in (
""
"    list [exp,exp,...] - show list of hosts."
""
"          exp         Literally/regular expression or IP address"
"                      for search in file config (max 9 expression)."
)do echo.%%~i
echo.
if "!cmd!" equ "help_list" set cmd=&goto start

:help_regexp
for %%i in (
""
"    regexp on         Enable regular expression search mode."
"    regexp off        Disable regular expression search mode."
"    regexp mode       Show search mode."
)do echo.%%~i
echo.
if "!cmd!" equ "help_regexp" set cmd=&goto start

:help_sens
for %%i in (
""
"    sens on           Enable case insensitive search mode."
"    sens off          Disable case insensitive search mode."
"    sens mode         Show sens mode."
)do echo.%%~i
echo.
if "!cmd!" equ "help_sens" set cmd=&goto start

:help_count
for %%i in (
""
"    count <number>    Number of echo requests to send in current session"
"                      (the number must be a digit greater than zero)."
"    count 0           Reset number of echo requests."
""
)do echo.%%~i
if "!cmd!" equ "help_count" set cmd=&goto start
echo.

for %%i in (
"    cls               Clears the screen."
""
"    quit              quit/exit."
""
"    ping [...]        launch standart ping utility"
""
)do echo.%%~i
set cmd=&goto start

REM ######################################## QUIT
:quit
exit /b /0
