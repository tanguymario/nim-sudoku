import strutils

type
   Pos* = array[2, int]

   SudokuCell* = int
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
