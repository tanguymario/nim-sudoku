import strutils
import bitops

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

proc createSudokuGrid*(m: array[9, array[9, SudokuCell]]): SudokuGrid =
   for p in gridPos():
      result[p] = m[p]

proc createSudokuGrid*(filePath: string): SudokuGrid =
   let gridStr = readFile(filePath).split({'\n', ' '})
   for p in gridPos():
      result[p] = parseInt(gridStr[p.y * 9 + p.x])

## Sudoku Cell and Grid Solvers. They represent the possibilities of the sudoku

type
   SolverCell* = uint16
   SolverGrid* = array[9, array[9, SolverCell]]

proc nbPossibilities*(c: SolverCell): int = return countSetBits(c)
proc filled*(c: SolverCell): bool = return c.nbPossibilities == 1
proc value*(c: SolverCell): SudokuCell =
   return (if c.filled: firstSetBit(c) - 1 else: 0)

proc isPossible*(c: SolverCell, v: SudokuCell): bool = return c.testBit(v)

iterator possibilities(c: SolverCell): SudokuCell =
   for i in 1 .. 9:
      if c.isPossible(i):
         yield i

proc `[]`*(c: SolverCell, i: int): SudokuCell =
   var tmpI = 0

   for possibility in c.possibilities:
      if i == tmpI:
         return possibility
      inc(tmpI)
   return -1

proc `$`*(g: SolverGrid): string =
   for p in gridPos():
      result &= $p & "["
      for possibility in g[p].possibilities:
         result &= $possibility & ", "
      result &= "]" & "\n"

proc removePossibility(g: var SolverGrid, p: Pos, v: SudokuCell)
proc onFilled(g: var SolverGrid, p: Pos)
proc fill(g: var SolverGrid, p: Pos, v: SudokuCell)

proc removePossibility(g: var SolverGrid, p: Pos, v: SudokuCell) =
   if not g[p].filled:
      g[p].clearBit(v)
      if g[p].filled:
         g.onFilled(p)

proc onFilled(g: var SolverGrid, p: Pos) =
   for pp in rowColCasePos(p):
      if p != pp:
         g.removePossibility(pp, g[p].value)

proc fill(g: var SolverGrid, p: Pos, v: SudokuCell) =
   g[p] = 0
   g[p].setBit(v)
   g.onFilled(p)

# proc checkForcedDigit(g: var SudokuCPGrid, p: Pos, v: SudokuCell) =
#    var caseConnectedPos: array[3, seq[Pos]]
#    caseConnectedPos[0] = toSeq(rowPos(p.y))
#    caseConnectedPos[1] = toSeq(colPos(p.x))
#    caseConnectedPos[2] = toSeq(casePos(p))
#    for i in 0 ..< 3:
#       let possiblePos = g.possiblePosAt(caseConnectedPos[i], v)
#       if len(possiblePos) == 1:
#          g.fill(possiblePos[0], v)

# proc checkForcedPairs(g: var SudokuCPGrid) =
#    for c in gridCases():
#       for v in 1 .. 9:
#          let possiblePos = g.possiblePosAt(toSeq(casePos(c)), v)
#          if len(possiblePos) == 0:
#             continue

#          var rowsPossible = [false, false, false]
#          var colsPossible = [false, false, false]
#          for p in possiblePos:
#             rowsPossible[p.y - c.y] = true
#             colsPossible[p.x - c.x] = true

#          if rowsPossible.count(true) == 1:
#             for p in rowPos(c.y + rowsPossible.find(true)):
#                if p.x < c.x or p.x > c.x + 3:
#                   g.removePossibility(p, v)
#          elif colsPossible.count(true) == 1:
#             for p in colPos(c.x + colsPossible.find(true)):
#                if p.y < c.y or p.y > c.y + 3:
#                   g.removePossibility(p, v)

proc apply*(sg: SolverGrid, g: var SudokuGrid) =
   for p in gridPos():
      g[p] = sg[p].value

proc createSolverGrid*(g: SudokuGrid): SolverGrid =
   for p in gridPos():
      result[p] = 0
      if g[p].filled:
         result[p].setBit(g[p])
      else:
         result[p].setBits(1, 2, 3, 4, 5, 6, 7, 8, 9)

   for p in gridPos():
      if g[p].filled:
         result.onFilled(p)

## Backtracing

proc solveWithBacktracing(g: var SudokuGrid, sg: SolverGrid) =
   type
      PossibleCell = ref PossibleCellObj
      PossibleCellObj = object
         p: Pos
         ind: int

   var cells: seq[PossibleCell]
   for p in gridPos():
      if not sg[p].filled:
         cells.add(PossibleCell(p: p, ind: 0))

   var iter = 0
   var i = 0
   while i < len(cells):
      var cell = cells[i]
      let v = sg[cell.p][cell.ind]
      var invalid = false
      for pp in rowColCasePos(cell.p):
         if pp != cell.p and g[pp].filled and g[pp] == v:
            invalid = true
            break

      if invalid:
         while true:
            if cell.ind < sg[cell.p].nbPossibilities - 1:
               cell.ind += 1
               break
            else:
               cell.ind = 0
               g[cell.p] = 0

               dec(i)
               if i < 0:
                  echo "oups"
                  return
               cell = cells[i]
      else:
         g[cell.p] = v
         inc(i)

proc solveWithBacktracing*(g: var SudokuGrid) =
   var sg = createSolverGrid(g)
   sg.apply(g)
   g.solveWithBacktracing(sg)
