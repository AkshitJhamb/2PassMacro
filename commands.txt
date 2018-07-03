flex 1.l
bison 1.y -d
gcc lex.yy.c 1.tab.c -o somefile.exe
somefile.exe newtest.txt