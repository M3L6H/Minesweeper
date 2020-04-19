# Minesweeper

A simple implementation of Minesweeper done to prepare myself for the second App
Academy Ruby assessment.

## Instructions

The game is based on the original Microsoft Minesweeper. Upon downloading the
files or cloning the repository using
`git clone https://github.com/M3L6H/Minesweeper.git`, run the game with
`ruby ./play_minesweeper.rb`.

A game can be created using the `start` command which accepts as input either a
difficulty ("easy", "medium", or "expert") or a set of three numbers (height,
width, and number of mines).

To play, use the `check <row> <col>` command to uncover the target tile. Note
that the grid is numbered starting from 0, with the top left corner being 0, 0.

The first check will never hit a mine. After that, it is anybody's game.

At any point, use the `flag <row> <col>` command to flag a tile. This prevents
you from accidentally checking it, and if you successfully flag all the mines in
the game, you will win. Additionally, if you have successfully identified all
the mines surrounding a tile, when you check that tile, it will reveal
additional tiles.

Alternatively, you can win by revealing all tiles that are not mines.

If you check a mine, the game ends. You can either start a new game with the
`start` command, or quit with the `quit` command.

At any point if you forget how the commands work, use the `help` command to list
available commands.
