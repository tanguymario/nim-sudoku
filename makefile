mainFile = src/sudoku.nim

appConsoleOpt = --app:console
appLibOpt = --app:lib
releaseOpt = -d:release --opt:speed

binPath = bin
cliAppPath = $(binPath)/console/nim-sudoku
libCPath = $(binPath)/lib/sudoku.so
libJSPath = $(binPath)/lib/sudoku.js

make:

cliapp:
	nim c $(appConsoleOpt) -o:$(cliAppPath) $(mainFile)

cliapp-release:
	nim c $(appConsoleOpt) $(releaseOpt) -o:$(cliAppPath) $(mainFile)

clib:
	nim c $(appLibOpt) -o:$(libCPath) $(mainFile)

clib-release:
	nim c $(appLibOpt) $(releaseOpt) -o:$(libCPath) $(mainFile)

jslib:
	nim js $(appLibOpt) -o:${libJSPath} $(mainFile)

jslib-release:
	nim js $(appLibOpt) $(releaseOpt) -o:${libJSPath} $(mainFile)

clear:
	rm -rf $(binPath)/*
