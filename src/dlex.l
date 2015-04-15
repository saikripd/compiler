Zero		0
Digit 		[0-9]
NonZeroDigit	[1-9]
BinaryDigit	[01]
OctalDigit	[0-7]
HexDigit 	[a-fA-F]

FloatSuffix 		(f|F)
RealSuffix 		(L)
ImaginarySuffix 	(i)
DecimalExponentStart 	(e|E|e\+|E\+|e\-|E\-)
HexExponentStart     	(p|P|p\+|P\+|p\-|P\-)
IntegerSuffix 		(L|u|U|Lu|LU|uL|UL)
BinPrefix		(0b|0B)
HexPrefix		(0x|0X)
StringPostfix		[cwd]

Letter 			[a-zA-Z]
Underscore		_
WhiteSpace		[ \t]	
Escape			("\\'"|"\\\""|"\\?"|"\\\\"|"\\0"|"\\a"|"\\b"|"\\f"|"\\n"|"\\r"|"\\t"|"\\v")

EOL			\n
%{
	#include<string.h>
	#include<stdio.h>
	#include "y.tab.h"
	char comments[1024]=" ";
	char token[1024];
	int lineno = 1; 
	int stringstartlineno=1; 
	int commentstartlineno=1;
	void printcomments(void);
%}
%x SLCOMMENT
%x MLCOMMENT
%x STRING
%x WYSIWYGSTRING
%x ALTWYSIWYGSTRING
%option yylineno

%%
					/*	Match single line comments 	*/
\/\/							{  BEGIN SLCOMMENT;}
<SLCOMMENT><<EOF>>					{BEGIN INITIAL;   yyterminate();}
<SLCOMMENT>{EOL}					{BEGIN INITIAL; printcomments();  }
<SLCOMMENT>.						{ }
					/*	Match multi line comments 	*/
\/\*							{  BEGIN MLCOMMENT; commentstartlineno = lineno;}
<MLCOMMENT><<EOF>>					{ printf("Error in line number %d", commentstartlineno); yyterminate();}
<MLCOMMENT>{EOL}					{  lineno++;}
<MLCOMMENT>\*\/						{  BEGIN INITIAL;}
<MLCOMMENT>.						{ }

