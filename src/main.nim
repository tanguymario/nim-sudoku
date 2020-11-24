import algorithm
import random

randomize()

type
   SudokuCell* = seq[int]
   SudokuGrid* = array[9, array[9, SudokuCell]]

proc filled(c: SudokuCell): bool = return len(c) == 1

proc full(g: SudokuGrid): bool =
   for row in g:
      for cell in row:
         if not cell.filled:
            return false
   return true

proc broken(g: SudokuGrid): bool =
   for row in 0 ..< 9:
      for col in 0 ..< 9:
         for tmpRow in 0 ..< 9:
            if row != tmpRow:
               if g[row][col].filled and g[row][col] == g[tmpRow][col]:
                  return true
         for tmpCol in 0 ..< 9:
            if col != tmpCol:
               if g[row][col].filled and g[row][col] == g[row][tmpCol]:
                  return true
         for y in 0 ..< 3:
            for x in 0 ..< 3:
               let tmpRow = int(row / 3) * 3 + y
               let tmpCol = int(col / 3) * 3 + x
               if tmpRow != row and tmpCol != col:
                  if g[row][col].filled and g[row][col] == g[row][tmpCol]:
                     return true

   return false

proc `$`*(g: SudokuGrid): string =
   result = ""
   result &= "╔═══════╦═══════╦═══════╗\n"
   for row in 0 ..< 9:
      if row > 0 and row mod 3 == 0:
         result &= "╠═══════╬═══════╬═══════╣\n"
      result &= "║ "
      for col in 0 ..< 9:
         result &= (if g[row][col].filled: $g[row][col][0] else: " ")
         result &= (if (col + 1) mod 3 == 0: " ║ " else: " ")
      result &= "\n"
   result &= "╚═══════╩═══════╩═══════╝\n"

proc debug(g: SudokuGrid): string =
   result = ""
   for row in 0 ..< 9:
      for col in 0 ..< 9:
         result &= "(" & $row & ", " & $col & ") " & $g[row][col] & "\n"

proc removePossibility(c: var SudokuCell, val: int): bool =
   if not c.filled:
      let idx = c.find(val)
      if idx >= 0:
         c.delete(idx)
         return true
   return false

proc createSudokuGrid*(m: array[9, array[9, int]]): SudokuGrid =
   for row in 0 ..< 9:
      for col in 0 ..< 9:
         if m[row][col] != 0:
            result[row][col].add(m[row][col])
         else:
            for i in 1 .. 9:
               result[row][col].add(i)

proc checkBasic(g: var SudokuGrid) =
   var canSolve = true
   while canSolve:
      canSolve = false
      for row in 0 ..< 9:
         for col in 0 ..< 9:
            if not g[row][col].filled:
               for tmpCol in 0 ..< 9:
                  if g[row][tmpCol].filled:
                     canSolve = canSolve or g[row][col].removePossibility(g[row][tmpCol][0])
               for tmpRow in 0 ..< 9:
                  if g[tmpRow][col].filled:
                     canSolve = canSolve or g[row][col].removePossibility(g[tmpRow][col][0])
               for y in 0 ..< 3:
                  for x in 0 ..< 3:
                     let tmpRow = int(row / 3) * 3 + y
                     let tmpCol = int(col / 3) * 3 + x
                     if g[tmpRow][tmpCol].filled:
                        canSolve = canSolve or g[row][col].removePossibility(g[tmpRow][tmpCol][0])

proc solve(g: var SudokuGrid) =
   g.checkBasic()

   var maxIter = 10
   var iter = 0
   while not g.full:

      iter += 1
      if iter >= maxIter:
         break
   echo iter
   echo (debug(g))

