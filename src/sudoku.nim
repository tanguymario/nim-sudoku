import strutils
import times
import sequtils
import random
import hashes

## Util to get position in the sudoku grid

{.push exportc: "Sudoku$1", dynlib.}

type
   Pos* = object
      x, y: int

proc pos*(y, x: int): Pos = result = Pos(y: y, x: x)

proc outOfBounds*(p: Pos): bool =
   return p.x < 0 or p.x >= 9 or p.y < 0 or p.y >= 9

proc next*(p: var Pos) =
   if p.x >= 8:
      p.y += 1
      p.x = 0
   else:
      p.x += 1

proc prev*(p: var Pos) =
   if p.x <= 0:
      p.y -= 1
      p.x = 8
   else:
      p.x -= 1

{.pop.}


## Util to get matrices values easily

proc `[]`*[T, Y, X](g: array[Y, array[X, T]], y, x: int): T =
   return g[y][x]
proc `[]`*[T, Y, X](g: var array[Y, array[X, T]], y, x: int): var T =
   return g[y][x]
proc `[]=`*[T, Y, X](g: var array[Y, array[X, T]], y, x: int, v: T) =
   g[y][x] = v

proc `[]`*[T, Y, X](g: array[Y, array[X, T]], p: Pos): T =
   return g[p.y][p.x]
proc `[]`*[T, Y, X](g: var array[Y, array[X, T]], p: Pos): var T =
   return g[p.y][p.x]
proc `[]=`*[T, Y, X](g: var array[Y, array[X, T]], p: Pos, v: T) =
   g[p.y][p.x] = v

## Iterators

{.push exportc: "Sudoku$1", dynlib.}

type
   SudokuCell* = int
   SudokuGrid* = array[9, array[9, SudokuCell]]

iterator gridPos*(): Pos =
   for y in 0 ..< 9:
      for x in  0 ..< 9:
         yield pos(y, x)

iterator gridCases*(): Pos =
   for y in 0 ..< 3:
      for x in 0 ..< 3:
         yield pos(y * 3, x * 3)

iterator casePos*(p: Pos): Pos =
   let caseY = int(p.y / 3)
   let caseX = int(p.x / 3)
   for y in 0 ..< 3:
      for x in  0 ..< 3:
         yield pos(caseY * 3 + y, caseX * 3 + x)

iterator colPos*(x: int): Pos =
   for y in 0 ..< 9:
      yield pos(y, x)

iterator rowPos*(y: int): Pos =
   for x in 0 ..< 9:
      yield pos(y, x)

iterator rowColCasePos*(p: Pos): Pos =
   for rp in rowPos(p.y):
      yield rp
   for cp in colPos(p.x):
      yield cp
   for caseP in casePos(p):
      yield caseP

## Sudoku Cell and Grid

{.push exportc: "SudokuSolver$1", dynlib.}

proc filled*(c: SudokuCell): bool = return c != 0

proc filledAt*(g: SudokuGrid, pos: openArray[Pos]): bool =
   for p in pos:
      if g[p].filled:
         return true
   return false

proc full*(g: SudokuGrid): bool =
   for p in gridPos():
      if not g[p].filled:
         return false
   return true

proc broken*(g: SudokuGrid): bool =
   for p in gridPos():
      for pp in rowColCasePos(p):
         if p != pp and g[p].filled and g[pp].filled and g[p] == g[pp]:
            return true
   return false

proc `$`*(g: SudokuGrid): string =
   for y in 0 ..< 9:
      result &= join(g[y], " ") & "\n"

proc fancyStr*(g: SudokuGrid): string =
   result &= "╔═══════╦═══════╦═══════╗\n"
   for y in 0 ..< 9:
      if y > 0 and y mod 3 == 0:
         result &= "╠═══════╬═══════╬═══════╣\n"
      result &= "║ "
      for x in 0 ..< 9:
         result &= (if g[y, x].filled: $g[y, x] else: " ")
         result &= (if (x + 1) mod 3 == 0: " ║ " else: " ")
      result &= "\n"
   result &= "╚═══════╩═══════╩═══════╝\n"

