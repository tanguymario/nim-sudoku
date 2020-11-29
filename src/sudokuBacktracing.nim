import sudoku
import sudokuConstraintProgramming

type
   PossibleCell = object
      p: Pos
      ind: int

proc solveWithBacktracing*(g: var SudokuGrid) =
   let cpGrid = createSudokuCPGrid(g)

   var possibleCells: seq[PossibleCell]
   for p in gridPos():
      if not cpGrid[p].filled:
         possibleCells.add(PossibleCell(p: p, ind: 0))

   var i = 0
   while i < len(possibleCells):
      let v = cpGrid[possibleCells[i].p][possibleCells[i].ind]
      var invalid = false
      for pp in rowColCasePos(possibleCells[i].p):
         if pp != possibleCells[i].p and g[pp].filled and g[pp] == v:
            invalid = true
            break

      if invalid:
         while true:
            if possibleCells[i].ind < len(cpGrid[possibleCells[i].p]) - 1:
               possibleCells[i].ind += 1
               break
            else:
               possibleCells[i].ind = 0
               g[possibleCells[i].p] = 0

               dec(i)
               if i < 0:
                  return
      else:
         g[possibleCells[i].p] = v
         inc(i)
