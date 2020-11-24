type
   Pos = object
      y, x: int

   SudokuCell* = seq[int]
   SudokuGrid* = array[9, array[9, SudokuCell]]

proc filled(c: SudokuCell): bool = return len(c) == 1

proc full(g: SudokuGrid): bool =
   for row in g:
      for cell in row:
         if not cell.filled:
            return false
   return true

proc `==`*(g1, g2: SudokuGrid): bool =
   for row in 0 ..< 9:
      for col in 0 ..< 9:
         if g1[row][col] != g2[row][col]:
            return false
   return true

# TODO test this function
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
                  if g[row][col].filled and g[tmpRow][tmpCol].filled:
                     if g[row][col] == g[tmpRow][tmpCol]:
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

proc onFilled(g: var SudokuGrid, row, col: int)
proc removePossibility(g: var SudokuGrid, row, col, val: int) =
   # TODO maybe change that
   if not g[row][col].filled:
      let idx = g[row][col].find(val)
      if idx >= 0:
         g[row][col].delete(idx)
         if g[row][col].filled:
            g.onFilled(row, col)

proc onFilled(g: var SudokuGrid, row, col: int) =
   for tmpRow in 0 ..< 9:
      if tmpRow != row:
         g.removePossibility(tmpRow, col, g[row][col][0])
   for tmpCol in 0 ..< 9:
      if tmpCol != col:
         g.removePossibility(row, tmpCol, g[row][col][0])
   for y in 0 ..< 3:
      for x in 0 ..< 3:
         let tmpRow = int(row / 3) * 3 + y
         let tmpCol = int(col / 3) * 3 + x
         if tmpRow != row and tmpCol != col:
            g.removePossibility(tmpRow, tmpCol, g[row][col][0])

proc fill(g: var SudokuGrid, row, col, val: int) =
   g[row][col] = @[val]
   g.onFilled(row, col)

proc createSudokuGrid*(m: array[9, array[9, int]]): SudokuGrid =
   for row in 0 ..< 9:
      for col in 0 ..< 9:
         if m[row][col] == 0:
            result[row][col] = @[1, 2, 3, 4, 5, 6, 7, 8, 9]
         else:
            result[row][col] = @[m[row][col]]

proc solve(g: var SudokuGrid) =
   for row in 0 ..< 9:
      for col in 0 ..< 9:
         if g[row][col].filled:
            g.onFilled(row, col)

   # TODO

