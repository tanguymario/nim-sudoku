import algorithm

type
    SudokuGrid* = array[9 * 9, int]

    SudokuSolverCase = object
        possibilities: array[9, bool]
        nb: int
    SudokuSolverGrid = array[9 * 9, SudokuSolverCase]

proc `[]`*(g: SudokuGrid, row, col: int): int = return g[row * 9 + col]
proc `[]=`*(g: var SudokuGrid, row, col, val: int) = g[row * 9 + col] = val
proc completed*(g: SudokuGrid): bool = return not g.contains(0)

proc `$`*(grid: SudokuGrid): string =
    result = ""
    result &= "╔═══════╦═══════╦═══════╗\n"
    for row in 0 ..< 9:
        if row > 0 and row mod 3 == 0:
            result &= "╠═══════╬═══════╬═══════╣\n"
        result &= "║ "
        for col in 0 ..< 9:
            result &= (if grid[row, col] == 0: " " else: $grid[row, col])
            result &= (if (col + 1) mod 3 == 0: " ║ " else: " ")
        result &= "\n"
    result &= "╚═══════╩═══════╩═══════╝\n"

proc `[]`(sg: SudokuSolverGrid, row, col: int): SudokuSolverCase =
    return sg[row * 9 + col]

proc `[]`(sg: var SudokuSolverGrid, row, col: int): var SudokuSolverCase =
    return sg[row * 9 + col]

proc remove(sc: var SudokuSolverCase, val: int) =
    if sc.possibilities[val - 1]:
        sc.possibilities[val - 1] = false
        sc.nb -= 1

proc `$`(sg: SudokuSolverGrid): string =
    result = ""
    for row in 0 ..< 9:
        for col in 0 ..< 9:
            result &= $row & " " & $col
            result &= " nb: " & $sg[row, col].nb
            result &= " ["
            var nbPossibilitiesShown = 0
            for i in 0 ..< 9:
                if sg[row, col].possibilities[i]:
                    result &= $(i + 1)
                    nbPossibilitiesShown += 1
                    if nbPossibilitiesShown == sg[row, col].nb:
                        break
                    result &= ", "
            result &= "]"
            result &= "\n"

proc init(sg: var SudokuSolverGrid, grid: SudokuGrid) =
    for row in 0 ..< 9:
        for col in 0 ..< 9:
            if grid[row, col] != 0:
                sg[row, col].possibilities.fill(false)
                sg[row, col].nb = 0
            else:
                sg[row, col].possibilities.fill(true)
                sg[row, col].nb = 9

                for tmpCol in 0 ..< 9:
                    if grid[row, tmpCol] != 0:
                        sg[row, col].remove(grid[row, tmpCol])
                for tmpRow in 0 ..< 9:
                    if grid[tmpRow, col] != 0:
                        sg[row, col].remove(grid[tmpRow, col])

                let caseX = int(col / 3)
                let caseY = int(row / 3)
                for y in 0 ..< 3:
                    for x in 0 ..< 3:
                        let tmpRow = caseY * 3 + y
                        let tmpCol = caseX * 3 + x
                        if grid[tmpRow, tmpCol] != 0:
                            sg[row, col].remove(grid[tmpRow, tmpCol])

proc update(sg: var SudokuSolverGrid, grid: SudokuGrid, row, col: int) =
    for tmpCol in 0 ..< 9:
        sg[row, tmpCol].remove(grid[row, col])
    for tmpRow in 0 ..< 9:
        sg[tmpRow, col].remove(grid[row, col])

    let caseX = int(col / 3)
    let caseY = int(row / 3)
    for y in 0 ..< 3:
        for x in 0 ..< 3:
            let tmpRow = caseY * 3 + y
            let tmpCol = caseX * 3 + x
            sg[tmpRow, tmpCol].remove(grid[row, col])

    sg[row, col].possibilities[grid[row, col] - 1] = false
    sg[row, col].nb = 0

proc solveNaive*(grid: var SudokuGrid, sg: var SudokuSolverGrid): bool =
    result = true
    while result:
        result = false
        for row in 0 ..< 9:
            for col in 0 ..< 9:
                if sg[row, col].nb == 1:
                    result = true
                    var possibility = 0
                    for i in 0 ..< 9:
                        if sg[row, col].possibilities[i]:
                            possibility = i + 1
                            break
                    grid[row, col] = possibility
                    sg.update(grid, row, col)

proc solve*(g: var SudokuGrid) =
    var sg: SudokuSolverGrid
    sg.init(g)
    discard g.solveNaive(sg)
    if not g.completed:
        var g2: SudokuGrid = g
        var sg2: SudokuSolverGrid = sg
        g2[1, 3] = 1
        sg2.update(g2, 1, 3)
        discard g2.solveNaive(sg2)
        echo g2
        echo sg2

