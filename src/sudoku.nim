import sequtils

type
   Pos* = array[2, int]

   SudokuCell* = seq[int]
   SudokuGrid* = array[9, array[9, SudokuCell]]

proc y*(p: Pos): int = return p[0]
proc x*(p: Pos): int = return p[1]

proc `[]`*(g: SudokuGrid, p: Pos): SudokuCell = return g[p.y][p.x]
proc `[]`*(g: var SudokuGrid, p: Pos): var SudokuCell = return g[p.y][p.x]
proc `[]=`*(g: var SudokuGrid, p: Pos, c: SudokuCell) = g[p.y][p.x] = c

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

proc onFilled(g: var SudokuGrid, p: Pos)
proc removePossibility(g: var SudokuGrid, p: Pos, v: int) =
   let idx = g[p].find(v)
   if idx >= 0:
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
      if m[p.y][p.x] == 0:
         result[p] = @[1, 2, 3, 4, 5, 6, 7, 8, 9]
      else:
         result[p] = @[m[p.y][p.x]]

proc solve*(g: var SudokuGrid) =
   for p in gridPos():
      if g[p].filled:
         g.onFilled(p)

   # echo debug(g)

   var maxIters = 10
   var iter = 0
   while iter < maxIters:
      for c in cases():
         for v in 1 .. 9:
            let possiblePos = g.possiblePosAt(toSeq(casePos(c)), v)
            if len(possiblePos) > 0 and len(possiblePos) <= 3:
               var iSameRow = possiblePos[0].y
               var iSameCol = possiblePos[0].x
               for pp in possiblePos:
                  if pp.x != possiblePos[0].x:
                     iSameCol = -1
                  if pp.y != possiblePos[0].y:
                     iSameRow = -1
               if iSameRow > 0:
                  for rp in rowPos(iSameRow):
                     # echo (rp, v)
                     if rp notin possiblePos and not g[rp].filled:
                        # if g[rp].isPossible(v):
                           # echo (rp, v)
                        g.removePossibility(rp, v)
               elif iSameCol > 0:
                  for cp in colPos(iSameCol):
                     # echo (cp, v)
                     if cp notin possiblePos and not g[cp].filled:
                        # if g[cp].isPossible(v):
                           # echo (cp, v)
                        g.removePossibility(cp, v)

      for v in 1 .. 9:
         for y in 0 ..< 9:
            let possiblePos = g.possiblePosAt(toSeq(rowPos(y)), v)
            if len(possiblePos) == 1:
               g.fill(possiblePos[0], v)
         for x in 0 ..< 9:
            let possiblePos = g.possiblePosAt(toSeq(rowPos(x)), v)
            if len(possiblePos) == 1:
               g.fill(possiblePos[0], v)
         for c in cases():
            let possiblePos = g.possiblePosAt(toSeq(casePos(c)), v)
            if len(possiblePos) == 1:
               g.fill(possiblePos[0], v)

      inc(iter)

   # echo debug(g)
