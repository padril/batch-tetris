@rem Copyright (C) 2023 Leo Peckham

@echo off
cls
setlocal enabledelayedexpansion




call :main
goto :end




rem ====
rem INIT
rem ====
:init

    call :constants

    rem Set ANSI settings
    echo %ANSI%?25l
    echo %ANSI%=7l
    echo %ANSI%0m

exit /b 0




rem =========
rem CONSTANTS
rem =========
:constants

    rem LANGUAGE UTIL
    set /a false=0
    set /a true=1

    rem ANSI
    for /f %%a in ('echo prompt $E ^| cmd') do set "ANSI=%%a["
    set /a BLACK=   40
    set /a RED=     41
    set /a GREEN=   42
    set /a YELLOW=  43
    set /a BLUE=    44
    set /a MAGENTA= 45
    set /a CYAN=    46
    set /a WHITE=   47
    set /a ORANGE=  101

    rem Game constants, subtracting 1 to index at 0
    set /a BOARD_HEIGHT= 15 - 1
    set /a BOARD_WIDTH=  10 - 1
    for /l %%y in ( 0 1 %BOARD_HEIGHT% ) do (
        for /l %%x in ( 0 1 %BOARD_WIDTH% ) do (
            set /a BOARD[%%y][%%x]=%BLACK%
        )
    )

    set /a NUMBER_OF_BLOCKS=0

    call :block_constructor IBLOCK 4 1 %CYAN% "1 1 1 1"
    call :block_constructor OBLOCK 2 2 %YELLOW% "1 1 1 1"
    call :block_constructor TBLOCK 3 2 %MAGENTA% "0 1 0 1 1 1"
    call :block_constructor JBLOCK 2 3 %BLUE% "0 1 0 1 1 1"
    call :block_constructor LBLOCK 2 3 %ORANGE% "1 0 1 0 1 1"
    call :block_constructor SBLOCK 3 2 %GREEN% "0 1 1 1 1 0"
    call :block_constructor ZBLOCK 3 2 %RED% "1 1 0 0 1 1"

exit /b 0




rem ====
rem GAME
rem ====
:game

    set /a tick=0
    set /a x_pos=2
    set /a y_pos=0
    set /a rand_id=!random! * !NUMBER_OF_BLOCKS! /32768
    set current_block=^^!BLOCK_ID[!rand_id!]^^!
    call :recurse current_block "!current_block!"
    set /a culm_dif=900

    call :draw_board

    :loop
        call :get_time time1
        rem I cannot think of a better way to do this
        for /f %%i in ('start /b cmd /c "choice /n /c ASD0 /t 1 /d 0"') do set key_pressed=%%i
        call :get_time time2
        call :time_dif dif !time1! !time2!
        if !dif! geq !culm_dif! (
            set /a culm_dif=900
            call :clear_block !current_block! !x_pos! !y_pos!
            set /a y_pos+=1
            call :check_collision collided !current_block! !x_pos! !y_pos!
            if !collided! equ %true% (
                set /a y_pos-=1
                call :display_block !current_block! !x_pos! !y_pos!
                call :check_lines
                call :draw_board
                timeout /t 1 /nobreak >nul
                call :clear_lines
                set /a x_pos=%BOARD_WIDTH%/2
                set /a y_pos=0
                set /a rand_id=!random! * !NUMBER_OF_BLOCKS! / 32768
                set current_block=^^!BLOCK_ID[!rand_id!]^^!
                call :recurse current_block "!current_block!"
            )
            call :display_block !current_block! !x_pos! !y_pos!
            call :draw_board
        ) else (
            set /a culm_dif-=!dif!
        )
        if "!key_pressed!" neq "0" (
            call :clear_block !current_block! !x_pos! !y_pos!
            set /a prev_x_pos=!x_pos!
            set /a prev_y_pos=!y_pos!
            if "!key_pressed!" equ "A" (
                set /a x_pos-=1
            )
            if "!key_pressed!" equ "D" (
                set /a x_pos+=1
            )
            if "!key_pressed!" equ "S" (
                set /a y_pos+=1
                set /a culm_dif=900
            )
            call :check_collision collided !current_block! !x_pos! !y_pos!
            if !collided! equ %true% (
                set /a x_pos=!prev_x_pos!
                set /a y_pos=!prev_y_pos!
                call :display_block !current_block! !x_pos! !y_pos!
                call :check_lines
                timeout /t 1 /nobreak >nul
                call :clear_lines
                set /a x_pos=%BOARD_WIDTH%/2
                set /a y_pos=0
                set /a rand_id=!random! * !NUMBER_OF_BLOCKS! / 32768
                set current_block=^^!BLOCK_ID[!rand_id!]^^!
                call :recurse current_block "!current_block!"
            )
            call :display_block !current_block! !x_pos! !y_pos!
            call :draw_board
        )

        goto :loop

