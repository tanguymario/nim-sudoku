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

iterator casePos*(p: Pos): Pos =
   let caseY = int(p.y / 3)
   let caseX = int(p.x / 3)
   for y in 0 ..< 3:
      for x in  0 ..< 3:
         yield Pos([caseY * 3 + y, caseX * 3 + x])

iterator rowPos*(y: int): Pos =
   for x in 0 ..< 9:
      yield Pos([y, x])

iterator colPos*(x: int): Pos =
   for y in 0 ..< 9:
      yield Pos([y, x])

iterator rowColCasePos*(p: Pos): Pos =
   for pRowCell in rowPos(p.y):
      yield pRowCell
   for pColCell in colPos(p.x):
      yield pColCell
   for pCaseCell in casePos(p):
      yield pCaseCell

proc filled*(c: SudokuCell): bool = return len(c) == 1

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
   # TODO maybe change that
   if not g[p].filled:
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

   # for caseY in 0 ..< 3:
   #    for caseX in 0 ..< 3:
   #       for num in 1 .. 9:
   #          var filled = false
   #          for p in allcasePos(caseY, caseX):
   #             if g[p.y][p.x].filled and g[p.y][p.x][0] == num:
   #                filled = true
   #                break

   #          if not filled:
   #             for row in 0 ..< 3:
   #                discard
   #             for col in 0 ..< 3:
   #                discard

   echo debug(g)
