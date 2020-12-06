import strutils
import sequtils
import random
import math

randomize()

## Util to get position in the sudoku grid

type
   Pos* = array[2, int]

proc y*(p: Pos): int = return p[0]
proc x*(p: Pos): int = return p[1]
proc `y=`*(p: var Pos, v: int) = p[0] = v
proc `x=`*(p: var Pos, v: int) = p[1] = v

proc outOfBounds*(p: Pos): bool =
   return p.x < 0 or p.x >= 9 or p.y < 0 or p.y >= 9

proc next*(p: var Pos) =
   if p.x >= 8:
      p.y = p.y + 1
      p.x = 0
   else:
      p.x = p.x + 1
proc prev*(p: var Pos) =
   if p.x <= 0:
      p.y = p.y - 1
      p.x = 8
   else:
      p.x = p.x - 1

## Sudoku Cell and Grid

type
   SudokuCell* = int
   SudokuGrid* = array[9, array[9, SudokuCell]]

proc `[]`*[T](g: array[9, array[9, T]], y, x: int): T = return g[y][x]
proc `[]`*[T](g: var array[9, array[9, T]], y, x: int): var T = return g[y][x]
proc `[]=`*[T](g: var array[9, array[9, T]], y, x: int, v: T) = g[y][x] = v

proc `[]`*[T](g: array[9, array[9, T]], p: Pos): T = return g[p.y][p.x]
proc `[]`*[T](g: var array[9, array[9, T]], p: Pos): var T = return g[p.y][p.x]
proc `[]=`*[T](g: var array[9, array[9, T]], p: Pos, v: T) = g[p.y][p.x] = v

iterator pos*(topLeft, bottomRight: Pos): Pos =
   var p = topLeft
   yield p
   while not p.outOfBounds and p != bottomRight:
      p.next()
      yield p

iterator gridPos*(): Pos =
   for y in 0 ..< 9:
      for x in  0 ..< 9:
         yield Pos([y, x])

iterator gridCases*(): Pos =
   for y in 0 ..< 3:
      for x in 0 ..< 3:
         yield Pos([y * 3, x * 3])

iterator casePos*(p: Pos): Pos =
   let caseY = int(p.y / 3)
   let caseX = int(p.x / 3)
   for y in 0 ..< 3:
      for x in  0 ..< 3:
         yield Pos([caseY * 3 + y, caseX * 3 + x])

iterator colPos*(x: int): Pos =
   for y in 0 ..< 9:
      yield Pos([y, x])

iterator rowPos*(y: int): Pos =
   for x in 0 ..< 9:
      yield Pos([y, x])

iterator rowColCasePos*(p: Pos): Pos =
   for rp in rowPos(p.y):
      yield rp
   for cp in colPos(p.x):
      yield cp
   for caseP in casePos(p):
      yield caseP

iterator fromTo*(p1, p2: Pos): Pos =
   for y in p1.y .. p2.y:
      for x in p1.x .. p2.x:
         yield Pos([y, x])

proc `[]`*[T](g: array[9, array[9, T]], p1, p2: Pos): seq[T] =
   result = @[]
   for p in fromTo(p1, p2):
      result.add(g[p])
proc `[]`*[T](g: var array[9, array[9, T]], p1, p2: Pos): seq[T] =
   result = @[]
   for p in fromTo(p1, p2):
      result.add(g[p])

proc filled*(c: SudokuCell): bool = return c != 0
proc filled*(c, v: SudokuCell): bool = return c == v

proc filledAt*(g: SudokuGrid, pos: openArray[Pos]): bool =
   for p in pos:
      if g[p].filled:
         return true
   return false

proc filledAt*(g: SudokuGrid, pos: openArray[Pos], v: SudokuCell): bool =
   for p in pos:
      if g[p].filled(v):
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

proc getRawStr*(g: SudokuGrid): string =
   for y in 0 ..< 9:
      result &= join(g[y], " ") & "\n"

proc `$`*(g: SudokuGrid): string =
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

proc createSudokuGrid*(): SudokuGrid =
   for p in gridPos():
      result[p] = 0

