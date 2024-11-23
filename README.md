# 8051-tic-tac-toe-game
Tic-tac-toe game on 8051

![GitHub](https://img.shields.io/github/license/ashvnv/8051-ludo-king-game)

Program is written in Assembly Language on Keil uVision and simulation was done on Proteus 8.15

## Proteus Schematic
<img src="https://raw.githubusercontent.com/ashvnv/8051-tic-tac-toe-game/refs/heads/main/Pics/pic1.png?raw=true">

<img src="https://github.com/ashvnv/8051-tic-tac-toe-game/raw/refs/heads/main/Pics/vid1.gif?raw=true" width=500>

## Overview:
The game follows the class Tic-tac-toe rules. This game can be played as single player vs 8051 or between two individual players.

### Game Modes:
#### Single Player vs. 8051 (Computer):
You can play against the 8051 microcontroller.
To select this mode, close the "PLAY WITH COMPUTER" switch.
In this case:
    Player 1 is you, and Player 2 is the 8051 microcontroller.
    The microcontroller (8051) will make its moves automatically.
    The 7-segment display will indicate whose turn it is.
#### Two Player Mode (Individual Players):
In this mode, two people can play against each other.
To enable this mode, open the "PLAY WITH COMPUTER" switch.
Player 1 and Player 2 take turns, and their moves are shown on the game grid.
The 7-segment display will indicate whose turn it is.

### RESTART button:
If you want to start a new game, press the RESTART button. This will reset the game and the board, allowing you to begin again.

### 7-Segment Display:
This is used to indicate whose turn it is. It likely shows numbers or symbols that represent either Player 1 (you) or Player 2 (the 8051 or the other human player) on the display.

### Gameplay:
Tic-Tac-Toe Rules: The game follows the classic rules where players take turns placing their marks (either X or O) on a 3x3 grid, aiming to get three of their marks in a row (horizontally, vertically, or diagonally).
Move Indication: Each player’s move is indicated on the grid, and after each move, the game checks for a winner.
If you're playing against the 8051, it uses a basic algorithm to choose its moves.
