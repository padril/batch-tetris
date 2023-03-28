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
    set /a true=1
    set /a false=0

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

    rem Game constants, indexed at one to make ANSI
    set /a GAME_HEIGHT=15 - 1
    set /a GAME_WIDTH=10 - 1
    for /l %%y in ( 0 1 %GAME_HEIGHT% ) do (
        for /l %%x in ( 0 1 %GAME_WIDTH% ) do (
            set GAME_BOARD[%%y][%%x]=%BLACK%
        )
    )

    rem Lists suck in batch, but this is a way to do them
    rem Each of these is a ANSI color array representing a tetronimo

    set /a NUMBER_OF_BLOCKS=7

    rem IBLOCK
    set "BLOCK_ID[0]=IBLOCK"
    set /a IBLOCK_WIDTH=4 - 1
    set /a IBLOCK_HEIGHT=1 - 1
    set x=0
    set y=0
    for %%n in ( %CYAN% %CYAN% %CYAN% %CYAN% ) do (
        set IBLOCK[!y!][!x!]=%%n
        if !x! equ %IBLOCK_WIDTH% (
            set /a y=!y!+1
            set /a x=0
        ) else (
            set /a x= !x! + 1
        )
    )

    rem OBLOCK
    set "BLOCK_ID[1]=OBLOCK"
    set /a OBLOCK_WIDTH=2 - 1
    set /a OBLOCK_HEIGHT=2 - 1
    set x=0
    set y=0
    for %%n in ( %YELLOW% %YELLOW% %YELLOW% %YELLOW% ) do (
        set OBLOCK[!y!][!x!]=%%n
        if !x! equ %OBLOCK_WIDTH% (
            set /a y=!y!+1
            set /a x=0
        ) else (
            set /a x= !x! + 1
        )
    )

    rem TBLOCK
    set "BLOCK_ID[2]=TBLOCK"
    set /a TBLOCK_WIDTH=3 - 1
    set /a TBLOCK_HEIGHT=2 - 1
    set x=0
    set y=0
    for %%n in ( %BLACK% %MAGENTA% %BLACK% %MAGENTA% %MAGENTA% %MAGENTA% ) do (
        set TBLOCK[!y!][!x!]=%%n
        if !x! equ %TBLOCK_WIDTH% (
            set /a y=!y!+1
            set /a x=0
        ) else (
            set /a x= !x! + 1
        )
    )

    rem JBLOCK
    set "BLOCK_ID[3]=JBLOCK"
    set /a JBLOCK_WIDTH=2 - 1
    set /a JBLOCK_HEIGHT=3 - 1
    set x=0
    set y=0
    for %%n in ( %BLACK% %BLUE% %BLACK% %BLUE% %BLUE% %BLUE% ) do (
        set JBLOCK[!y!][!x!]=%%n
        if !x! equ %JBLOCK_WIDTH% (
            set /a y=!y!+1
            set /a x=0
        ) else (
            set /a x= !x! + 1
        )
    )
    
    rem LBLOCK
    set "BLOCK_ID[4]=LBLOCK"
    set /a LBLOCK_WIDTH=2 - 1
    set /a LBLOCK_HEIGHT=3 - 1
    set x=0
    set y=0
    for %%n in ( %ORANGE% %BLACK% %ORANGE% %BLACK% %ORANGE% %ORANGE% ) do (
        set LBLOCK[!y!][!x!]=%%n
        if !x! equ %LBLOCK_WIDTH% (
            set /a y=!y!+1
            set /a x=0
        ) else (
            set /a x= !x! + 1
        )
    )

    rem SBLOCK
    set "BLOCK_ID[5]=SBLOCK"
    set /a SBLOCK_WIDTH=3 - 1
    set /a SBLOCK_HEIGHT=2 - 1
    set x=0
    set y=0
    for %%n in ( %BLACK% %GREEN% %GREEN% %GREEN% %GREEN% %BLACK% ) do (
        set SBLOCK[!y!][!x!]=%%n
        if !x! equ %SBLOCK_WIDTH% (
            set /a y=!y!+1
            set /a x=0
        ) else (
            set /a x= !x! + 1
        )
    )

    rem ZBLOCK
    set "BLOCK_ID[6]=ZBLOCK"
    set /a ZBLOCK_WIDTH=3 - 1
    set /a ZBLOCK_HEIGHT=2 - 1
    set x=0
    set y=0
    for %%n in ( %RED% %RED% %BLACK% %BLACK% %RED% %RED% ) do (
        set ZBLOCK[!y!][!x!]=%%n
        if !x! equ %ZBLOCK_WIDTH% (
            set /a y=!y!+1
            set /a x=0
        ) else (
            set /a x= !x! + 1
        )
    )

exit /b 0




