import parseopt
import strutils
import times

import sudoku
import sudokuBacktracing
import sudokuConstraintProgramming
import sudokuStochasticSearch

const version = 0.1

type
   SolvingSolution* = enum
      ConstraintProgramming,
      Backtracing,
      StochasticProgramming

   CmdOpt = object
      showHelp: bool
      showVersion: bool
      inputFilePath: string
      outputFilePath: string
      showGrids: bool
      solvingSolution: SolvingSolution
      solve: bool
      showTime: bool
      solutionGridFilePath: string

proc createCmdOpt(): CmdOpt =
   result.showHelp = false
   result.showVersion = false
   result.inputFilePath = ""
   result.outputFilePath = ""
   result.showGrids = false
   result.solvingSolution = SolvingSolution.Backtracing
   result.solve = false
   result.showTime = false
   result.solutionGridFilePath = ""

proc helpStr(): string =
   return """
Nim-sudoku

Arguments:
   Input file path of the sudoku grid [string]

Options:
  -h --help                     Show this screen
  --version                     Show version
  --solveBacktracing            Solve the sudoku with backtracing
  --solveConstraintProgramming  Solve the sudoku with constraint programming
  --solveStochasticSearch       Solve the sudoku with stochastic search
  --showGrids                   Show sudoku grids
  -o --outputFile=[string]      Write result sudoku in the given file path
  --showTime                    Show solving time
  --checkWith=[string]          Check result sudoku with the given solution

Usage:
  # Show a sudoku grid
  nim-sudoku grid.txt --showGrids

  # Solve a sudoku grid with backtracing and show it with elapsed time
  nim-sudoku grid.txt --solveBacktracing --showGrids --showTime
"""

proc versionStr(): string = result = "nim-sudoku " & $version

proc main() =
   var cmdOpt = createCmdOpt()
   for kind, key, val in getopt():
      case kind
      of cmdArgument:
         cmdOpt.inputFilePath = key
      of cmdLongOption, cmdShortOption:
         case key:
         of "o", "outputFile": cmdOpt.outputFilePath = val
         of "h", "help": cmdOpt.showHelp = true
         of "version": cmdOpt.showVersion = true
         of "showGrids": cmdOpt.showGrids = true
         of "solveConstraintProgramming":
            cmdOpt.solvingSolution = SolvingSolution.ConstraintProgramming
            cmdOpt.solve = true
         of "solveBacktracing":
            cmdOpt.solvingSolution = SolvingSolution.Backtracing
            cmdOpt.solve = true
         of "solveStochasticSearch":
            cmdOpt.solvingSolution = SolvingSolution.StochasticProgramming
            cmdOpt.solve = true
         of "showTime": cmdOpt.showTime = true
         of "checkWith": cmdOpt.solutionGridFilePath = val
      of cmdEnd: assert(false)

   if cmdOpt.showHelp:
      echo helpStr()
   elif cmdOpt.showVersion:
      echo versionStr()
   elif cmdOpt.inputFilePath.isEmptyOrWhitespace:
      echo "Input file missing"
      echo helpStr()
   else:
      var grid = createSudokuGrid(cmdOpt.inputFilePath)
      if cmdOpt.showGrids:
         echo "Input Grid"
         echo grid

      if cmdOpt.solve:
         let startTime = cpuTime()

         case cmdOpt.solvingSolution:
            of SolvingSolution.ConstraintProgramming:
               grid.solveWithConstraintProgramming()
            of SolvingSolution.Backtracing:
               grid.solveWithBacktracing()
            of SolvingSolution.StochasticProgramming:
               grid.solveWithStochasticSearch()

         let duration = cpuTime() - startTime

         if cmdOpt.showGrids:
            echo "Solved Grid"
            echo grid

         if not cmdOpt.solutionGridFilePath.isEmptyOrWhitespace:
            let solutionGrid = createSudokuGrid(cmdOpt.solutionGridFilePath)
            if grid == solutionGrid:
               echo "Solved grid and given solution grid are same!"
            else:
               echo "Solved grid and given solution grid are different!"
               if cmdOpt.showGrids:
                  echo solutionGrid

         if cmdOpt.showTime:
            let elapsedStr = duration.formatFloat(format=ffDecimal, precision=9)
            echo "Solving time: " & $elapsedStr & "s"
main()
