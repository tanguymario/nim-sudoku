import parseopt
import strutils
import times

import sudoku

const version = 0.1

type
   CmdOpt = object
      showHelp: bool
      showVersion: bool
      inputFilePath: string
      outputFilePath: string
      showGrids: bool
      gridToSolvePath: string
      generate: bool
      generateDifficulty: int
      showTime: bool
      solutionGridFilePath: string

proc createCmdOpt(): CmdOpt =
   result.showHelp = false
   result.showVersion = false
   result.inputFilePath = ""
   result.outputFilePath = ""
   result.showGrids = false
   result.gridToSolvePath = ""
   result.generate = false
   result.generateDifficulty = 0
   result.showTime = false
   result.solutionGridFilePath = ""

proc helpStr(): string =
   return """
Nim-sudoku

Options:
  -h --help                 Show this screen
  --version                 Show version
  --solve=[string]          Solve the sudoku at the given filepath
  --generate=[0-100]        Generates a sudoku grid with the given difficulty
  --showGrids               Show sudoku grids
  --outputFile=[string]  Write result sudoku in the given file path
  --showTime                Show solving time
  --checkWith=[string]      Check result sudoku with the given solution

Usage:
  # Solve a sudoku grid and show it with elapsed time
  nim-sudoku --solve=grid.txt --showGrids --showTime

  # Generate a sudoku grid and writes it into a file
  nim-sudoku --generate=50 --showGrids --showTime --outputFile=test1.txt
"""

proc versionStr(): string = result = "nim-sudoku " & $version

proc main() =
   var cmdOpt = createCmdOpt()
   for kind, key, val in getopt():
      case kind
      of cmdArgument: discard
      of cmdLongOption, cmdShortOption:
         case key:
         of "outputFile": cmdOpt.outputFilePath = val
         of "h", "help": cmdOpt.showHelp = true
         of "version": cmdOpt.showVersion = true
         of "showGrids": cmdOpt.showGrids = true
         of "solve": cmdOpt.gridToSolvePath = val
         of "generate":
            cmdOpt.generate = true
            cmdOpt.generateDifficulty = parseInt(val)
         of "showTime": cmdOpt.showTime = true
         of "checkWith": cmdOpt.solutionGridFilePath = val
      of cmdEnd: assert(false)

   if cmdOpt.showHelp:
      echo helpStr()
   elif cmdOpt.showVersion:
      echo versionStr()
   elif not cmdOpt.gridToSolvePath.isEmptyOrWhitespace:
      var grid = createSudokuGrid(cmdOpt.gridToSolvePath)

      if cmdOpt.showGrids:
         echo "Input Grid"
         echo grid

      let startTime = cpuTime()
      grid.solve()
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

      if not cmdOpt.outputFilePath.isEmptyOrWhitespace:
         grid.writeToFile(cmdOpt.outputFilePath)

   elif cmdOpt.generate:
      let startTime = cpuTime()
      var grid = generate(cmdOpt.generateDifficulty)
      let duration = cpuTime() - startTime

      if cmdOpt.showGrids:
         echo "Generated Grid"
         echo grid

      if cmdOpt.showTime:
         let elapsedStr = duration.formatFloat(format=ffDecimal, precision=9)
         echo "Generating time: " & $elapsedStr & "s"

      if not cmdOpt.outputFilePath.isEmptyOrWhitespace:
         grid.writeToFile(cmdOpt.outputFilePath)
   else:
      echo helpStr()

main()