rem ====
rem GAME
rem ====
:game

    set /a tick=0
    set /a x_pos=2
    set /a y_pos=0
    set /a rand_id=!random! * %NUMBER_OF_BLOCKS% /32768
    set current_block=^^!BLOCK_ID[!rand_id!]^^!
    call :recurse current_block "!current_block!"
    set /a culm_dif=900

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
                set /a x_pos=%GAME_WIDTH%/2
                set /a y_pos=0
                set /a rand_id=!random! * %NUMBER_OF_BLOCKS% / 32768
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
                set /a x_pos=%GAME_WIDTH%/2
                set /a y_pos=0
                set /A rand_id=!random! * %NUMBER_OF_BLOCKS% / 32768
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
    for /l %%x in ( 0 1 %GAME_WIDTH% ) do (
        set GAME_BOARD[!move_line_down.new_y!][%%x]=!GAME_BOARD[%~1][%%x]!
    )
    exit /b 0

:clear_lines
    for /l %%y in ( 0 1 %GAME_HEIGHT% ) do (
        if !GAME_BOARD[%%y][0]! equ %WHITE% (
            set /a clear_lines.above=%%y - 1
            for /l %%n in ( !clear_lines.above! -1 1 ) do (
                call :move_line_down %%n
            )
            for /l %%x in ( 0 1 %GAME_WIDTH% ) do (
                set GAME_BOARD[0][%%x]=%BLACK%
            )
        )
    )
    exit /b 0


rem param - return
:get_input
    for /f "delims=" %%A in ('choice /c ASD /n /t 1 /d s') do set "%~1=%%A" 
exit /b 0


:check_lines
    for /l %%y in ( 0 1 %GAME_HEIGHT% ) do (
        set complete_line=%true%
        for /l %%x in ( 0 1 %GAME_WIDTH% ) do (
            if !GAME_BOARD[%%y][%%x]! equ %BLACK% (
                set complete_line=%false%
            )
        )
        if !complete_line! equ %true% (
            for /l %%x in ( 0 1 %GAME_WIDTH% ) do (
                set GAME_BOARD[%%y][%%x]=%WHITE%
            )
        )
    )
    exit /b 0


:draw_board
    echo %ANSI%H
    for /l %%y in ( 0 1 %GAME_HEIGHT% ) do (
        set draw_board.line[%%y]=
        for /l %%x in ( 0 1 %GAME_WIDTH% ) do (
            set draw_board.line[%%y]=!draw_board.line[%%y]!%ANSI%8;!GAME_BOARD[%%y][%%x]!m#
        )
    )
    for /l %%y in ( 0 1 %GAME_HEIGHT% ) do (
        echo !draw_board.line[%%y]!
    )
    echo %ANSI%0m
exit /b 0


rem params - block_name, xpos, ypos
:display_block
    for /l %%y in (0 1 !%~1_HEIGHT!) do (
        for /l %%x in (0 1 !%~1_WIDTH!) do (
            set /a display_block.x_pos=%%x+%~2
            set /a display_block.y_pos=%%y+%~3
            set color_=!%~1[%%y][%%x]!
            if !color_! neq %BLACK% (
                set GAME_BOARD[!display_block.y_pos!][!display_block.x_pos!]=!color_!
            )
        )
    )
exit /b 0


rem params - block_name, xpos, ypos
:clear_block
    for /l %%y in (0 1 !%~1_HEIGHT!) do (
        for /l %%x in (0 1 !%~1_WIDTH!) do (
            set /a clear_block.x_pos=%%x+%~2
            set /a clear_block.y_pos=%%y+%~3
            set color_=!%~1[%%y][%%x]!
            if !color_! neq %BLACK% (
                set GAME_BOARD[!clear_block.y_pos!][!clear_block.x_pos!]=%BLACK%
            )
        )
    )
exit /b 0


rem params - return, block_name, xpos, ypos
rem make sure you clear the block before calling
:check_collision
    set /a lowest_point=%~4+!%~2_HEIGHT!
    if !lowest_point! gtr %GAME_HEIGHT% (
        set %~1=%true%
        exit /b 0
    )
    for /l %%y in (0 1 !%~2_HEIGHT!) do (
        for /l %%x in (0 1 !%~2_WIDTH!) do (
            set /a check_collision.x_pos=%%x+%~3
            set /a check_collision.y_pos=%%y+%~4
            set color_=!%~2[%%y][%%x]!
            set game_board_color=^^!GAME_BOARD[!check_collision.y_pos!][!check_collision.x_pos!]^^!
            call :recurse game_board_color "!game_board_color!"
            if !game_board_color! neq %BLACK% (
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
    echo %ANSI%%GAME_HEIGHT%;%GAME_WIDTH%H%ANSI%0m

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