"/"			{yylval.token.text=strdup(yytext); yylval.token.type='/'; return '/'	;}
"/=" 		{yylval.token.text=strdup(yytext); yylval.token.type=DIV_EQ; return DIV_EQ	;}
"."			{yylval.token.text=strdup(yytext); yylval.token.type='.'; return '.'	;}
"&" 		{yylval.token.text=strdup(yytext); yylval.token.type='&'; return '&'	;}
"&=" 		{yylval.token.text=strdup(yytext); yylval.token.type=AND_EQ; return AND_EQ	;}
"&&" 		{yylval.token.text=strdup(yytext); yylval.token.type=AND_AND; return AND_AND	;}
"|"			{yylval.token.text=strdup(yytext); yylval.token.type='|'; return '|'	;}
"|="		{yylval.token.text=strdup(yytext); yylval.token.type=OR_EQ; return OR_EQ	;}
"||"		{yylval.token.text=strdup(yytext); yylval.token.type=OR_OR; return OR_OR	;}
"-"			{yylval.token.text=strdup(yytext); yylval.token.type='-'; return '-'	;}
"-=" 		{yylval.token.text=strdup(yytext); yylval.token.type=MIN_EQ; return MIN_EQ	;}
"--" 		{yylval.token.text=strdup(yytext); yylval.token.type=MIN_MIN; return MIN_MIN	;}
"+" 		{yylval.token.text=strdup(yytext); yylval.token.type='+'; return '+'	;}
"+=" 		{yylval.token.text=strdup(yytext); yylval.token.type=PLUS_EQ; return PLUS_EQ	;}
"++" 		{yylval.token.text=strdup(yytext); yylval.token.type=PLUS_PLUS; return PLUS_PLUS	;}
"<" 		{yylval.token.text=strdup(yytext); yylval.token.type='<'; return '<'	;}
"<=" 		{yylval.token.text=strdup(yytext); yylval.token.type=LEQ; return LEQ	;}
"<<" 		{yylval.token.text=strdup(yytext); yylval.token.type=LSHIFT; return LSHIFT	;}
"<<=" 		{yylval.token.text=strdup(yytext); yylval.token.type=LSHIFT_EQ; return LSHIFT_EQ	;}
"<>" 		{yylval.token.text=strdup(yytext); yylval.token.type=LESS_GREAT; return LESS_GREAT	;}
">" 		{yylval.token.text=strdup(yytext); yylval.token.type='>'; return '>'	;}
">=" 		{yylval.token.text=strdup(yytext); yylval.token.type=GEQ; return GEQ	;}
">>=" 		{yylval.token.text=strdup(yytext); yylval.token.type=RSHIFT_EQ; return RSHIFT_EQ	;}
">>>=" 		{yylval.token.text=strdup(yytext); yylval.token.type=LOG_RSHIFT_EQ; return LOG_RSHIFT_EQ	;}
">>" 		{yylval.token.text=strdup(yytext); yylval.token.type=RSHIFT; return RSHIFT	;}
">>>" 		{yylval.token.text=strdup(yytext); yylval.token.type=LOG_RSHIFT; return LOG_RSHIFT	;}
"!" 		{yylval.token.text=strdup(yytext); yylval.token.type='!'; return '!'	;}
"!=" 		{yylval.token.text=strdup(yytext); yylval.token.type=NEQ; return NEQ	;}
"!<>" 		{yylval.token.text=strdup(yytext); yylval.token.type=NLESS_GREAT; return NLESS_GREAT	;}
"!<" 		{yylval.token.text=strdup(yytext); yylval.token.type=NLT; return NLT	;}
"!<=" 		{yylval.token.text=strdup(yytext); yylval.token.type=NLEQ; return NLEQ	;}
"!>" 		{yylval.token.text=strdup(yytext); yylval.token.type=NGT; return NGT	;}
"!>=" 		{yylval.token.text=strdup(yytext); yylval.token.type=NGEQ; return NGEQ	;}
"(" 		{yylval.token.text=strdup(yytext); yylval.token.type='('; return '('	;}
")" 		{yylval.token.text=strdup(yytext); yylval.token.type=')'; return ')'	;}
"[" 		{yylval.token.text=strdup(yytext); yylval.token.type='['; return '['	;}
"]" 		{yylval.token.text=strdup(yytext); yylval.token.type=']'; return ']'	;}
"{" 		{yylval.token.text=strdup(yytext); yylval.token.type='{'; return '{'	;}
"}" 		{yylval.token.text=strdup(yytext); yylval.token.type='}'; return '}'	;}
"?" 		{yylval.token.text=strdup(yytext); yylval.token.type='?'; return '?'	;}
","			{yylval.token.text=strdup(yytext); yylval.token.type=','; return ','	;}
";" 		{yylval.token.text=strdup(yytext); yylval.token.type=';'; return ';'	;}
":" 		{yylval.token.text=strdup(yytext); yylval.token.type=':'; return ':'	;}
"$" 		{yylval.token.text=strdup(yytext); yylval.token.type='$'; return '$'	;}
"=" 		{yylval.token.text=strdup(yytext); yylval.token.type='='; return '='	;}
"==" 		{yylval.token.text=strdup(yytext); yylval.token.type=EQ_EQ; return EQ_EQ	;}
"*" 		{yylval.token.text=strdup(yytext); yylval.token.type='*'; return '*'	;}
"*=" 		{yylval.token.text=strdup(yytext); yylval.token.type=MULT_EQ; return MULT_EQ	;}
"%" 		{yylval.token.text=strdup(yytext); yylval.token.type='%'; return '%'	;}
"%=" 		{yylval.token.text=strdup(yytext); yylval.token.type=MOD_EQ; return MOD_EQ	;}
"^" 		{yylval.token.text=strdup(yytext); yylval.token.type='^'; return '^'	;}
"^=" 		{yylval.token.text=strdup(yytext); yylval.token.type=XOR_EQ; return XOR_EQ	;}
"^^" 		{yylval.token.text=strdup(yytext); yylval.token.type=POW; return POW	;}
"^^=" 		{yylval.token.text=strdup(yytext); yylval.token.type=POW_EQ; return POW_EQ	;}
"~" 		{yylval.token.text=strdup(yytext); yylval.token.type='~'; return '~'	;}
"~=" 		{yylval.token.text=strdup(yytext); yylval.token.type=BREAK; return INV_EQ	;}
"@" 		{yylval.token.text=strdup(yytext); yylval.token.type='@'; return '@'	;}
"#"			{yylval.token.text=strdup(yytext); yylval.token.type='#'; return '#'	;}

					/*		Keywords		*/
