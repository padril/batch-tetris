rem Copyright (C) 2023 Leo Peckham


@echo off
cls
setlocal enabledelayedexpansion




rem =========
rem CONSTANTS
rem =========




rem Delaytime
rem the higher the delay constant, the longer, but more accurate the delay
rem calculation will be
set delay_constant=10
set /a delay_constant_50=%delay_constant%+50

echo Getting information about your terminal's speed...
for %%t in (25 %delay_constant% %delay_constant_50%) do (
    call :get_time time1
    call :delay_ %%t
    call :get_time time2
    call :time_dif return[%%t] !time1! !time2!
)

set /a delay_per50=!return[%delay_constant_50%]!-!return[%delay_constant%]!
set /a const_delay=!delay_per50!/2
set /a const_delay=!return[25]!-!const_delay!

call :get_time time1
call :delay_ 50
call :get_time time2
call :time_dif return !time1! !time2!
set /a predicted=!delay_per50!+!const_delay!
echo Predicted delay: !predicted!0ms, Actual delay: !return!0ms

call :get_time time1
call :delay 300
call :get_time time2
call :time_dif return !time1! !time2!
echo Desired delay: 3000ms, Actual delay : !return!0ms



rem Util
set /a true=1
set /a false=0


rem ANSI
for /f %%a in ('echo prompt $E ^| cmd') do set "ANSI=%%a["
set /a RED=41
set /a BLACK=40


rem Game constants, subtracting 1 to better use 0 indexed ranges
set /a GAME_HEIGHT=15 - 1
set /a GAME_WIDTH=20 - 1
for /l %%y in ( 0 1 %GAME_HEIGHT% ) do (
    for /l %%x in ( 0 1 %GAME_WIDTH% ) do (
        set GAME_BOARD[%%y][%%x]=%BLACK%
    )
)


rem Lists suck in batch, but this is a way to do them
rem Each of these is a ANSI color array representing a tetronimo

rem LBLOCK
set /a LBLOCK_WIDTH=2 - 1
set /a LBLOCK_HEIGHT=3 - 1
set x=0
set y=0
for %%n in ( %BLACK% %RED% %BLACK% %RED% %RED% %RED% ) do (
    set LBLOCK[!y!][!x!]=%%n
    if !x! equ %LBLOCK_WIDTH% (
        set /a y=!y!+1
        set /a x=0
    ) else (
        set /a x= !x! + 1
    )
)




rem ====
rem GAME
rem ====


rem Initialization stuff, TODO(padril): move to an init function
echo %ANSI%?25l
echo %ANSI%0m

rem Initial block position
set /a block_x=%GAME_WIDTH%/2
set /a block_y=0


rem Initial display
call :display_block LBLOCK !block_x! !block_y!
call :draw_board


rem Game loop
for /l %%T in ( 0 1 100 ) do (
    call :get_time time1
    call :get_input key_pressed
    call :get_time time2

    if !key_pressed! equ A (
        call :clear_block LBLOCK !block_x! !block_y!
        set /a block_x=!block_x!-1
        call :display_block LBLOCK !block_x! !block_y!
        call :draw_board
        call :time_dif dif !time1! !time2!
        set /a dif=100-!dif!
        call :delay !dif!
    )
    if !key_pressed! equ D (
        call :clear_block LBLOCK !block_x! !block_y!
        set /a block_x=!block_x!+1
        call :display_block LBLOCK !block_x! !block_y!
        call :draw_board
        call :time_dif dif !time1! !time2!
        set /a dif=100-!dif!
        call :delay !dif!
    )

    rem clear before we check collision
    call :clear_block LBLOCK !block_x! !block_y!

    rem move pos down, and check collision with hypothetical position
    set /a block_y=!block_y!+1
    call :check_colision return LBLOCK !block_x! !block_y!

    rem there was a collision!
    if !return! equ %false% (
        rem halt the tetronimo
        set /a block_y=!block_y!-1
        call :display_block LBLOCK !block_x! !block_y!

        rem spawn a new one
        set /a block_x=5
        set /a block_y=0
        call :display_block LBLOCK !block_x! !block_y!
    rem just move down
    ) else (
        call :display_block LBLOCK !block_x! !block_y!
        call :draw_board
    )
)


