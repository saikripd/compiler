SRC_DIR = src
OUT_DIR = bin
PARSER = dyacc.y
LEXER = dlex.l
EXE_NAME = parser

.PHONY: all clean

all:	
	mkdir -p $(OUT_DIR)
	cd $(OUT_DIR); \
	lex ../$(SRC_DIR)/$(LEXER); \
	yacc -d -v ../$(SRC_DIR)/$(PARSER);\
	gcc -c -g y.tab.c lex.yy.c ../$(SRC_DIR)/definition.c;\
	gcc -o $(EXE_NAME) y.tab.o lex.yy.o definition.o;\

clean:	
	rm -f $(OUT_DIR)/*~
	rm -f $(OUT_DIR)/y.*
	rm -f $(OUT_DIR)/lex.*
	rm -f $(OUT_DIR)/*.o

	