"asm"				{ yylval.token.text=strdup(yytext); yylval.token.type=ASM; return ASM;	}
"assert"			{ yylval.token.text=strdup(yytext); yylval.token.type=ASSERT; return ASSERT; }
"auto"				{ yylval.token.text=strdup(yytext); yylval.token.type=AUTO; return AUTO;	}
"bool"				{ yylval.token.text=strdup(yytext); yylval.token.type=BOOL; return BOOL;	}
"body"				{ yylval.token.text=strdup(yytext); yylval.token.type=BODY; return BODY;	}
"break"				{ yylval.token.text=strdup(yytext); yylval.token.type=BREAK; return BREAK;	}
"byte"				{ yylval.token.text=strdup(yytext); yylval.token.type=BYTE; return BYTE;	}
"case"				{ yylval.token.text=strdup(yytext); yylval.token.type=CASE; return CASE;	}
"catch"				{ yylval.token.text=strdup(yytext); yylval.token.type=CATCH; return CATCH;	}
"char"				{ yylval.token.text=strdup(yytext); yylval.token.type=CHAR; return CHAR;	}
"class"				{ yylval.token.text=strdup(yytext); yylval.token.type=CLASS; return CLASS;	}
"const"				{ yylval.token.text=strdup(yytext); yylval.token.type=CONST; return CONST;	}
"continue"			{ yylval.token.text=strdup(yytext); yylval.token.type=CONTINUE; return CONTINUE;	}
"default"			{ yylval.token.text=strdup(yytext); yylval.token.type=DEFAULT; return DEFAULT;	}
"delete"			{ yylval.token.text=strdup(yytext); yylval.token.type=DELETE; return DELETE;	}
"do"				{ yylval.token.text=strdup(yytext); yylval.token.type=DO; return DO;	}
"double"			{ yylval.token.text=strdup(yytext); yylval.token.type=DOUBLE; return DOUBLE;	}
"else"				{ yylval.token.text=strdup(yytext); yylval.token.type=ELSE; return ELSE;	}
"enum"				{ yylval.token.text=strdup(yytext); yylval.token.type=ENUM; return ENUM; }
"false"				{ yylval.token.text=strdup(yytext); yylval.token.type=FALSE; return FALSE;	}
"final"				{ yylval.token.text=strdup(yytext); yylval.token.type=FINAL; return FINAL;	}
"finally"			{ yylval.token.text=strdup(yytext); yylval.token.type=FINALLY; return FINALLY;	}
"float"				{ yylval.token.text=strdup(yytext); yylval.token.type=FLOAT; return FLOAT;	}
"for"				{ yylval.token.text=strdup(yytext); yylval.token.type=FOR; return FOR;	}
"foreach"			{ yylval.token.text=strdup(yytext); yylval.token.type=FOREACH; return FOREACH;	}
"function"			{ yylval.token.text=strdup(yytext); yylval.token.type=FUNCTION; return FUNCTION;	}
"goto"				{ yylval.token.text=strdup(yytext); yylval.token.type=GOTO; return GOTO;	}
"if"				{ yylval.token.text=strdup(yytext); yylval.token.type=IF; return IF;	}
"import"			{ yylval.token.text=strdup(yytext); yylval.token.type=IMPORT; return IMPORT;	}
"in"				{ yylval.token.text=strdup(yytext); yylval.token.type=IN; return IN;	}
"int"				{ yylval.token.text=strdup(yytext); yylval.token.type=INT; return INT;	}
"long"				{ yylval.token.text=strdup(yytext); yylval.token.type=LONG; return LONG;	}
"new"				{ yylval.token.text=strdup(yytext); yylval.token.type=NEW; return NEW;	}
"null"				{ yylval.token.text=strdup(yytext); yylval.token.type=NULLTOKEN; return NULLTOKEN;	}
"out"				{ yylval.token.text=strdup(yytext); yylval.token.type=OUT; return OUT;	}
"private"			{ yylval.token.text=strdup(yytext); yylval.token.type=PRIVATE; return PRIVATE;	}
"protected"			{ yylval.token.text=strdup(yytext); yylval.token.type=PROTECTED; return PROTECTED;	}
"public"			{ yylval.token.text=strdup(yytext); yylval.token.type=PUBLIC; return PUBLIC;	}
"return"			{ yylval.token.text=strdup(yytext); yylval.token.type=RETURN; return RETURN;	}
"short"				{ yylval.token.text=strdup(yytext); yylval.token.type=SHORT; return SHORT;	}
"static"			{ yylval.token.text=strdup(yytext); yylval.token.type=STATIC; return STATIC;	}
"struct"			{ yylval.token.text=strdup(yytext); yylval.token.type=STRUCT; return STRUCT;	}	
"super"				{ yylval.token.text=strdup(yytext); yylval.token.type=SUPER; return SUPER;	}
"switch"			{ yylval.token.text=strdup(yytext); yylval.token.type=SWITCH; return SWITCH;	}
"this"				{ yylval.token.text=strdup(yytext); yylval.token.type=THIS; return THIS;	}
"throw"				{ yylval.token.text=strdup(yytext); yylval.token.type=THROW; return THROW;	}
"true"				{ yylval.token.text=strdup(yytext); yylval.token.type=TRUE; return TRUE;	}
"try"				{ yylval.token.text=strdup(yytext); yylval.token.type=TRY; return TRY;	}
"typeof"			{ yylval.token.text=strdup(yytext); yylval.token.type=TYPEOF; return TYPEOF;	}
"ubyte"				{ yylval.token.text=strdup(yytext); yylval.token.type=UBYTE; return UBYTE;	}
"uint"				{ yylval.token.text=strdup(yytext); yylval.token.type=UINT; return UINT;	}
"ulong"				{ yylval.token.text=strdup(yytext); yylval.token.type=ULONG; return ULONG;	}
"ushort"			{ yylval.token.text=strdup(yytext); yylval.token.type=USHORT; return USHORT;	}
"void"				{ yylval.token.text=strdup(yytext); yylval.token.type=VOID; return VOID;	}
"while"				{ yylval.token.text=strdup(yytext); yylval.token.type=WHILE; return WHILE;	}
"writeln"			{ yylval.token.text=strdup(yytext); yylval.token.type=WRITELN; return WRITELN;	}

					/*		Integer literals	*/
{BinPrefix}({BinaryDigit}|_)*{IntegerSuffix}?					{ yylval.token.text=strdup(yytext); yylval.token.type=INT; return INT_LIT;}
{HexPrefix}({Digit}|{HexDigit}|_)*{IntegerSuffix}?				{ yylval.token.text=strdup(yytext); yylval.token.type=INT; return INT_LIT;}
({NonZeroDigit})({Digit}|_)*{IntegerSuffix}?|{Zero}{IntegerSuffix}?		{ yylval.token.text=strdup(yytext); yylval.token.type=INT; return INT_LIT;}
	
					/* 		Float literals		*/
