import sudoku
import sudokuConstraintProgramming

proc solveWithBacktracing*(g: var SudokuGrid) =
   let cpGrid = createSudokuCPGrid(g)

   var possibilitiesIndices: array[9, array[9, int]]
   for p in gridPos():
      possibilitiesIndices[p] = 0

   var p = Pos([0, 0])
   while not p.outOfBounds:
      if not g[p].filled:
         let v = cpGrid[p][possibilitiesIndices[p]]
         var invalid = false
         for pp in rowColCasePos(p):
            if pp != p and g[pp].filled and g[pp] == v:
               invalid = true
               break

         if invalid:
            while true:
               if possibilitiesIndices[p] < len(cpGrid[p]) - 1:
                  possibilitiesIndices[p] += 1
                  break
               else:
                  possibilitiesIndices[p] = 0
                  g[p] = 0

                  while true:
                     p.prev()
                     if p.outOfBounds:
                        return
                     if not cpGrid[p].filled:
                        g[p] = 0
                        break

         else:
            g[p] = v
            p.next()
      else:
         p.next()