exit /b 0




rem ==============
rem UTIL FUNCTIONS
rem ==============

rem fn( name, width, height, color, bit-array ) no ret
:block_constructor

    set BLOCK_ID[!NUMBER_OF_BLOCKS!]=%~1
    set /a %~1.width=%~2 - 1
    set /a %~1.height=%~3 - 1
    set /a block_constructor.x=0
    set /a block_constructor.y=0
    for %%b in ( %~5 ) do (
        if %%b equ 1 (
            set /a %~1[!block_constructor.y!][!block_constructor.x!]=%~4
        ) else (
            set /a %~1[!block_constructor.y!][!block_constructor.x!]=%BLACK%    
        )
        if !block_constructor.x! equ !%~1.width! (
            set /a block_constructor.y+=1
            set /a block_constructor.x=0
        ) else (
            set /a block_constructor.x+=1
        )
    )
    set /a NUMBER_OF_BLOCKS+=1

exit /b 0


rem params - return, function name, number of params in function, params
:time_it
    rem TODO: implement
    exit /b 0


rem params - return, time1, time2
:time_dif
    set /a %~1=%~3-%~2
    rem if the diff is negative, then %~3 was actually 60 seconds ahead
    if !%~1! lss 0 (
        set /a %~1=60000+%~1
    )
    exit /b 0


rem params - return
:get_time
    for /f "tokens=4 delims=:" %%i in ('echo.^|time') do set "%~1=%%i"
    rem add a one to the start so we don't have octal problems
    rem add a zero to turn into ms
    set /a %~1=1!%~1:,=!0
    set /a %~1=%~1-100000
    exit /b 0


rem param - time in milliseconds
:delay
    set /a delay.adjusted_time=%~1*!delay_calculation.ADJUSTMENT!
    set /a delay.adjusted_time=!delay.adjusted_time!/%delay_calculation.ADJUSTMENT_DECIMALS%
    set /a delay.iterations=!delay.adjusted_time!-!delay_calculation.CONSTANT_DELAY!
    set /a delay.iterations=!delay.iterations!*%delay_calculation.CALCULATION_GAP%
    set /a delay.iterations=!delay.iterations!/!delay_calculation.DELAY_PER_GAP!
    call :delay_ !delay.iterations!
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

rem params - y
:move_line_down
    set /a move_line_down.new_y=%~1 + 1
    for /l %%x in ( 0 1 %BOARD_WIDTH% ) do (
        set /a BOARD[!move_line_down.new_y!][%%x]=!BOARD[%~1][%%x]!
    )
    exit /b 0

:clear_lines
    for /l %%y in ( 0 1 %BOARD_HEIGHT% ) do (
        if !BOARD[%%y][0]! equ %WHITE% (
            set /a clear_lines.above=%%y - 1
            for /l %%n in ( !clear_lines.above! -1 1 ) do (
                call :move_line_down %%n
            )
            for /l %%x in ( 0 1 %BOARD_WIDTH% ) do (
                set /a BOARD[0][%%x]=%BLACK%
            )
        )
    )
    exit /b 0