({NonZeroDigit}({Digit})*|{Zero})({ImaginarySuffix}|{FloatSuffix}{ImaginarySuffix}|{RealSuffix}{ImaginarySuffix})|{Zero}({ImaginarySuffix}|{FloatSuffix}{ImaginarySuffix}|{RealSuffix}{ImaginarySuffix})|{HexPrefix}({Digit}|{HexDigit})+({ImaginarySuffix}|{FloatSuffix}{ImaginarySuffix}|{RealSuffix}{ImaginarySuffix})						{ yylval.token.text=strdup(yytext); yylval.token.type=FLOAT; return FLOAT_LIT;}
({NonZeroDigit}({Digit})*|{Zero})\.({Digit}*)({FloatSuffix}|{RealSuffix}|{ImaginarySuffix}|{FloatSuffix}{ImaginarySuffix}|{RealSuffix}{ImaginarySuffix})?|{Zero}{Digit}+\.({Digit}*)({FloatSuffix}|{RealSuffix}|{ImaginarySuffix}|{FloatSuffix}{ImaginarySuffix}|{RealSuffix}{ImaginarySuffix})?|({Digit}+)\.({Digit}+){DecimalExponentStart}({Digit}+)({FloatSuffix}|{RealSuffix}|{ImaginarySuffix}|{FloatSuffix}{ImaginarySuffix}|{RealSuffix}{ImaginarySuffix})?						{ yylval.token.text=strdup(yytext); yylval.token.type=FLOAT; return FLOAT_LIT;}
\.{NonZeroDigit}({Digit})*({DecimalExponentStart}({Digit}+))?({FloatSuffix}|{RealSuffix}|{ImaginarySuffix}|{FloatSuffix}{ImaginarySuffix}|{RealSuffix}{ImaginarySuffix})?|({NonZeroDigit}({Digit})*|{Zero}){DecimalExponentStart}({Digit}+)({FloatSuffix}|{RealSuffix}|{ImaginarySuffix}|{FloatSuffix}{ImaginarySuffix}|{RealSuffix}{ImaginarySuffix})?|{Zero}{Digit}+{DecimalExponentStart}({Digit}+)({FloatSuffix}|{RealSuffix}|{ImaginarySuffix}|{FloatSuffix}{ImaginarySuffix}|{RealSuffix}{ImaginarySuffix})? 	{ yylval.token.text=strdup(yytext); yylval.token.type=FLOAT; return FLOAT_LIT;}
{HexPrefix}({Digit}|{HexDigit})*\.({Digit}|{HexDigit})+{HexExponentStart}{Digit}+({FloatSuffix}|{RealSuffix}|{ImaginarySuffix}|{FloatSuffix}{ImaginarySuffix}|{RealSuffix}{ImaginarySuffix})?|{HexPrefix}({Digit}|{HexDigit})+{HexExponentStart}{Digit}+({FloatSuffix}|{RealSuffix}|{ImaginarySuffix}|{FloatSuffix}{ImaginarySuffix}|{RealSuffix}{ImaginarySuffix})?  		{ yylval.token.text=strdup(yytext); yylval.token.type=FLOAT; return FLOAT_LIT;}
			
					/*		Character literals	*/