goto :cleanup




rem ==============
rem UTIL FUNCTIONS
rem ==============

rem params - return, time1, time2
:time_dif
    set /a %~1=%~3-%~2
    if !%~1! lss 0 (
        set /a %~1=6000+%~1
    )
    exit /b 0

rem params - return
:get_time
    for /f "tokens=4 delims=:" %%i in ('echo.^|time') do set "%~1=%%i"
    rem weird subtraction thing to get around octal problems
    set /a %~1=1!%~1:,=!
    exit /b 0


rem param - time in centiseconds (0.01 seconds)
:delay
    set /a number_of_iterations=%~1-!const_delay!
    set /a number_of_iterations=!number_of_iterations!*50
    set /a number_of_iterations=!number_of_iterations!/!delay_per50!
    call :delay_ !number_of_iterations!
    exit /b 0


rem param - iterations
:delay_
    for /l %%i in ( 0 1 %~1 ) do (
        ping localhost -n 1 >nul
    )
    exit /b 0


rem params - var, "!var!"
:recurse
    set %~1=%~2
    exit /b 0




rem ==============
rem GAME FUNCTIONS
rem ==============


rem param - return
:get_input
    for /f "delims=" %%A in ('choice /c ASD /n /t 1 /d s') do set "%~1=%%A" 
    exit /b 0


:draw_board
    for /l %%y in ( 0 1 %GAME_HEIGHT% ) do (
        for /l %%x in ( 0 1 %GAME_WIDTH% ) do (
            echo %ANSI%%%y;%%xH%ANSI%8;!GAME_BOARD[%%y][%%x]!m#
        )
    )
    exit /b 0


rem params - block_name, xpos, ypos
:display_block
    for /l %%y in (0 1 !%~1_HEIGHT!) do (
        for /l %%x in (0 1 !%~1_WIDTH!) do (
            set /a x_pos=%%x+%~2
            set /a y_pos=%%y+%~3
            set color_=!%~1[%%y][%%x]!
            if !color_! neq %BLACK% (
                set GAME_BOARD[!y_pos!][!x_pos!]=!color_!
            )
        )
    )
    exit /b 0


rem params - block_name, xpos, ypos
:clear_block
    for /l %%y in (0 1 !%~1_HEIGHT!) do (
        for /l %%x in (0 1 !%~1_WIDTH!) do (
            set /a x_pos=%%x+%~2
            set /a y_pos=%%y+%~3
            set color_=!%~1[%%y][%%x]!
            if !color_! neq %BLACK% (
                set GAME_BOARD[!y_pos!][!x_pos!]=%BLACK%
            )
        )
    )
    exit /b 0


rem params - return, block_name, xpos, ypos
rem make sure you clear the block before calling
:check_colision
    set /a lowest_point=%~4+!%~2_HEIGHT!
    if !lowest_point! gtr %GAME_HEIGHT% (
        set %~1=%false%
        exit /b 0
    )
    for /l %%y in (0 1 !%~2_HEIGHT!) do (
        for /l %%x in (0 1 !%~2_WIDTH!) do (
            set /a x_pos=%%x+%~3
            set /a y_pos=%%y+%~4
            set color_=!%~2[%%y][%%x]!
            set game_board_color=^^!GAME_BOARD[!y_pos!][!x_pos!]^^!
            call :recurse game_board_color "!game_board_color!"
            if !game_board_color! neq %BLACK% (
                rem `and` doesn't really work
                if !color_! neq %BLACK% (
                    set %~1=%false%
                    exit /b 0
                )
            )
        )
    )
    set %~1=%true%
    exit /b 0




rem =======
rem CLEANUP
rem =======


:cleanup

echo %ANSI%%GAME_HEIGHT%;%GAME_WIDTH%H%ANSI%0m




endlocal
exit /b 0