proc main() =
   # var grid = createSudokuGrid([
   #    [0, 0, 0, 0, 0, 0, 0, 0, 0],
   #    [0, 0, 0, 0, 0, 0, 0, 0, 0],
   #    [0, 0, 0, 0, 0, 0, 0, 0, 0],
   #    [0, 0, 0, 0, 0, 0, 0, 0, 0],
   #    [0, 0, 0, 0, 0, 0, 0, 0, 0],
   #    [0, 0, 0, 0, 0, 0, 0, 0, 0],
   #    [0, 0, 0, 0, 0, 0, 0, 0, 0],
   #    [0, 0, 0, 0, 0, 0, 0, 0, 0],
   #    [0, 0, 0, 0, 0, 0, 0, 0, 0],
   # ])

   # Easy - Arizona Daily Wildcat: Tuesday, Jan 17th 2006
   # var fullGrid = createSudokuGrid([
   #    [4, 3, 5, 2, 6, 9, 7, 8, 1],
   #    [6, 8, 2, 5, 7, 1, 4, 9, 3],
   #    [1, 9, 7, 8, 3, 4, 5, 6, 2],
   #    [8, 2, 6, 1, 9, 5, 3, 4, 7],
   #    [3, 7, 4, 6, 8, 2, 9, 1, 5],
   #    [9, 5, 1, 7, 4, 3, 6, 2, 8],
   #    [5, 1, 9, 3, 2, 6, 8, 7, 4],
   #    [2, 4, 8, 9, 5, 7, 1, 3, 6],
   #    [7, 6, 3, 4, 1, 8, 2, 5, 9],
   # ])

   # var grid = createSudokuGrid([
   #    [0, 0, 0, 2, 6, 0, 7, 0, 1],
   #    [6, 8, 0, 0, 7, 0, 0, 9, 0],
   #    [1, 9, 0, 0, 0, 4, 5, 0, 0],
   #    [8, 2, 0, 1, 0, 0, 0, 4, 0],
   #    [0, 0, 4, 6, 0, 2, 9, 0, 0],
   #    [0, 5, 0, 0, 0, 3, 0, 2, 8],
   #    [0, 0, 9, 3, 0, 0, 0, 7, 4],
   #    [0, 4, 0, 0, 5, 0, 0, 3, 6],
   #    [7, 0, 3, 0, 1, 8, 0, 0, 0],
   # ])

   # Easy - Arizona Daily Wildcat: Wednesday, Jan 18th 2006
   # var fullGrid = createSudokuGrid([
   #    [1, 5, 2, 4, 8, 9, 3, 7, 6],
   #    [7, 3, 9, 2, 5, 6, 8, 4, 1],
   #    [4, 6, 8, 3, 7, 1, 2, 9, 5],
   #    [3, 8, 7, 1, 2, 4, 6, 5, 9],
   #    [5, 9, 1, 7, 6, 3, 4, 2, 8],
   #    [2, 4, 6, 8, 9, 5, 7, 1, 3],
   #    [9, 1, 4, 6, 3, 7, 5, 8, 2],
   #    [6, 2, 5, 9, 4, 8, 1, 3, 7],
   #    [8, 7, 3, 5, 1, 2, 9, 6, 4],
   # ])

   # var grid = createSudokuGrid([
   #    [1, 0, 0, 4, 8, 9, 0, 0, 6],
   #    [7, 3, 0, 0, 0, 0, 0, 4, 0],
   #    [0, 0, 0, 0, 0, 1, 2, 9, 5],
   #    [0, 0, 7, 1, 2, 0, 6, 0, 0],
   #    [5, 0, 0, 7, 0, 3, 0, 0, 8],
   #    [0, 0, 6, 0, 9, 5, 7, 0, 0],
   #    [9, 1, 4, 6, 0, 0, 0, 0, 0],
   #    [0, 2, 0, 0, 0, 0, 0, 3, 7],
   #    [8, 0, 0, 5, 1, 2, 0, 0, 4],
   # ])

   # Intermediate - Daily Telegraph January 19th "Diabolical"
   var fullGrid = createSudokuGrid([
      [1, 2, 3, 6, 7, 8, 9, 4, 5],
      [5, 8, 4, 2, 3, 9, 7, 6, 1],
      [9, 6, 7, 1, 4, 5, 3, 2, 8],
      [3, 7, 2, 4, 6, 1, 5, 8, 9],
      [6, 9, 1, 5, 8, 3, 2, 7, 4],
      [4, 5, 8, 7, 9, 2, 6, 1, 3],
      [8, 3, 6, 9, 2, 4, 1, 5, 7],
      [2, 1, 9, 8, 5, 7, 4, 3, 6],
      [7, 4, 5, 3, 1, 6, 8, 9, 2],
   ])

   var grid = createSudokuGrid([
      [0, 2, 0, 6, 0, 8, 0, 0, 0],
      [5, 8, 0, 0, 0, 9, 7, 0, 0],
      [0, 0, 0, 0, 4, 0, 0, 0, 0],
      [3, 7, 0, 0, 0, 0, 5, 0, 0],
      [6, 0, 0, 0, 0, 0, 0, 0, 4],
      [0, 0, 8, 0, 0, 0, 0, 1, 3],
      [0, 0, 0, 0, 2, 0, 0, 0, 0],
      [0, 0, 9, 8, 0, 0, 0, 3, 6],
      [0, 0, 0, 3, 0, 6, 0, 9, 0],
   ])

   # Hard
   # var grid = createSudokuGrid([
   #    [0, 0, 0, 6, 0, 0, 4, 0, 0],
   #    [7, 0, 0, 0, 0, 3, 6, 0, 0],
   #    [0, 0, 0, 0, 9, 1, 0, 8, 0],
   #    [0, 0, 0, 0, 0, 0, 0, 0, 0],
   #    [0, 5, 0, 1, 8, 0, 0, 0, 3],
   #    [0, 0, 0, 3, 0, 6, 0, 4, 5],
   #    [0, 4, 0, 2, 0, 0, 0, 6, 0],
   #    [9, 0, 3, 0, 0, 0, 0, 0, 0],
   #    [0, 2, 0, 0, 0, 0, 1, 0, 0],
   # ])

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

   echo (if grid == fullGrid: "Correct!" else: "Incorrect")
   if grid.broken:
      echo "Broken!"

main()
