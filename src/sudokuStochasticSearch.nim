import sudoku
import sudokuConstraintProgramming

proc solveWithStochasticSearch*(g: var SudokuGrid) =
   let cpGrid = createSudokuCPGrid(g)

   discard

