type
    SudokuGrid* = array[9 * 9, int]

    SudokuGridPossibilities = array[9 * 9, seq[int]]

proc `[]`(grid: SudokuGrid, row, col: int): int =
  return grid[row * 9 + col]

proc `[]=`(grid: var SudokuGrid, row, col, val: int) =
    grid[row * 9 + col] = val

proc `[]`(p: var SudokuGridPossibilities, row, col: int): var seq[int] =
  return p[row * 9 + col]

proc `[]=`(p: var SudokuGridPossibilities, row, col: int, val: seq[int]) =
    p[row * 9 + col] = val

proc remove(p: var SudokuGridPossibilities, row, col, val: int) =
    let idx = p[row, col].find(val)
    if idx >= 0:
        p[row, col].del(idx)

proc echo*(grid: SudokuGrid) =
    var str = ""
    for row in 0 ..< 9:
        if row > 0 and row mod 3 == 0:
            str &= "══════════════════════\n"
        for col in 0 ..< 9:
            str &= $grid[row, col]
            if col < 8:
                str = str & (if (col + 1) mod 3 == 0: " ║ " else: " ")
        if row < 8:
            str &= "\n"
    echo str

proc init*(p: var SudokuGridPossibilities, grid: SudokuGrid) =
    for row in 0 ..< 9:
        for col in 0 ..< 9:
            p[row, col] = @[1, 2, 3, 4, 5, 6, 7, 8, 9]

            if grid[row, col] == 0:
                for tmpCol in 0 ..< 9:
                    if grid[row, tmpCol] != 0:
                        p.remove(row, col, grid[row, tmpCol])
                for tmpRow in 0 ..< 9:
                    if grid[tmpRow, col] != 0:
                        p.remove(row, col, grid[tmpRow, col])

                let caseX = int(col / 3)
                let caseY = int(row / 3)
                for y in 0 ..< 3:
                    for x in 0 ..< 3:
                        let tmpRow = caseY * 3 + y
                        let tmpCol = caseX * 3 + x
                        if grid[tmpRow, tmpCol] != 0:
                            p.remove(row, col, grid[tmpRow, tmpCol])


proc update(p: var SudokuGridPossibilities, grid: SudokuGrid, row, col: int) =
    for tmpCol in 0 ..< 9:
        p.remove(row, tmpCol, grid[row, col])
    for tmpRow in 0 ..< 9:
        p.remove(tmpRow, col, grid[row, col])

    let caseX = int(col / 3)
    let caseY = int(row / 3)
    for y in 0 ..< 3:
        for x in 0 ..< 3:
            let tmpRow = caseY * 3 + y
            let tmpCol = caseX * 3 + x
            p.remove(tmpRow, tmpCol, grid[row, col])

proc solve*(grid: var SudokuGrid) =
    var possibilities: SudokuGridPossibilities
    possibilities.init(grid)
    var canSolve = true
    while canSolve:
        canSolve = false
        for row in 0 ..< 9:
            for col in 0 ..< 9:
                if len(possibilities[row, col]) == 1:
                    canSolve = true
                    grid[row, col] = possibilities[row, col][0]
                    possibilities.update(grid, row, col)
                    possibilities[row, col].setLen(0)

proc main*() =
    const soluceGrid: SudokuGrid = [
        2, 9, 4, 6, 7, 3, 1, 5, 8,
        3, 6, 7, 5, 1, 8, 9, 4, 2,
        8, 5, 1, 2, 4, 9, 6, 3, 7,
        4, 2, 9, 8, 6, 7, 3, 1, 5,
        1, 7, 6, 3, 2, 5, 8, 9, 4,
        5, 8, 3, 1, 9, 4, 7, 2, 6,
        6, 3, 8, 9, 5, 2, 4, 7, 1,
        7, 1, 2, 4, 3, 6, 5, 8, 9,
        9, 4, 5, 7, 8, 1, 2, 6, 3
    ]

    var grid: SudokuGrid = [
        0, 0, 4, 0, 7, 3, 0, 5, 0,
        3, 6, 0, 0, 0, 8, 9, 0, 0,
        8, 5, 1, 2, 0, 0, 0, 3, 0,
        4, 0, 9, 8, 6, 7, 3, 0, 0,
        1, 0, 0, 0, 0, 5, 0, 0, 0,
        0, 8, 0, 1, 9, 0, 7, 0, 0,
        0, 0, 0, 9, 0, 2, 0, 7, 1,
        0, 1, 2, 0, 0, 6, 0, 8, 0,
        9, 0, 5, 7, 8, 1, 2, 6, 0
    ]

    grid.solve()

    echo(grid)

main()
