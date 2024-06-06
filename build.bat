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
if [%toolset%]   == [] set toolset=clang
if [%target%]    == [] set target=main.exe
if [%CRT%]       == [] set CRT=static
if [%subsystem%] == [] set subsystem=windows
if [%optimize%]  == [] set optimize=release
if [%WAE%]       == [] set WAE=0

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
		where -q "clang.exe" || (
			echo.please, install "Clang", github.com/llvm/llvm-project/releases
			exit /b 1
		)
	)

	rem refer to `code/utils/_project.h` for additional info
	echo.[compile data]
	pushd "build/temp"
		set resource=-nologo
		set resource=%resource% -fo "main.res" "%root%/data/main.rc"
		call llvm-rc %resource% || exit /b 1
	popd

	echo.[compile code]
	pushd "build/temp"
		set compiler=-std=c99 -fno-exceptions -fno-rtti
		set compiler=%compiler% -ffp-contract=off
		set compiler=%compiler% -flto=thin
		set compiler=%compiler% -I"%root%/code" -I"%root%/code/third_party"
		if "%subsystem%" == "console" set compiler=%compiler% -DBUILD_SUBSYSTEM=BUILD_SUBSYSTEM_CONSOLE
		if "%subsystem%" == "windows" set compiler=%compiler% -DBUILD_SUBSYSTEM=BUILD_SUBSYSTEM_WINDOWS
		if "%optimize%" == "inspect" set compiler=%compiler% -O0 -g -DBUILD_OPTIMIZE=BUILD_OPTIMIZE_INSPECT
		if "%optimize%" == "develop" set compiler=%compiler% -Og -g -DBUILD_OPTIMIZE=BUILD_OPTIMIZE_DEVELOP
		if "%optimize%" == "release" set compiler=%compiler% -O2    -DBUILD_OPTIMIZE=BUILD_OPTIMIZE_RELEASE
		if "%WAE%" == "1" set compiler=%compiler% -Werror -Wall
		call clang -c %compiler% "%root%/code/main.c" -o "main.o" || exit /b 1
	popd

	echo.[link objects]
	pushd "build"
		set linker=-nologo -machine:x64 -incremental:no -noimplib
		if "%CRT%" == "static"  set linker=%linker% -nodefaultlib libucrt.lib libvcruntime.lib libcmt.lib
		if "%CRT%" == "dynamic" set linker=%linker% -nodefaultlib    ucrt.lib    vcruntime.lib msvcrt.lib
		set linker=%linker% kernel32.lib user32.lib
		if "%subsystem%" == "console" set linker=%linker% -subsystem:console
		if "%subsystem%" == "windows" set linker=%linker% -subsystem:windows
		if "%optimize%" == "inspect" set linker=%linker% -debug:full
		if "%optimize%" == "develop" set linker=%linker% -debug:full
		if "%optimize%" == "release" set linker=%linker% -debug:none
		if "%WAE%" == "1" set linker=%linker% -WX
		call lld-link %linker% ^
			"temp/main.o" "temp/main.res" ^
			-out:"%target%" || exit /b 1
	popd
goto :eof