rem param - return
:get_input
    for /f "delims=" %%A in ('choice /c ASD /n /t 1 /d s') do set "%~1=%%A" 
exit /b 0


:check_lines
    for /l %%y in ( 0 1 %BOARD_HEIGHT% ) do (
        set complete_line=%true%
        for /l %%x in ( 0 1 %BOARD_WIDTH% ) do (
            if !BOARD[%%y][%%x]! equ %BLACK% (
                set complete_line=%false%
            )
        )
        if !complete_line! equ %true% (
            for /l %%x in ( 0 1 %BOARD_WIDTH% ) do (
                set /a BOARD[%%y][%%x]=%WHITE%
            )
        )
    )
    exit /b 0


:draw_board
    echo %ANSI%H
    for /l %%y in ( 0 1 %BOARD_HEIGHT% ) do (
        set draw_board.line[%%y]=
        for /l %%x in ( 0 1 %BOARD_WIDTH% ) do (
            set draw_board.line[%%y]=!draw_board.line[%%y]!%ANSI%8;!BOARD[%%y][%%x]!m#
        )
    )
    for /l %%y in ( 0 1 %BOARD_HEIGHT% ) do (
        echo !draw_board.line[%%y]!
    )
    echo %ANSI%0m
exit /b 0


rem params - block_name, xpos, ypos
:display_block
    for /l %%y in (0 1 !%~1.height!) do (
        for /l %%x in (0 1 !%~1.width!) do (
            set /a display_block.x_pos=%%x+%~2
            set /a display_block.y_pos=%%y+%~3
            set color_=!%~1[%%y][%%x]!
            if !color_! neq %BLACK% (
                set /a BOARD[!display_block.y_pos!][!display_block.x_pos!]=!color_!
            )
        )
    )
exit /b 0


rem params - block_name, xpos, ypos
:clear_block
    for /l %%y in (0 1 !%~1.height!) do (
        for /l %%x in (0 1 !%~1.width!) do (
            set /a clear_block.x_pos=%%x+%~2
            set /a clear_block.y_pos=%%y+%~3
            set color_=!%~1[%%y][%%x]!
            if !color_! neq %BLACK% (
                set /a BOARD[!clear_block.y_pos!][!clear_block.x_pos!]=%BLACK%
            )
        )
    )
exit /b 0


rem params - return, block_name, xpos, ypos
rem make sure you clear the block before calling
:check_collision
    set /a lowest_point=%~4+!%~2.height!
    if !lowest_point! gtr %BOARD_HEIGHT% (
        set %~1=%true%
        exit /b 0
    )
    for /l %%y in (0 1 !%~2.height!) do (
        for /l %%x in (0 1 !%~2.width!) do (
            set /a check_collision.x_pos=%%x+%~3
            set /a check_collision.y_pos=%%y+%~4
            set color_=!%~2[%%y][%%x]!
            set BOARD_color=^^!BOARD[!check_collision.y_pos!][!check_collision.x_pos!]^^!
            call :recurse BOARD_color "!BOARD_color!"
            if !BOARD_color! neq %BLACK% (
                rem `and` doesn't really work
                if !color_! neq %BLACK% (
                    set %~1=%true%
                    exit /b 0
                )
            )
        )
    )
    set %~1=%false%
exit /b 0




rem =======
rem CLEANUP
rem =======
:cleanup

    echo Cleanup...
    pause >nul
    del tetris_istream.txt >nul
    echo %ANSI%%BOARD_HEIGHT%;%BOARD_WIDTH%H%ANSI%0m

exit /b 0




rem ====
rem MAIN
rem ====
:main

    call :init
    call :game
    call :cleanup

exit /b 0


:end

endlocal
exit /b 0