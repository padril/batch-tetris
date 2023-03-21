rem Copyright (C) 2023 Leo Peckham


@echo off
cls
setlocal enabledelayedexpansion




rem =========
rem CONSTANTS
rem =========


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
set /a block_x=5
set /a block_y=0

rem Initial display
call :display_block LBLOCK !block_x! !block_y!
call :draw_board


rem Descent loop
for /l %%T in ( 0 1 36 ) do (
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


rem param - time (changes based on speed of terminal)
:delay
    for /l %%Z in ( 0 1 %~1 ) do (
        rem delay
    )
    exit /b 0


rem params - var, "!var!"
:recurse
    set %~1=%~2
    exit /b 0




rem ==============
rem GAME FUNCTIONS
rem ==============


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