\'({Letter}|{Escape})\'					{ yylval.token.text=strdup(yytext); yylval.token.type=CHAR; return CHAR_LIT;}	
					/*	String literals			*/
\"							{  BEGIN STRING; stringstartlineno = lineno;yylval.token.text = strdup("\"");}
<STRING><<EOF>>						{ printf("Error in line number %d", stringstartlineno); yyterminate();}
<STRING>{EOL}						{  lineno++;strcat(yylval.token.text,strdup(yytext));}
<STRING>{Escape}					{ strcat(yylval.token.text,strdup(yytext));}
<STRING>\"{StringPostfix}?			{  BEGIN INITIAL;strcat(yylval.token.text,strdup(yytext)); yylval.token.type=STRING_LIT; return STRING_LIT;}
<STRING>.						{ strcat(yylval.token.text,strdup(yytext));}

r\"							{  BEGIN WYSIWYGSTRING; stringstartlineno = lineno;yylval.token.text = strdup("\"");}
<WYSIWYGSTRING><<EOF>>					{ printf("Error in line number %d", stringstartlineno); yyterminate();}
<WYSIWYGSTRING>{EOL}					{  lineno++;strcat(yylval.token.text,strdup(yytext));}
<WYSIWYGSTRING>\"{StringPostfix}?			{  BEGIN INITIAL; strcat(yylval.token.text,strdup(yytext)); yylval.token.type=STRING_LIT; return STRING_LIT;}
<WYSIWYGSTRING>.					{ strcat(yylval.token.text,strdup(yytext));}

`							{  BEGIN ALTWYSIWYGSTRING; stringstartlineno = lineno;yylval.token.text = strdup("\"");}
<ALTWYSIWYGSTRING><<EOF>>				{ printf("Error in line number %d", stringstartlineno); yyterminate();}
<ALTWYSIWYGSTRING>{EOL}					{  lineno++;strcat(yylval.token.text,strdup(yytext));}
<ALTWYSIWYGSTRING>`{StringPostfix}?			{  BEGIN INITIAL;strcat(yylval.token.text,strdup("\"")); yylval.token.type=STRING_LIT; return STRING_LIT;}
<ALTWYSIWYGSTRING>.					{ strcat(yylval.token.text,strdup(yytext));}	

					/*	Identifiers		*/
({Underscore}|{Letter})({Underscore}|{Letter}|{Digit})*	{ yylval.token.text=strdup(yytext); yylval.token.type=IDENTIFIER; return IDENTIFIER;}
					/* 		Whitespace	*/
({WhiteSpace})*						{ }
					/*		End of line	*/
{EOL}							{printcomments();  }

					/* If nothing matches, then there is an error */
.							{  strcpy(comments, "****Error****");}
%%
void printcomments()
{
	if(strcmp(comments, " ") != 0)
		printf("\t\t//%s", comments);
	strcpy(comments, " ");
	lineno++;
}
int yywrap(void){
	return 1;
}
 	