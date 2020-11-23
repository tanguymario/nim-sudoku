import algorithm
import random

randomize()

type
   SudokuCell* = int
   SudokuGrid* = array[9, array[9, SudokuCell]]

   SudokuSolverCell = object
      possibilities: array[9, bool]
      nb: int
   SudokuSolverGrid = array[9, array[9, SudokuSolverCell]]

proc filled*(c: SudokuCell): bool = return c != 0
proc full*(g: SudokuGrid): bool =
   for row in g:
      if row.contains(0):
         return false
   return true

proc broken*(g: SudokuGrid): bool =
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
         result &= (if g[row][col].filled: $g[row][col] else: " ")
         result &= (if (col + 1) mod 3 == 0: " ║ " else: " ")
      result &= "\n"
   result &= "╚═══════╩═══════╩═══════╝\n"

proc empty(sc: SudokuSolverCell): bool = return sc.nb == 0
proc empty(sg: SudokuSolverGrid): bool =
   for row in sg:
      for cell in row:
         if not cell.empty:
            return false
   return true

proc removePossibility(sc: var SudokuSolverCell, val: int) =
   if sc.possibilities[val - 1]:
      sc.possibilities[val - 1] = false
      sc.nb -= 1

proc `+=`(sc1, sc2: var SudokuSolverCell) =
   for i in 0 ..< 9:
      if not sc1.possibilities[i] and sc2.possibilities[i]:
         sc1.possibilities[i] = true
         sc1.nb += 1

proc `$`(sc: SudokuSolverCell): string =
   result = ""
   result &= "nb: " & $sc.nb
   result &= " ["
   var nbPossibilitiesShown = 0
   for i in 0 ..< 9:
      if sc.possibilities[i]:
         result &= $(i + 1)
         nbPossibilitiesShown += 1
         if nbPossibilitiesShown == sc.nb:
            break
         result &= ", "
   result &= "]"

proc `$`(sg: SudokuSolverGrid): string =
   result = ""
   for row in 0 ..< 9:
      for col in 0 ..< 9:
         result &= "(" & $row & ", " & $col & ") " & $sg[row][col] & "\n"

proc init(sg: var SudokuSolverGrid, g: SudokuGrid) =
   for row in 0 ..< 9:
      for col in 0 ..< 9:
         if g[row][col].filled:
            sg[row][col].possibilities.fill(false)
            sg[row][col].nb = 0
         else:
            sg[row][col].possibilities.fill(true)
            sg[row][col].nb = 9

            for tmpCol in 0 ..< 9:
               if g[row][tmpCol].filled:
                  sg[row][col].removePossibility(g[row][tmpCol])
            for tmpRow in 0 ..< 9:
               if g[tmprow][col].filled:
                  sg[row][col].removePossibility(g[tmpRow][col])
            for y in 0 ..< 3:
               for x in 0 ..< 3:
                  let tmpRow = int(row / 3) * 3 + y
                  let tmpCol = int(col / 3) * 3 + x
                  if g[tmpRow][tmpCol].filled:
                     sg[row][col].removePossibility(g[tmpRow][tmpCol])

proc update(sg: var SudokuSolverGrid, g: SudokuGrid, row, col: int) =
   for tmpCol in 0 ..< 9:
      sg[row][tmpCol].removePossibility(g[row][col])
   for tmpRow in 0 ..< 9:
      sg[tmpRow][col].removePossibility(g[row][col])
   for y in 0 ..< 3:
      for x in 0 ..< 3:
         let tmpRow = int(row / 3) * 3 + y
         let tmpCol = int(col / 3) * 3 + x
         sg[tmpRow][tmpCol].removePossibility(g[row][col])

   sg[row][col].possibilities.fill(false)
   sg[row][col].nb = 0

proc update(g: var SudokuGrid, sg: var SudokuSolverGrid, row, col, val: int) =
   g[row][col] = val
   sg.update(g, row, col)