proc createEmptySudokuGrid*(): SudokuGrid =
   for p in gridPos():
      result[p] = 0

proc createSudokuGrid*(m: array[9, array[9, SudokuCell]]): SudokuGrid =
   for p in gridPos():
      result[p] = m[p]

proc readSudokuGridFromFile*(filePath: string): SudokuGrid =
   let gridStr = readFile(filePath).split({'\n', ' '})
   for p in gridPos():
      result[p] = parseInt(gridStr[p.y * 9 + p.x])

proc writeToFile*(g: SudokuGrid, filePath: string) =
   let f = open(filePath, fmWrite)
   f.write($g)
   f.close()

{.pop.}

## Sudoku Cell and Grid Solvers. They represent the possibilities of the sudoku

{.push exportc: "Solver$1", dynlib.}

type
   SolverCell* = seq[int]
   SolverGrid* = array[9, array[9, SolverCell]]

proc nbPossibilities*(sc: SolverCell): int = return len(sc)
proc filled*(sc: SolverCell): bool = return sc.nbPossibilities == 1
proc value*(sc: SolverCell): SudokuCell = return (if sc.filled: sc[0] else: 0)

proc isPossible*(sc: SolverCell, v: SudokuCell): bool =
   return not sc.filled and sc.contains(v)

proc getPossiblePos*(sg: SolverGrid, pos: seq[Pos], v: SudokuCell): seq[Pos] =
   for p in pos:
      if sg[p].isPossible(v):
         result.add(p)

proc `$`*(sg: SolverGrid): string =
   for p in gridPos():
      result &= $p & $sg[p] & "\n"

proc removePossibility(sg: var SolverGrid, p: Pos, v: SudokuCell)
proc onFilled(sg: var SolverGrid, p: Pos)

proc removePossibility(sg: var SolverGrid, p: Pos, v: SudokuCell) =
   let idx = sg[p].find(v)
   if idx >= 0:
      sg[p].del(idx)
      if sg[p].filled:
         sg.onFilled(p)

proc onFilled(sg: var SolverGrid, p: Pos) =
   for pp in rowColCasePos(p):
      if p != pp:
         sg.removePossibility(pp, sg[p][0])

proc fill(sg: var SolverGrid, p: Pos, v: SudokuCell) =
   sg[p] = @[v]
   sg.onFilled(p)

proc checkForcedDigits(sg: var SolverGrid) =
   var canSolve = true
   while canSolve:
      canSolve = false
      for v in 1 .. 9:
         for y in 0 ..< 9:
            let rowPossibilitiesPos = sg.getPossiblePos(toSeq(rowPos(y)), v)
            if len(rowPossibilitiesPos) == 1:
               canSolve = true
               sg.fill(rowPossibilitiesPos[0], v)

         for x in 0 ..< 9:
            let colPossibilitiesPos = sg.getPossiblePos(toSeq(colPos(x)), v)
            if len(colPossibilitiesPos) == 1:
               canSolve = true
               sg.fill(colPossibilitiesPos[0], v)

         for caseY in 0 ..< 3:
            for caseX in 0 ..< 3:
               for y in 0 ..< 3:
                  for x in 0 ..< 3:
                     let p = pos(caseY * 3 + y, caseX * 3 + x)
                     let casePossibilitiesPos =
                        sg.getPossiblePos(toSeq(casePos(p)), v)
                     if len(casePossibilitiesPos) == 1:
                        canSolve = true
                        sg.fill(casePossibilitiesPos[0], v)

proc apply*(sg: SolverGrid, g: var SudokuGrid) =
   for p in gridPos():
      g[p] = sg[p].value

proc createSolverGrid*(g: SudokuGrid): SolverGrid =
   for p in gridPos():
      if g[p].filled:
         result[p] = @[g[p]]
      else:
         result[p] = @[1, 2, 3, 4, 5, 6, 7, 8, 9]

   for p in gridPos():
      if g[p].filled:
         result.onFilled(p)

   result.checkForcedDigits()

{.pop.}

## Solving algorithm (backtracing)

{.push exportc: "Sudoku$1", dynlib.}

