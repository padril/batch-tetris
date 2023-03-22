rem Copyright (C) 2023 Leo Peckham


@echo off
cls
setlocal enabledelayedexpansion




rem =========
rem CONSTANTS
rem =========


rem LANGUAGE UTIL
set /a true=1
set /a false=0

rem Delay calculations
:delay_calculation

    rem the higher the calculation floor and gap, the longer
    rem but more accurate the delay calculation will be
    set /a delay_calculation.CALCULATION_FLOOR=50
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
    set /a delay_calculation.ADJUSTMENT_AMOUNT=2
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

    timeout /t 3 /nobreak >nul

    cls

    echo.
    echo Press any key to start
    pause >nul
    

    cls



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
        set /a dif=1000-!dif!
        call :delay !dif!
    )
    if !key_pressed! equ D (
        call :clear_block LBLOCK !block_x! !block_y!
        set /a block_x=!block_x!+1
        call :display_block LBLOCK !block_x! !block_y!
        call :draw_board
        call :time_dif dif !time1! !time2!
        set /a dif=1000-!dif!
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
