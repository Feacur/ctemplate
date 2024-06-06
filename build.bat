
@echo off
setlocal
cd /d "%~dp0"
chcp 65001 > nul

rem unpack arguments
for %%a in (%*) do (
	for /f "tokens=1,2 delims=:" %%b IN ("%%a") do (
		if [%%c] == [] (set %%b=true) else (set %%b=%%c)
	)
)

rem prepare flags
if [%toolset%]  == [] set toolset=clang
if [%CRT%]      == [] set CRT=static
if [%type%]     == [] set type=windows
if [%optimize%] == [] set optimize=release
if [%arch%]     == [] set arch=64
if [%WAE%]      == [] set WAE=false

set root=%cd%
set code=%root%/code
set data=%root%/data

rem prepare directories
if not exist "build" mkdir "build"
pushd "build"
	if not exist "temp" mkdir "temp"
popd

if "%clean%" == "true" (
	del "build\temp\*" /s /q > nul
)

rem build
call :build_%toolset%

endlocal

rem declare functions
goto :eof

:build_clang
	rem refer to `code/_project.h` for additional info

	where -q "clang.exe" || (
		set "PATH=%PATH%;C:/Program Files/LLVM/bin/"
		where -q "clang.exe" || (
			echo.please, install "Clang", https://github.com/llvm/llvm-project/releases
			exit /b 1
		)
	)

	echo.[compile data]
	pushd "build/temp"
		set resource=-nologo
		call llvm-rc %resource% "%data%/main.rc" -fo "main.res" || exit /b 1
	popd

	echo.[compile code]
	pushd "build/temp"
		rem https://clang.llvm.org/docs/CommandGuide/clang.html
		rem https://gcc.gnu.org/onlinedocs/

		set compiler=-std=c99 -fno-exceptions -fno-rtti
		set compiler=%compiler% -ffp-contract=off
		set compiler=%compiler% -flto=thin
		set compiler=%compiler% ^
			-I"%code%" ^
			-I"%data%"
		if "%type%" == "console" set compiler=%compiler% -DBUILD_TYPE=BUILD_TYPE_CONSOLE
		if "%type%" == "windows" set compiler=%compiler% -DBUILD_TYPE=BUILD_TYPE_WINDOWS
		if "%type%" == "dynamic" set compiler=%compiler% -DBUILD_TYPE=BUILD_TYPE_DYNAMIC
		if "%optimize%" == "inspect" set compiler=%compiler% -O0 -g -DBUILD_OPT=BUILD_OPT_INSPECT
		if "%optimize%" == "develop" set compiler=%compiler% -Og -g -DBUILD_OPT=BUILD_OPT_DEVELOP
		if "%optimize%" == "release" set compiler=%compiler% -O2    -DBUILD_OPT=BUILD_OPT_RELEASE
		if "%arch%" == "32" set compiler=%compiler% -m32
		if "%arch%" == "64" set compiler=%compiler% -m64
		if not "%WAE%" == "false" set compiler=%compiler% -Werror -Wall
		call clang -c %compiler% "%code%/main.c" -o "main.o" || exit /b 1
	popd

	echo.[link objects]
	pushd "build"
		rem https://learn.microsoft.com/cpp/build/reference/linker-options
		rem https://learn.microsoft.com/cpp/c-runtime-library/crt-library-features

		set linker=-nologo -incremental:no -noimplib
		if "%CRT%" == "static"  set linker=%linker% -nodefaultlib libucrt.lib libvcruntime.lib libcmt.lib
		if "%CRT%" == "dynamic" set linker=%linker% -nodefaultlib    ucrt.lib    vcruntime.lib msvcrt.lib
		set linker=%linker% kernel32.lib user32.lib
		if "%type%" == "console" set linker=%linker% -subsystem:console
		if "%type%" == "windows" set linker=%linker% -subsystem:windows
		if "%type%" == "dynamic" set linker=%linker% -dll
		if "%optimize%" == "inspect" set linker=%linker% -debug:full
		if "%optimize%" == "develop" set linker=%linker% -debug:full
		if "%optimize%" == "release" set linker=%linker% -debug:none
		if "%arch%" == "32" set linker=%linker% -machine:x86
		if "%arch%" == "64" set linker=%linker% -machine:x64
		if not "%WAE%" == "false" set linker=%linker% -WX
		call lld-link %linker% ^
			"temp/main.o" "temp/main.res" ^
			-out:"main.exe" || exit /b 1
	popd
goto :eof