type
   SolveOpts* = object
      randomizeBacktracingIndices: bool
      rand: Rand
      checkIfMultipleSolutionsExists: bool

   SolveResultInfo* = object
      solutionFound: bool
      multipleGridsExist: bool

proc backtracing(
   g: var SudokuGrid, sg: SolverGrid,
   opts: SolveOpts, resultInfo: var SolveResultInfo) =

   if g.full:
      resultInfo.solutionFound = true
      resultInfo.multipleGridsExist = false
      return

   type
      PossibleCell = ref PossibleCellObj
      PossibleCellObj = object
         p: Pos
         possibilities: SolverCell
         ind: int

   var cells: seq[PossibleCell]
   for p in gridPos():
      if not sg[p].filled:
         cells.add(PossibleCell(p: p, possibilities: sg[p], ind: 0))

   if opts.randomizeBacktracingIndices:
      var r = opts.rand
      for cell in cells:
         shuffle(r, cell.possibilities)

   var i = 0

   let increaseValueOrGoBack = proc(
      g: var SudokuGrid, cells: var seq[PossibleCell], i: var int): bool =

      while true:
         if cells[i].ind < len(cells[i].possibilities) - 1:
            cells[i].ind += 1
            return true
         else:
            cells[i].ind = 0
            g[cells[i].p] = 0

            dec(i)
            if i < 0:
               return false

   while true:
      let v = cells[i].possibilities[cells[i].ind]

      var invalid = false
      for pp in rowColCasePos(cells[i].p):
         if pp != cells[i].p and g[pp].filled and g[pp] == v:
            invalid = true
            break

      if invalid:
         if not increaseValueOrGoBack(g, cells, i):
            break
      else:
         g[cells[i].p] = v
         inc(i)

         if i >= len(cells):
            if not opts.checkIfMultipleSolutionsExists:
               resultInfo.solutionFound = true
               break
            elif resultInfo.solutionFound:
               resultInfo.multipleGridsExist = true
               break
            else:
               resultInfo.solutionFound = true
               i -= 1
               if not increaseValueOrGoBack(g, cells, i):
                  break

proc solve*(
   g: var SudokuGrid,
   opts: SolveOpts=SolveOpts(
      randomizeBacktracingIndices: false,
      checkIfMultipleSolutionsExists: false)): SolveResultInfo {.discardable.} =

   result = SolveResultInfo(
      solutionFound: false,
      multipleGridsExist: false)

   if not g.broken:
      var sg = createSolverGrid(g)
      sg.apply(g)
      g.backtracing(sg, opts, result)

{.pop.}

## Generate Sudoku

{.push exportc, dynlib.}

proc generateNaiveGrid*(): SudokuGrid = discard result.solve()
const NaiveGeneratedGrid*: SudokuGrid = generateNaiveGrid()

proc generateRandomGrid*(r: var Rand): SudokuGrid =
   discard result.solve(SolveOpts(
      randomizeBacktracingIndices: true,
      rand: r,
      checkIfMultipleSolutionsExists: false))

proc generateGrid*(difficulty: int, seed: string): SudokuGrid =
   var r: Rand
   if not seed.isEmptyOrWhitespace:
      r = initRand(int64(hash(seed)))
   else:
      let now = getTime()
      when defined(js):
         r = initRand(now.nanosecond)
      else:
         r = initRand(now.toUnix * 1_000_000 + now.nanosecond)

   let originalGeneratedGrid = generateRandomGrid(r)

   # Minimum number of clues to have a unique solution is 17
   # See https://arxiv.org/pdf/1201.0749.pdf
   const minNbCellsToSolve = 17
   const nbMaxRemovableCells = 9 * 9 - minNbCellsToSolve

   let nbCellsToRemove = int(
      nbMaxRemovableCells * clamp(difficulty, 0, 100) / 100)

   result = originalGeneratedGrid
   var randomGridPos = toSeq(gridPos())
   shuffle(r, randomGridPos)

   var nbCellsRemoved = 0
   while len(randomGridPos) > 0 and nbCellsRemoved < nbCellsToRemove:
      let p = randomGridPos.pop()
      result[p] = 0

      var gCopy = result

      let resultInfo = gCopy.solve(SolveOpts(
         randomizeBacktracingIndices: false,
         checkIfMultipleSolutionsExists: true))

      if resultInfo.multipleGridsExist:
         result[p] = originalGeneratedGrid[p]
      else:
         inc(nbCellsRemoved)

