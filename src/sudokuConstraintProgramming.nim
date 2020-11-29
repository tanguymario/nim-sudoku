import sudoku
import sequtils

type
   SudokuCPCell* = seq[SudokuCell]
   SudokuCPGrid* = array[9, array[9, SudokuCPCell]]

proc filled*(c: SudokuCPCell): bool = return len(c) == 1
proc value*(c: SudokuCPCell): SudokuCell = return (if c.filled: c[0] else: 0)
proc filled*(c1: SudokuCPCell, c2: SudokuCell): bool = return c1.value == c2

proc isPossible*(c: SudokuCPCell, v: SudokuCell): bool =
   return not c.filled and c.contains(v)

proc isPossibleAt*(g: SudokuCPGrid, pos: openArray[Pos], v: SudokuCell): bool =
   for p in pos:
      if g[p].isPossible(v):
         return true
   return false

proc possiblePosAt*(
   g: SudokuCPGrid, pos: openArray[Pos], v: SudokuCell): seq[Pos] =
   for p in pos:
      if g[p].isPossible(v):
         result.add(p)

proc debug*(g: SudokuCPGrid): string =
   for p in gridPos():
      result &= $p & " " & $g[p] & "\n"

proc removePossibility(g: var SudokuCPGrid, p: Pos, v: SudokuCell)
proc checkForcedDigit(g: var SudokuCPGrid, p: Pos, v: SudokuCell)
proc checkForcedPairs(g: var SudokuCPGrid)
proc onFilled(g: var SudokuCPGrid, p: Pos)
proc fill(g: var SudokuCPGrid, p: Pos, v: SudokuCell)

proc checkForcedDigit(g: var SudokuCPGrid, p: Pos, v: SudokuCell) =
   var caseConnectedPos: array[3, seq[Pos]]
   caseConnectedPos[0] = toSeq(rowPos(p.y))
   caseConnectedPos[1] = toSeq(colPos(p.x))
   caseConnectedPos[2] = toSeq(casePos(p))
   for i in 0 ..< 3:
      let possiblePos = g.possiblePosAt(caseConnectedPos[i], v)
      if len(possiblePos) == 1:
         g.fill(possiblePos[0], v)

# https://homepages.cwi.nl/~aeb/games/sudoku/solving5.html
proc checkForcedPairs(g: var SudokuCPGrid) =
   for c in gridCases():
      for v in 1 .. 9:
         let possiblePos = g.possiblePosAt(toSeq(casePos(c)), v)
         if len(possiblePos) == 0:
            continue

         var rowsPossible = [false, false, false]
         var colsPossible = [false, false, false]
         for p in possiblePos:
            rowsPossible[p.y - c.y] = true
            colsPossible[p.x - c.x] = true

         if rowsPossible.count(true) == 1:
            for p in rowPos(c.y + rowsPossible.find(true)):
               if p.x < c.x or p.x > c.x + 3:
                  g.removePossibility(p, v)
         elif colsPossible.count(true) == 1:
            for p in colPos(c.x + colsPossible.find(true)):
               if p.y < c.y or p.y > c.y + 3:
                  g.removePossibility(p, v)

# https://homepages.cwi.nl/~aeb/games/sudoku/solving6.html
proc checkTwoPairs(g: var SudokuCPGrid) =
   for v in 1 .. 9:
      for caseY in 0 ..< 3:
         var possibilities: array[3, seq[Pos]]
         for caseX in 0 ..< 3:
            possibilities[caseX] = g.possiblePosAt(toSeq(casePos(Pos([caseY * 3, caseX * 3]))), v)
         # TODO
      for caseX in 0 ..< 3:
         var possibilities: array[3, seq[Pos]]
         for caseY in 0 ..< 3:
            possibilities[caseY] = g.possiblePosAt(toSeq(casePos(Pos([caseY * 3, caseX * 3]))), v)
         # TODO

proc removePossibility(g: var SudokuCPGrid, p: Pos, v: SudokuCell) =
   let idx = g[p].find(v)
   if idx >= 0:
      # echo $p & ": removed " & $v
      g[p].del(idx)
      if g[p].filled:
         g.onFilled(p)

proc onFilled(g: var SudokuCPGrid, p: Pos) =
   for pp in rowColCasePos(p):
      if p != pp:
         g.removePossibility(pp, g[p][0])

proc fill(g: var SudokuCPGrid, p: Pos, v: SudokuCell) =
   g[p] = @[v]
   g.onFilled(p)

proc createSudokuCPGrid*(g: SudokuGrid): SudokuCPGrid =
   for p in gridPos():
      if g[p].filled:
         result[p] = @[g[p]]
      else:
         result[p] = @[1, 2, 3, 4, 5, 6, 7, 8, 9]

   for p in gridPos():
      if g[p].filled:
         result.onFilled(p)

proc solveWithConstraintProgramming*(g: var SudokuGrid) =
   var cpGrid = createSudokuCPGrid(g)

   var nbIters = 0
   # while true:
   #    break
   # let cpGridCopy = deepCopy(cpGrid)

   # inc(nbIters)
   # echo "Iter num " & $nbIters

   # for p in gridPos():
   #    for v in 1 .. 9:
   #       cpGrid.checkForcedDigit(p, v)

   # cpGrid.checkForcedPairs()

   # cpGrid.checkTwoPairs()

   # if cpGrid == cpGridCopy:
   #    break

   # TODO write grid
   for p in gridPos():
      g[p] = cpGrid[p].value

   # echo "Number of iterations: " & $nbIters
   # echo "Grid is " & (if g.full: "full" else: "not full")
   # echo debug(g)
