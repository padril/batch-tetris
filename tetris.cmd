@rem Copyright (C) 2023 Leo Peckham

@echo off
cls
setlocal enabledelayedexpansion




call :main
goto :end




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

exit /b 0




rem ===========
rem SETUP BOARD
rem ===========
:setup_board

    set /a board.height= 15 - 1
    set /a board.width=  10 - 1
    for /l %%y in ( 0 1 %board.height% ) do (
        for /l %%x in ( 0 1 %board.width% ) do (
            set /a board[%%y][%%x]=%BLACK%
        )
    )

exit /b 0




rem =================
rem SETUP TETRONIMOES
rem =================
:setup_tetronimoes

    set /a TETRONIMO_COUNT=0

    call :tetronimo_constructor I_TETRONIMO 4 1 %CYAN%      "1 1 1 1"
    call :tetronimo_constructor O_TETRONIMO 2 2 %YELLOW%    "1 1 1 1"
    call :tetronimo_constructor T_TETRONIMO 3 2 %MAGENTA%   "0 1 0 1 1 1"
    call :tetronimo_constructor J_TETRONIMO 2 3 %BLUE%      "0 1 0 1 1 1"
    call :tetronimo_constructor L_TETRONIMO 2 3 %ORANGE%    "1 0 1 0 1 1"
    call :tetronimo_constructor S_TETRONIMO 3 2 %GREEN%     "0 1 1 1 1 0"
    call :tetronimo_constructor Z_TETRONIMO 3 2 %RED%       "1 1 0 0 1 1"
    
exit /b 0




rem ====
rem INIT
rem ====
:init

    call :constants
    call :setup_tetronimoes
    call :setup_board

    rem Set ANSI settings
    echo %ANSI%?25l
    echo %ANSI%=7l
    echo %ANSI%0m

exit /b 0




rem ==========
rem SETUP GAME
rem ==========
:setup_game
    call :create_tetronimo current_tetronimo x_pos y_pos
    call :display_tetronimo current_tetronimo x_pos y_pos
    call :reset_time_til_next_frame
    call :draw_board
exit /b 0




rem ====
rem GAME
rem ====
:game

    call :setup_game

    :loop

        call :get_time begin_input
        for /f %%i in ('start /b cmd /c "choice /n /c ASD0 /t 1 /d 0"') do set key_pressed=%%i
        call :get_time end_input
        call :time_dif input_time !begin_input! !end_input!

        if !input_time! geq !time_til_next_frame! (
            call :reset_time_til_next_frame
            call :move current_tetronimo x_pos y_pos y_pos 1
        ) else (
            set /a time_til_next_frame-=!input_time!
            if "!key_pressed!" neq "0" (
                if "!key_pressed!" equ "A" (
                    call :move current_tetronimo x_pos y_pos x_pos -1
                )
                if "!key_pressed!" equ "D" (
                    call :move current_tetronimo x_pos y_pos x_pos 1
                )
                if "!key_pressed!" equ "S" (
                    call :reset_time_til_next_frame
                    call :move current_tetronimo x_pos y_pos y_pos 1
                )
            )
        )
    call :draw_board
    goto :loop

exit /b 0




rem =======
rem CLEANUP
rem =======
:cleanup

    echo Cleanup...
    pause >nul
    echo %ANSI%%board.height%;%board.width%H%ANSI%0m

exit /b 0




rem ====
rem MAIN
rem ====
:main

    call :init
    call :game
    call :cleanup

exit /b 0




rem############################################################################
rem############################################################################




rem ==============
rem UTIL FUNCTIONS
rem ==============


rem fn( name, width, height, color, bit-array ) no ret
:tetronimo_constructor
    set tetronimo_by_id[!TETRONIMO_COUNT!]=%~1
    set /a %~1.width=%~2 - 1
    set /a %~1.height=%~3 - 1
    set /a tetronimo_constructor.x=0
    set /a tetronimo_constructor.y=0
    for %%b in ( %~5 ) do (
        if %%b equ 1 (
            set /a %~1[!tetronimo_constructor.y!][!tetronimo_constructor.x!]=%~4
        ) else (
            set /a %~1[!tetronimo_constructor.y!][!tetronimo_constructor.x!]=%BLACK%    
        )
        if !tetronimo_constructor.x! equ !%~1.width! (
            set /a tetronimo_constructor.y+=1
            set /a tetronimo_constructor.x=0
        ) else (
            set /a tetronimo_constructor.x+=1
        )
    )
    set /a TETRONIMO_COUNT+=1
exit /b 0

rem params - return, start_time, end_time
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


rem params - var, "!var!"
:recurse
    set %~1=%~2
exit /b 0

:recurse_a
    set /a %~1=%~2
exit /b 0




rem ==============
rem GAME FUNCTIONS
rem ==============


rem fn(tetronimo, x_pos, y_pos, movement_axis, movement_amount) no return
:move
    call :clear_tetronimo !%~1! !%~2! !%~3!
    set /a %~4+=%~5

    call :check_collision collided !%~1! !%~2! !%~3!
    if !collided! equ %true% (
        set /a %~4-=%~5
        call :display_tetronimo !%~1! !%~2! !%~3!

        call :check_lines
        call :clear_lines

        call :create_tetronimo %~1 %~2 %~3
    )
    call :display_tetronimo !%~1! !%~2! !%~3!