{.pop.}

## CLI Command

when isMainModule and appType == "console" and not defined(js):
   import parseopt

   const version = 0.1

   type
      CmdOpt = object
         showHelp: bool
         showVersion: bool
         outputFilePath: string
         showGrids: bool
         gridToSolvePath: string
         generate: bool
         generateSeed: string
         generateDifficulty: int
         showTime: bool
         solutionGridFilePath: string

   proc createCmdOpt(): CmdOpt =
      result.showHelp = false
      result.showVersion = false
      result.outputFilePath = ""
      result.showGrids = false
      result.gridToSolvePath = ""
      result.generate = false
      result.generateDifficulty = 0
      result.generateSeed = ""
      result.showTime = false
      result.solutionGridFilePath = ""

   proc versionStr(): string = return "nim-sudoku " & $version

   proc helpStr(): string =
      return versionStr() & "\n" & """

Options:
  -h --help                Show this screen
  --version                Show version
  --solve=[string]         Solve the sudoku at the given filepath
  --generate=[0-100]       Generates a sudoku grid with the given difficulty
  --generateSeed=[string]  Seed for generating the grid
  --showGrids              Show sudoku grids
  --outputFile=[string]    Write result sudoku in the given file path
  --showTime               Show solving time
  --checkWith=[string]     Check result sudoku with the given solution

Usage:
  # Solve a sudoku grid and show it with elapsed time
  nim-sudoku --solve=grid.txt --showGrids --showTime

  # Generate a sudoku grid and writes it into a file
  nim-sudoku --generate=50 --showGrids --showTime --outputFile=test1.txt

Notes:
  Format for sudoku grid is:
    - each column is separated by a space
    - each row is separated by a new line
   """

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
            of "generateSeed": cmdOpt.generateSeed = val
            of "showTime": cmdOpt.showTime = true
            of "checkWith": cmdOpt.solutionGridFilePath = val
         of cmdEnd: assert(false)

      if cmdOpt.showHelp:
         echo helpStr()
      elif cmdOpt.showVersion:
         echo versionStr()
      elif not cmdOpt.gridToSolvePath.isEmptyOrWhitespace:
         var grid = readSudokuGridFromFile(cmdOpt.gridToSolvePath)

         if cmdOpt.showGrids:
            echo "Input Grid"
            echo grid.fancyStr()

         let startTime = cpuTime()
         grid.solve()
         let duration = cpuTime() - startTime

         if cmdOpt.showGrids:
            echo "Solved Grid"
            echo grid.fancyStr()

         if not cmdOpt.solutionGridFilePath.isEmptyOrWhitespace:
            let solutionGrid = readSudokuGridFromFile(
               cmdOpt.solutionGridFilePath)
            if grid == solutionGrid:
               echo "Solved grid and given solution grid are same!"
            else:
               echo "Solved grid and given solution grid are different!"
               if cmdOpt.showGrids:
                  echo solutionGrid.fancyStr()

         if cmdOpt.showTime:
            let elapsedStr = duration.formatFloat(format=ffDecimal, precision=9)
            echo "Solving time: " & $elapsedStr & "s"

         if not cmdOpt.outputFilePath.isEmptyOrWhitespace:
            grid.writeToFile(cmdOpt.outputFilePath)

      elif cmdOpt.generate:
         let startTime = cpuTime()
         var grid = generateGrid(cmdOpt.generateDifficulty, cmdOpt.generateSeed)
         let duration = cpuTime() - startTime

         if cmdOpt.showGrids:
            echo "Generated Grid"
            echo grid.fancyStr()

         if cmdOpt.showTime:
            let elapsedStr = duration.formatFloat(format=ffDecimal, precision=9)
            echo "Generating time: " & $elapsedStr & "s"

         if not cmdOpt.outputFilePath.isEmptyOrWhitespace:
            grid.writeToFile(cmdOpt.outputFilePath)
      else:
         echo helpStr()

   main()