proc createSudokuGrid*(m: array[9, array[9, SudokuCell]]): SudokuGrid =
   for p in gridPos():
      result[p] = m[p]

proc createSudokuGrid*(filePath: string): SudokuGrid =
   let gridStr = readFile(filePath).split({'\n', ' '})
   for p in gridPos():
      result[p] = parseInt(gridStr[p.y * 9 + p.x])

proc writeToFile*(g: SudokuGrid, filePath: string) =
   let f = open(filePath, fmWrite)
   f.write(g.getRawStr())
   f.close()

## Sudoku Cell and Grid Solvers. They represent the possibilities of the sudoku

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
                     let p = Pos([caseY * 3 + y, caseX * 3 + x])
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

type
   SolveOpts* = object
      randomizeBacktracingIndices: bool
      checkIfMultipleSolutionsExists: bool

   SolveResultInfo* = object
      solutionFound: bool
      multipleGridsExist: bool

proc init(resultInfo: var SolveResultInfo) =
   resultInfo.solutionFound = false
   resultInfo.multipleGridsExist = false

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
      for cell in cells:
         cell.possibilities.shuffle()

   var i = 0

   let increaseValueOrGoBack = proc(g: var SudokuGrid): bool =
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
         if not increaseValueOrGoBack(g):
            return
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
               if not increaseValueOrGoBack(g):
                  return

proc solve*(g: var SudokuGrid, opts: SolveOpts): SolveResultInfo =
   result.init()
   if not g.broken:
      var sg = createSolverGrid(g)
      sg.apply(g)
      g.backtracing(sg, opts, result)

proc solve*(g: var SudokuGrid) =
   discard g.solve(SolveOpts(
      randomizeBacktracingIndices: false,
      checkIfMultipleSolutionsExists: false))

## Generate Sudoku

proc generateNaiveFullGrid*(): SudokuGrid = result.solve()
const NaiveGeneratedFullGrid*: SudokuGrid = generateNaiveFullGrid()

proc generateRandomFullGrid*(): SudokuGrid =
   discard result.solve(SolveOpts(
      randomizeBacktracingIndices: true,
      checkIfMultipleSolutionsExists: false))

proc exchangeCols*(g: var SudokuGrid, firstCol, secondCol: int) =
   for y in 0 ..< 9:
      let tmp = g[y, firstCol]
      g[y, firstCol] = g[y, secondCol]
      g[y, secondCol] = tmp

proc exchangeRows*(g: var SudokuGrid, firstRow, secondRow: int) =
   for x in 0 ..< 9:
      let tmp = g[firstRow, x]
      g[firstRow, x] = g[secondRow, x]
      g[secondRow, x] = tmp

proc exchangeRowsGroups*(g: var SudokuGrid) =
   for y in 0 ..< 3:
      g.exchangeRows(y, 3 + y)
   for y in 0 ..< 3:
      g.exchangeRows(3 + y, 6 + y)

proc exchangeColsGroups*(g: var SudokuGrid) =
   for x in 0 ..< 3:
      g.exchangeCols(x, 3 + x)
   for x in 0 ..< 3:
      g.exchangeRows(3 + x, 6 + x)

proc transpose*(g: var SudokuGrid) =
   var gCopy = g
   for p in gridPos():
      g[p.y, p.x] = gCopy[p.x, p.y]

proc generate*(difficulty: int): SudokuGrid =
   let originalGeneratedGrid = generateRandomFullGrid()

   # Minimum number of clues to have a unique solution is 17
   # See https://arxiv.org/pdf/1201.0749.pdf
   const nbMaxRemovableCells = 9 * 9 - 17
   var nbCellsToRemove = int(
      nbMaxRemovableCells * clamp(difficulty, 0, 100) / 100)

   while true:
      result = originalGeneratedGrid

      var randomGridPos = toSeq(gridPos())
      randomGridPos.shuffle()

      for i in 0 ..< nbCellsToRemove:
         result[randomGridPos.pop()] = 0

      var gCopy = result

      let resultInfo = gCopy.solve(SolveOpts(
         randomizeBacktracingIndices: false,
         checkIfMultipleSolutionsExists: true))

      if not resultInfo.multipleGridsExist:
         break