proc main*() =
   # var grid: SudokuGrid = [
   #    [0, 0, 0, 0, 0, 0, 0, 0, 0],
   #    [0, 0, 0, 0, 0, 0, 0, 0, 0],
   #    [0, 0, 0, 0, 0, 0, 0, 0, 0],
   #    [0, 0, 0, 0, 0, 0, 0, 0, 0],
   #    [0, 0, 0, 0, 0, 0, 0, 0, 0],
   #    [0, 0, 0, 0, 0, 0, 0, 0, 0],
   #    [0, 0, 0, 0, 0, 0, 0, 0, 0],
   #    [0, 0, 0, 0, 0, 0, 0, 0, 0],
   #    [0, 0, 0, 0, 0, 0, 0, 0, 0],
   # ]

   # Easy - Arizona Daily Wildcat: Tuesday, Jan 17th 2006
   # var grid: SudokuGrid = [
   #    [0, 0, 0, 2, 6, 0, 7, 0, 1],
   #    [6, 8, 0, 0, 7, 0, 0, 9, 0],
   #    [1, 9, 0, 0, 0, 4, 5, 0, 0],
   #    [8, 2, 0, 1, 0, 0, 0, 4, 0],
   #    [0, 0, 4, 6, 0, 2, 9, 0, 0],
   #    [0, 5, 0, 0, 0, 3, 0, 2, 8],
   #    [0, 0, 9, 3, 0, 0, 0, 7, 4],
   #    [0, 4, 0, 0, 5, 0, 0, 3, 6],
   #    [7, 0, 3, 0, 1, 8, 0, 0, 0],
   # ]

   # Easy - Arizona Daily Wildcat: Wednesday, Jan 18th 2006
   var grid = createSudokuGrid([
      [1, 0, 0, 4, 8, 9, 0, 0, 6],
      [7, 3, 0, 0, 0, 0, 0, 4, 0],
      [0, 0, 0, 0, 0, 1, 2, 9, 5],
      [0, 0, 7, 1, 2, 0, 6, 0, 0],
      [5, 0, 0, 7, 0, 3, 0, 0, 8],
      [0, 0, 6, 0, 9, 5, 7, 0, 0],
      [9, 1, 4, 6, 0, 0, 0, 0, 0],
      [0, 2, 0, 0, 0, 0, 0, 3, 7],
      [8, 0, 0, 5, 1, 2, 0, 0, 4],
   ])

   # Intermediate - Daily Telegraph January 19th "Diabolical"
   # var grid = createSudokuGrid([
   #    [0, 2, 0, 6, 0, 8, 0, 0, 0],
   #    [5, 8, 0, 0, 0, 9, 7, 0, 0],
   #    [0, 0, 0, 0, 4, 0, 0, 0, 0],
   #    [3, 7, 0, 0, 0, 0, 5, 0, 0],
   #    [6, 0, 0, 0, 0, 0, 0, 0, 4],
   #    [0, 0, 8, 0, 0, 0, 0, 1, 3],
   #    [0, 0, 0, 0, 2, 0, 0, 0, 0],
   #    [0, 0, 9, 8, 0, 0, 0, 3, 6],
   #    [0, 0, 0, 3, 0, 6, 0, 9, 0],
   # ])

   # Hard
   # var grid: SudokuGrid = [
   #    [0, 0, 0, 6, 0, 0, 4, 0, 0],
   #    [7, 0, 0, 0, 0, 3, 6, 0, 0],
   #    [0, 0, 0, 0, 9, 1, 0, 8, 0],
   #    [0, 0, 0, 0, 0, 0, 0, 0, 0],
   #    [0, 5, 0, 1, 8, 0, 0, 0, 3],
   #    [0, 0, 0, 3, 0, 6, 0, 4, 5],
   #    [0, 4, 0, 2, 0, 0, 0, 6, 0],
   #    [9, 0, 3, 0, 0, 0, 0, 0, 0],
   #    [0, 2, 0, 0, 0, 0, 1, 0, 0],
   # ]

   # Test
   # var grid = createSudokuGrid([
   #    [0, 0, 0, 7, 2, 1, 5, 8, 6],
   #    [0, 0, 0, 0, 8, 0, 7, 0, 0],
   #    [0, 0, 0, 0, 0, 0, 0, 0, 0],
   #    [0, 0, 0, 0, 0, 0, 0, 0, 0],
   #    [0, 0, 0, 0, 0, 0, 2, 0, 1],
   #    [0, 0, 0, 5, 0, 0, 0, 0, 0],
   #    [0, 0, 0, 0, 5, 0, 0, 0, 0],
   #    [0, 0, 0, 0, 0, 0, 1, 0, 0],
   #    [0, 0, 0, 0, 0, 0, 0, 0, 2],
   # ])

   echo(grid)

   grid.solve()

   echo(grid)

main()
