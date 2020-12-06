exec = bin/nim-sudoku
mainFile = src/sudoku

make:
	nim c -o:$(exec) $(mainFile)

release:
	nim c -d:release --opt:speed -o:$(exec) $(mainFile)

clear:
	rm -rf bin/*
