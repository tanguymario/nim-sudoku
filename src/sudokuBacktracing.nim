import sudoku
import sudokuConstraintProgramming

type
   PossibleCell = ref PossibleCellObj
   PossibleCellObj = object
      p: Pos
      ind: int

proc solveWithBacktracing*(g: var SudokuGrid) =
   let cpGrid = createSudokuCPGrid(g)

   var cells: seq[PossibleCell]
   for p in gridPos():
      if not cpGrid[p].filled:
         cells.add(PossibleCell(p: p, ind: 0))

   var i = 0
   while i < len(cells):
      var cell = cells[i]
      let v = cpGrid[cell.p][cell.ind]
      var invalid = false
      for pp in rowColCasePos(cell.p):
         if pp != cell.p and g[pp].filled and g[pp] == v:
            invalid = true
            break

      if invalid:
         while true:
            if cell.ind < len(cpGrid[cell.p]) - 1:
               cell.ind += 1
               break
            else:
               cell.ind = 0
               g[cell.p] = 0

               dec(i)
               if i < 0:
                  return
               cell = cells[i]
      else:
         g[cell.p] = v
         inc(i)