exit /b 0

:reset_time_til_next_frame
    set /a time_til_next_frame=1000
exit /b 0

rem fn() returns name, x, y
:create_tetronimo
    set /a rand_id=!random! * !TETRONIMO_COUNT! /32768
    set %~1=^^!tetronimo_by_id[!rand_id!]^^!
    call :recurse %~1 "!%~1!"

    set create_tetronimo.height=^^!!%~1!.height^^!
    call :recurse_a create_tetronimo.height "!create_tetronimo.height!"

    set /a %~2=%board.width%/2
    set /a %~3=-!create_tetronimo.height!-1
exit /b 0


rem params - y
:move_line_down
    set /a move_line_down.new_y=%~1 + 1
    for /l %%x in ( 0 1 %board.width% ) do (
        set /a board[!move_line_down.new_y!][%%x]=!board[%~1][%%x]!
    )
exit /b 0

:clear_lines
    for /l %%y in ( 0 1 %board.height% ) do (
        if !board[%%y][0]! equ %WHITE% (
            set /a clear_lines.above=%%y - 1
            for /l %%n in ( !clear_lines.above! -1 1 ) do (
                call :move_line_down %%n
            )
            for /l %%x in ( 0 1 %board.width% ) do (
                set /a board[0][%%x]=%BLACK%
            )
        )
    )
    exit /b 0


rem param - return
:get_input
    for /f "delims=" %%A in ('choice /c ASD /n /t 1 /d s') do set "%~1=%%A" 
exit /b 0


:check_lines
    set /a check_lines.any_complete=%false%
    for /l %%y in ( 0 1 %board.height% ) do (
        set complete_line=%true%
        for /l %%x in ( 0 1 %board.width% ) do (
            if !board[%%y][%%x]! equ %BLACK% (
                set complete_line=%false%
            )
        )
        if !complete_line! equ %true% (
            set /a check_lines.any_complete=%true%
            for /l %%x in ( 0 1 %board.width% ) do (
                set /a board[%%y][%%x]=%WHITE%
            )
        )
    )
    if !check_lines.any_complete! equ %true% (
        call :draw_board
        timeout /t 1 /nobreak >nul
    )
exit /b 0


:draw_board
    echo %ANSI%H
    for /l %%y in ( 0 1 %board.height% ) do (
        set draw_board.line[%%y]=
        for /l %%x in ( 0 1 %board.width% ) do (
            set draw_board.line[%%y]=!draw_board.line[%%y]!%ANSI%8;!board[%%y][%%x]!m#
        )
    )
    for /l %%y in ( 0 1 %board.height% ) do (
        echo !draw_board.line[%%y]!
    )
    echo %ANSI%0m
exit /b 0


rem params - tetronimo_name, xpos, ypos
:display_tetronimo
    for /l %%y in (0 1 !%~1.height!) do (
        set /a display_tetronimo.y_pos=%%y+%~3
        if !display_tetronimo.y_pos! geq 0 (
            for /l %%x in (0 1 !%~1.width!) do (
                set /a display_tetronimo.x_pos=%%x+%~2
                set color_=!%~1[%%y][%%x]!
                if !color_! neq %BLACK% (
                    rem echo %ANSI%10C!display_tetronimo.y_pos! !display_tetronimo.x_pos!
                    set /a board[!display_tetronimo.y_pos!][!display_tetronimo.x_pos!]=!color_!
                )
            )
        )
    )
exit /b 0


rem params - tetronimo_name, xpos, ypos
:clear_tetronimo
    for /l %%y in (0 1 !%~1.height!) do (
        for /l %%x in (0 1 !%~1.width!) do (
            set /a clear_tetronimo.x_pos=%%x+%~2
            set /a clear_tetronimo.y_pos=%%y+%~3
            set color_=!%~1[%%y][%%x]!
            if !clear_tetronimo.y_pos! geq 0 (
                if !color_! neq %BLACK% (
                    set /a board[!clear_tetronimo.y_pos!][!clear_tetronimo.x_pos!]=%BLACK%
                )
            )
        )
    )
exit /b 0


rem params - return, tetronimo_name, xpos, ypos
rem make sure you clear the tetronimo before calling
:check_collision

    set /a lowest_point=%~4+!%~2.height!
    if !lowest_point! gtr %board.height% (
        set %~1=%true%
        exit /b 0
    )
    for /l %%y in (0 1 !%~2.height!) do (
        set /a check_collision.y_pos=%%y+%~4
        if !check_collision.y_pos! geq 0 (
            for /l %%x in (0 1 !%~2.width!) do (
                set /a check_collision.x_pos=%%x+%~3
                set color_=!%~2[%%y][%%x]!
                set board_color=^^!board[!check_collision.y_pos!][!check_collision.x_pos!]^^!
                call :recurse board_color "!board_color!"
                if !board_color! neq %BLACK% (
                    rem `and` doesn't really work
                    if !color_! neq %BLACK% (
                        set %~1=%true%
                        exit /b 0
                    )
                )
            )
        )
    )
    set %~1=%false%

exit /b 0




:end

endlocal
exit /b 0