proc refine(sg: var SudokuSolverGrid, g: SudokuGrid) =
   for row in 0 ..< 9:
      var nbFreeCells = 0
      var cell: SudokuSolverCell
      cell.possibilities.fill(false)
      cell.nb = 0
      for col in 0 ..< 9:
         if not g[row][col].filled:
            nbFreeCells += 1
            cell += sg[row][col]

      if cell.nb == nbFreeCells:
         var col = 0
         while col < 9:
            if not g[row][col].filled:
               for y in 0 ..< 3:
                  let tmpRow = int(row / 3) + y
                  if row != tmpRow:
                     for x in 0 ..< 3:
                        let tmpCol = int(col / 3) + x
                        for i in 0 ..< 9:
                           if cell.possibilities[i]:
                              sg[tmpRow][tmpCol].removePossibility(i + 1)

               col = (int(col / 3) + 1) * 3
            else:
               col += 1

   for col in 0 ..< 9:
      var nbFreeCells = 0
      var cell: SudokuSolverCell
      cell.possibilities.fill(false)
      cell.nb = 0
      for row in 0 ..< 9:
         if not g[row][col].filled:
            nbFreeCells += 1
            cell += sg[row][col]

      if cell.nb == nbFreeCells:
         var row = 0
         while row < 9:
            if not g[row][col].filled:
               for x in 0 ..< 3:
                  let tmpCol = int(col / 3) + x
                  if col != tmpCol:
                     for y in 0 ..< 3:
                        let tmpRow = int(row / 3) + y
                        for i in 0 ..< 9:
                           if cell.possibilities[i]:
                              sg[tmpRow][tmpCol].removePossibility(i + 1)

               row = (int(row / 3) + 1) * 3
            else:
               row += 1

   # https://homepages.cwi.nl/~aeb/games/sudoku/solving10.html

   # TODO check case

   # TODO hidden n-set

   # TODO naked n-set

   # TODO X-wing' for n=2, 'Swordfish' for n=3, 'Jellyfish' for n=4.



proc solveNaive*(g: var SudokuGrid, sg: var SudokuSolverGrid) =
   var canSolve = true
   while canSolve:
      canSolve = false
      for row in 0 ..< 9:
         for col in 0 ..< 9:
            if sg[row][col].nb == 1:
               canSolve = true
               var possibility = 0
               for i in 0 ..< 9:
                  if sg[row][col].possibilities[i]:
                     possibility = i + 1
                     break
               g.update(sg, row, col, possibility)

proc solve(g: var SudokuGrid, sg: var SudokuSolverGrid) =
   var maxIter = 10
   var iter = 0
   while true:
      g.solveNaive(sg)
      if g.full or sg.empty:
         break

      sg.refineMatching(g)
      # echo sg

      iter += 1
      if iter >= maxIter:
         break

proc solve*(g: var SudokuGrid) =
   var sg: SudokuSolverGrid
   sg.init(g)
   g.solve(sg)

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
   # var grid: SudokuGrid = [
   #    [1, 0, 0, 4, 8, 9, 0, 0, 6],
   #    [7, 3, 0, 0, 0, 0, 0, 4, 0],
   #    [0, 0, 0, 0, 0, 1, 2, 9, 5],
   #    [0, 0, 7, 1, 2, 0, 6, 0, 0],
   #    [5, 0, 0, 7, 0, 3, 0, 0, 8],
   #    [0, 0, 6, 0, 9, 5, 7, 0, 0],
   #    [9, 1, 4, 6, 0, 0, 0, 0, 0],
   #    [0, 2, 0, 0, 0, 0, 0, 3, 7],
   #    [8, 0, 0, 5, 1, 2, 0, 0, 4],
   # ]

   # Intermediate - Daily Telegraph January 19th "Diabolical"
   var grid: SudokuGrid = [
      [0, 2, 0, 6, 0, 8, 0, 0, 0],
      [5, 8, 0, 0, 0, 9, 7, 0, 0],
      [0, 0, 0, 0, 4, 0, 0, 0, 0],
      [3, 7, 0, 0, 0, 0, 5, 0, 0],
      [6, 0, 0, 0, 0, 0, 0, 0, 4],
      [0, 0, 8, 0, 0, 0, 0, 1, 3],
      [0, 0, 0, 0, 2, 0, 0, 0, 0],
      [0, 0, 9, 8, 0, 0, 0, 3, 6],
      [0, 0, 0, 3, 0, 6, 0, 9, 0],
   ]

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

   echo(grid)

   grid.solve()

   echo(grid)

main()
