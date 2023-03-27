@echo off
cls
setlocal enabledelayedexpansion

rem Copyright (C) 2023 Leo Peckham


rem TODO! AND A BIG FUCKING TODO AT THAT
rem I CANNOT FUCKING FIGURE OUT HOW TO GET INPUT
rem TO WORK ALL IN THE SAME WINDOW, CAUSE HAVING TWO
rem PROCESSES GOING SIMULTANEOUSLY IS SERIOUSLY A BITCH
rem USING TWO WINDOWS DOESN't REALLY WORK EITHER SO
rem I"M JUST GOING TO KEEP HAVING TO THINK OF A WORKAROUND
rem AND THATS A BITCH

rem CURRENT IDEAS:
rem     - USE THE SOMETIMES FAILING METHOD
rem     - JUST MAKE REALLY GOOD GUESSED OF WHEN WE CAN
rem       CHECK FOR INPUT
rem     - maybe using two windows could work in
rem       a different environment

rem I slept on it and have a good idea
rem use a call with two start commands to check for input, or terminate early
rem if terminated early, it will flag to not start a new listen resquest on 
rem reentry it will always go straight to drawing the frame after, which is fine
rem since it will prevent a lot of presses of the same key




call :init
call :main
call :cleanup
goto :end




rem ====
rem INIT
rem ====
:init
    call :constants
    rem call :delay_calculation

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
    set /a RED=41
    set /a BLACK=40

    rem Set ANSI settings
    echo %ANSI%?25l
    echo %ANSI%0m


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
    set "BLOCK_ID[0]=LBLOCK"
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

    rem SBLOCK
    set "BLOCK_ID[1]=SBLOCK"
    set /a SBLOCK_WIDTH=2 - 1
    set /a SBLOCK_HEIGHT=2 - 1
    set x=0
    set y=0
    for %%n in ( %RED% %RED% %RED% %RED% ) do (
        set SBLOCK[!y!][!x!]=%%n
        if !x! equ %SBLOCK_WIDTH% (
            set /a y=!y!+1
            set /a x=0
        ) else (
            set /a x= !x! + 1
        )
    )

exit /b 0




rem =================
rem DELAY CALCULATION
rem =================
:delay_calculation

    rem the higher the calculation floor and gap, the longer
    rem but more accurate the delay calculation will be
    set /a delay_calculation.CALCULATION_FLOOR=30
    set /a delay_calculation.CALCULATION_GAP=50
    set /a %delay_calculation.CALCULATION_HALF_GAP=^
          %delay_calculation.CALCULATION_GAP%/2
    set /a delay_calculation.CALCULATION_CEIL=^
          %delay_calculation.CALCULATION_FLOOR%^
          +%delay_calculation.CALCULATION_GAP%

    echo Getting information about your terminal's speed...
    for %%i in (%delay_calculation.CALCULATION_HALF_GAP%^
                %delay_calculation.CALCULATION_FLOOR%^
                %delay_calculation.CALCULATION_CEIL%) do (
        call :get_time delay_calculation.start
        call :delay_ %%i
        call :get_time delay_calculation.end
        call :time_dif delay_calculation.dif[%%i]^
                       !delay_calculation.start!^
                       !delay_calculation.end!
    )

    rem Calculate linear approximation
    set /a delay_calculation.DELAY_PER_GAP=^
        !delay_calculation.dif[%delay_calculation.CALCULATION_CEIL%]!^
        -!delay_calculation.dif[%delay_calculation.CALCULATION_FLOOR%]!
    set /a delay_calculation.CONSTANT_DELAY=^
        !delay_calculation.dif[%delay_calculation.CALCULATION_HALF_GAP%]!^
        -!delay_calculation.DELAY_PER_GAP!/2

    echo Predicting a delay...
    set /a delay_calculation.predicted=^
        !delay_calculation.DELAY_PER_GAP!^
        +!delay_calculation.CONSTANT_DELAY!
    call :get_time delay_calculation.start
    call :delay_ %delay_calculation.CALCULATION_GAP%
    call :get_time delay_calculation.end
    call :time_dif delay_calculation.dif^
                   !delay_calculation.start!^
                   !delay_calculation.end!
    echo    Predicted delay: !delay_calculation.predicted!ms
    echo    Actual delay:    !delay_calculation.dif!ms
    
    echo Adjusting based on prediction...
    rem Adjustment is a 'floating' point number.
    rem We will only adjust by a percentage of adjustment
    set /a delay_calculation.ADJUSTMENT_DECIMALS=1000
    set /a delay_calculation.ADJUSTMENT_AMOUNT=1
    set /a delay_calculation.ADJUSTMENT=^
        ((!delay_calculation.predicted!*%delay_calculation.ADJUSTMENT_DECIMALS%)^
        /!delay_calculation.dif!-%delay_calculation.ADJUSTMENT_DECIMALS%)^
        /%delay_calculation.ADJUSTMENT_AMOUNT%+%delay_calculation.ADJUSTMENT_DECIMALS%

    echo Testing delay function on 500ms (0.5 seconds)...
    call :get_time delay_calculation.start
    call :delay 500
    call :get_time delay_calculation.end
    call :time_dif delay_calculation.dif^
                   !delay_calculation.start!^
                   !delay_calculation.end!
    echo    Attempted delay: 500ms
    echo    Actual delay:    !delay_calculation.dif!ms
    echo    (Difference between attempted and actual should be ^<= 100ms)

    echo.
    echo Press any key to start
    pause >nul

    cls

exit /b 0




rem ====
rem MAIN
rem ====
:main

    call :game


exit /b 0




rem ====
rem GAME
rem ====
:game

    set /a tick=0
    set /a x_pos=5
    set /a y_pos=0
    set /a rand_id=!random! * 2 /32768
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
                set /a x_pos=%GAME_WIDTH%/2
                set /a y_pos=0
                set /a rand_id=!random! * 2 / 32768
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
                set /a x_pos=%GAME_WIDTH%/2
                set /a y_pos=0
                set /A rand_id=!random! * 2 / 32768
                set current_block=^^!BLOCK_ID[!rand_id!]^^!
                call :recurse current_block "!current_block!"
            )
            call :display_block !current_block! !x_pos! !y_pos!
            call :draw_board

            goto :loop
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




:end

endlocal
exit /b 0
