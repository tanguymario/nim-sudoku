import sequtils

type
   Pos* = array[2, int]

   # TODO maybe change to set
   SudokuCell* = seq[int]
   SudokuGrid* = array[9, array[9, SudokuCell]]

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

iterator cases*(): Pos =
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

proc filled*(c: SudokuCell): bool = return len(c) == 1
proc filled*(c: SudokuCell, v: int): bool =
   return c.filled and c[0] == v

proc isPossible*(c: SudokuCell, v: int): bool =
   return not c.filled and c.contains(v)

proc filledAt*(g: SudokuGrid, pos: openArray[Pos]): bool =
   for p in pos:
      if g[p].filled:
         return true
   return false

proc filledAt*(g: SudokuGrid, pos: openArray[Pos], v: int): bool =
   for p in pos:
      if g[p].filled(v):
         return true
   return false

proc isPossibleAt*(g: SudokuGrid, pos: openArray[Pos], v: int): bool =
   for p in pos:
      if g[p].isPossible(v):
         return true
   return false

proc possiblePosAt*(g: SudokuGrid, pos: openArray[Pos], v: int): seq[Pos] =
   for p in pos:
      if g[p].isPossible(v):
         result.add(p)

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
         result &= (if g[y][x].filled: $g[y][x][0] else: " ")
         result &= (if (x + 1) mod 3 == 0: " ║ " else: " ")
      result &= "\n"
   result &= "╚═══════╩═══════╩═══════╝\n"

proc debug*(g: SudokuGrid): string =
   for p in gridPos():
      result &= $p & " " & $g[p] & "\n"

proc removePossibility(g: var SudokuGrid, p: Pos, v: int)
proc checkForcedDigit(g: var SudokuGrid, p: Pos, v: int)
proc checkForcedPairs(g: var SudokuGrid)
proc onFilled(g: var SudokuGrid, p: Pos)
proc fill(g: var SudokuGrid, p: Pos, v: int)

proc checkForcedDigit(g: var SudokuGrid, p: Pos, v: int) =
   var caseConnectedPos: array[3, seq[Pos]]
   caseConnectedPos[0] = toSeq(rowPos(p.y))
   caseConnectedPos[1] = toSeq(colPos(p.x))
   caseConnectedPos[2] = toSeq(casePos(p))
   for i in 0 ..< 3:
      let possiblePos = g.possiblePosAt(caseConnectedPos[i], v)
      if len(possiblePos) == 1:
         g.fill(possiblePos[0], v)

# https://homepages.cwi.nl/~aeb/games/sudoku/solving5.html
proc checkForcedPairs(g: var SudokuGrid) =
   for c in cases():
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
proc checkTwoPairs(g: var SudokuGrid) =
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

proc removePossibility(g: var SudokuGrid, p: Pos, v: int) =
   let idx = g[p].find(v)
   if idx >= 0:
      echo $p & ": removed " & $v
      g[p].del(idx)
      if g[p].filled:
         g.onFilled(p)

proc onFilled(g: var SudokuGrid, p: Pos) =
   for pp in rowColCasePos(p):
      if p != pp:
         g.removePossibility(pp, g[p][0])

proc fill(g: var SudokuGrid, p: Pos, v: int) =
   g[p] = @[v]
   g.onFilled(p)

proc createSudokuGrid*(m: array[9, array[9, int]]): SudokuGrid =
   for p in gridPos():
      if m[p] == 0:
         result[p] = @[1, 2, 3, 4, 5, 6, 7, 8, 9]
      else:
         result[p] = @[m[p]]

proc solveWithConstraint*(g: var SudokuGrid) =
   for p in gridPos():
      if g[p].filled:
         g.onFilled(p)

   # echo debug(g)

   var nbIters = 0
   while true:
      let gCopy = deepCopy(g)

      inc(nbIters)
      echo "Iter num " & $nbIters

      for p in gridPos():
         for v in 1 .. 9:
            g.checkForcedDigit(p, v)

      g.checkForcedPairs()

      g.checkTwoPairs()

      if g == gCopy:
         break

   echo "Number of iterations: " & $nbIters
   echo "Grid is " & (if g.full: "full" else: "not full")
   # echo debug(g)

## Backtracing

proc solveWithBacktracing*(g: var SudokuGrid) =
   for p in gridPos():
      if g[p].filled:
         g.onFilled(p)

   var indices: array[9, array[9, int]]
   for p in gridPos():
      indices[p] = 0

   let originalGrid = deepCopy(g)

   var filled: array[9, array[9, bool]]
   for p in gridPos():
      filled[p] = g[p].filled
      if not filled[p]:
         g[p].setLen(1)

   var p = Pos([0, 0])
   while not p.outOfBounds:
      if not filled[p]:
         let v = originalGrid[p][indices[p]]
         var invalid = false
         for pp in rowColCasePos(p):
            if pp != p and filled[pp] and g[pp][0] == v:
               invalid = true
               break

         if invalid:
            while true:
               if indices[p] < len(originalGrid[p]) - 1:
                  indices[p] += 1
                  break
               else:
                  indices[p] = 0
                  filled[p] = false

                  while true:
                     p.prev()
                     if p.outOfBounds:
                        return
                     if not originalGrid[p].filled:
                        filled[p] = false
                        break

         else:
            g[p][0] = v
            filled[p] = true
            p.next()
      else:
         p.next()

## Constraint Programming
