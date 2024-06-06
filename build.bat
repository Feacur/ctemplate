@echo off
setlocal
cd /d "%~dp0"
chcp 65001 > nul

rem unpack arguments
for %%a in (%*) do (
	for /f "tokens=1,2 delims=:" %%b IN ("%%a") do (
		if [%%c] == [] (set %%b=1) else (set %%b=%%c)
	)
)

rem prepare
if [%toolset%] == [] set toolset=clang
if [%target%]  == [] set target=main.exe
if [%console%] == [] set console=0
if [%debug%]   == [] set debug=0
if [%WAE%]     == [] set WAE=0

set root=%cd%

if not exist "build" mkdir "build"
pushd "build"
	if not exist "temp" mkdir "temp"
popd

rem build
call :build_%toolset%

endlocal

rem declare functions
goto :eof

:build_clang
	where -q "clang.exe" || (
		set "PATH=%PATH%;C:/Program Files/LLVM/bin/"
		where -q "clang.exe" || exit /b 1
	)

	echo.[compile data]
	pushd "build/temp"
		set resource=-nologo
		set resource=%resource% -fo "main.res" "%root%/data/main.rc"
		call llvm-rc %resource% || exit /b 1
	popd

	echo.[compile code]
	pushd "build/temp"
		set compiler=-std=c99 -fno-exceptions -fno-rtti
		set compiler=%compiler% -I"%root%/code" -I"%root%/code/third_party"
		if "%console%" == "1" (set compiler=%compiler% -DBUILD_CONSOLE=1) else (set compiler=%compiler% -DBUILD_CONSOLE=0)
		if "%debug%"   == "1" (set compiler=%compiler% -O0 -g)            else (set compiler=%compiler% -O2)
		if "%debug%"   == "1" (set compiler=%compiler% -DBUILD_DEBUG=1)   else (set compiler=%compiler% -DBUILD_DEBUG=0)
		if "%WAE%"     == "1" (set compiler=%compiler% -Werror -Wall)
		call clang -c %compiler% "%root%/code/main.c" -o "main.o" || exit /b 1
	popd

	echo.[link objects]
	pushd "build"
		set linker=-nologo -machine:x64 -incremental:no -noimplib
		set linker=%linker% -nodefaultlib libucrt.lib libvcruntime.lib libcmt.lib
		set linker=%linker% kernel32.lib user32.lib
		if "%console%" == "1" (set linker=%linker% -subsystem:console) else (set linker=%linker% -subsystem:windows)
		if "%debug%"   == "1" (set linker=%linker% -debug:full)        else (set linker=%linker% -debug:none)
		if "%WAE%"     == "1" (set linker=%linker% -WX)
		call lld-link %linker% ^
			"temp/main.o" "temp/main.res" ^
			-out:"%target%" || exit /b 1
	popd
goto :eof