proc main*() =
    # const soluceGrid: SudokuGrid = [
    #     2, 9, 4, 6, 7, 3, 1, 5, 8,
    #     3, 6, 7, 5, 1, 8, 9, 4, 2,
    #     8, 5, 1, 2, 4, 9, 6, 3, 7,
    #     4, 2, 9, 8, 6, 7, 3, 1, 5,
    #     1, 7, 6, 3, 2, 5, 8, 9, 4,
    #     5, 8, 3, 1, 9, 4, 7, 2, 6,
    #     6, 3, 8, 9, 5, 2, 4, 7, 1,
    #     7, 1, 2, 4, 3, 6, 5, 8, 9,
    #     9, 4, 5, 7, 8, 1, 2, 6, 3
    # ]

    # var grid: SudokuGrid = [
    #     0, 0, 4, 0, 7, 3, 0, 5, 0,
    #     3, 6, 0, 0, 0, 8, 9, 0, 0,
    #     8, 5, 1, 2, 0, 0, 0, 3, 0,
    #     4, 0, 9, 8, 6, 7, 3, 0, 0,
    #     1, 0, 0, 0, 0, 5, 0, 0, 0,
    #     0, 8, 0, 1, 9, 0, 7, 0, 0,
    #     0, 0, 0, 9, 0, 2, 0, 7, 1,
    #     0, 1, 2, 0, 0, 6, 0, 8, 0,
    #     9, 0, 5, 7, 8, 1, 2, 6, 0
    # ]

    # var grid: SudokuGrid = [
    #     0, 7, 6, 0, 0, 0, 0, 8, 0,
    #     0, 0, 0, 0, 0, 0, 0, 0, 0,
    #     4, 0, 0, 0, 5, 8, 0, 0, 0,
    #     0, 0, 0, 0, 0, 3, 0, 0, 0,
    #     0, 0, 1, 2, 0, 6, 7, 0, 0,
    #     0, 8, 0, 1, 9, 4, 2, 0, 3,
    #     7, 6, 0, 0, 0, 0, 8, 0, 0,
    #     0, 0, 3, 8, 0, 7, 1, 9, 2,
    #     0, 0, 0, 0, 4, 0, 0, 0, 6
    # ]

    # var grid: SudokuGrid = [
    #     0, 0, 0, 0, 0, 0, 0, 0, 0,
    #     0, 0, 0, 0, 0, 0, 0, 0, 0,
    #     0, 0, 0, 0, 0, 0, 0, 0, 0,
    #     0, 0, 0, 0, 0, 0, 0, 0, 0,
    #     0, 0, 0, 0, 0, 0, 0, 0, 0,
    #     0, 0, 0, 0, 0, 0, 0, 0, 0,
    #     0, 0, 0, 0, 0, 0, 0, 0, 0,
    #     0, 0, 0, 0, 0, 0, 0, 0, 0,
    #     0, 0, 0, 0, 0, 0, 0, 0, 0
    # ]

    # Easy
    # var grid: SudokuGrid = [
    #     0, 0, 0, 2, 6, 0, 7, 0, 1,
    #     6, 8, 0, 0, 7, 0, 0, 9, 0,
    #     1, 9, 0, 0, 0, 4, 5, 0, 0,
    #     8, 2, 0, 1, 0, 0, 0, 4, 0,
    #     0, 0, 4, 6, 0, 2, 9, 0, 0,
    #     0, 5, 0, 0, 0, 3, 0, 2, 8,
    #     0, 0, 9, 3, 0, 0, 0, 7, 4,
    #     0, 4, 0, 0, 5, 0, 0, 3, 6,
    #     7, 0, 3, 0, 1, 8, 0, 0, 0
    # ]

    # Intermediate
    var grid: SudokuGrid = [
        0, 2, 0, 6, 0, 8, 0, 0, 0,
        5, 8, 0, 0, 0, 9, 7, 0, 0,
        0, 0, 0, 0, 4, 0, 0, 0, 0,
        3, 7, 0, 0, 0, 0, 5, 0, 0,
        6, 0, 0, 0, 0, 0, 0, 0, 4,
        0, 0, 8, 0, 0, 0, 0, 1, 3,
        0, 0, 0, 0, 2, 0, 0, 0, 0,
        0, 0, 9, 8, 0, 0, 0, 3, 6,
        0, 0, 0, 3, 0, 6, 0, 9, 0
    ]

    # Hard
    # var grid: SudokuGrid = [
    #     0, 0, 0, 6, 0, 0, 4, 0, 0,
    #     7, 0, 0, 0, 0, 3, 6, 0, 0,
    #     0, 0, 0, 0, 9, 1, 0, 8, 0,
    #     0, 0, 0, 0, 0, 0, 0, 0, 0,
    #     0, 5, 0, 1, 8, 0, 0, 0, 3,
    #     0, 0, 0, 3, 0, 6, 0, 4, 5,
    #     0, 4, 0, 2, 0, 0, 0, 6, 0,
    #     9, 0, 3, 0, 0, 0, 0, 0, 0,
    #     0, 2, 0, 0, 0, 0, 1, 0, 0
    # ]

    grid.solve()

    echo(grid)

main()
