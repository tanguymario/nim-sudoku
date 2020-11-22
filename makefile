exec = bin/nim-sudoku
mainFile = src/main

make:
	nim c -o:$(exec) $(mainFile)

makerun:
	nim c -o:$(exec) -r $(mainFile) 100 100

run:
ifeq ($(wildcard $(exec)), "")
	make
endif
	./$(exec)

clear:
	rm -rf bin/*
