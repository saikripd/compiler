#define INT_LIT 257
#define FLOAT_LIT 258
#define CHAR_LIT 259
#define STRING_LIT 260
#define IDENTIFIER 261
#define WRITELN 262
#define DIV_EQ 263
#define AND_EQ 264
#define AND_AND 265
#define OR_EQ 266
#define OR_OR 267
#define MIN_EQ 268
#define MIN_MIN 269
#define PLUS_EQ 270
#define PLUS_PLUS 271
#define LEQ 272
#define LSHIFT 273
#define LSHIFT_EQ 274
#define LESS_GREAT 275
#define GEQ 276
#define RSHIFT_EQ 277
#define LOG_RSHIFT_EQ 278
#define RSHIFT 279
#define LOG_RSHIFT 280
#define NEQ 281
#define NLESS_GREAT 282
#define NLT 283
#define NLEQ 284
#define NGT 285
#define NGEQ 286
#define EQ_EQ 287
#define MULT_EQ 288
#define MOD_EQ 289
#define XOR_EQ 290
#define POW 291
#define POW_EQ 292
#define INV_EQ 293
#define ASM 294
#define ASSERT 295
#define AUTO 296
#define BOOL 297
#define BODY 298
#define BREAK 299
#define BYTE 300
#define CASE 301
#define CATCH 302
#define CHAR 303
#define CLASS 304
#define CONST 305
#define CONTINUE 306
#define DEFAULT 307
#define DELETE 308
#define DO 309
#define DOUBLE 310
#define ELSE 311
#define ENUM 312
#define FALSE 313
#define FINAL 314
#define FINALLY 315
#define FLOAT 316
#define FOR 317
#define FOREACH 318
#define FUNCTION 319
#define GOTO 320
#define IF 321
#define IMPORT 322
#define IN 323
#define INT 324
#define LONG 325
#define NEW 326
#define NULLTOKEN 327
#define OUT 328
#define PRIVATE 329
#define PROTECTED 330
#define PUBLIC 331
#define RETURN 332
#define SHORT 333
#define SIZEOF 334
#define STATIC 335
#define STRUCT 336
#define SUPER 337
#define SWITCH 338
#define THIS 339
#define THROW 340
#define TRUE 341
#define TRY 342
#define TYPEOF 343
#define UBYTE 344
#define UINT 345
#define ULONG 346
#define USHORT 347
#define VOID 348
#define WHILE 349
#ifdef YYSTYPE
#undef  YYSTYPE_IS_DECLARED
#define YYSTYPE_IS_DECLARED 1
#endif
#ifndef YYSTYPE_IS_DECLARED
#define YYSTYPE_IS_DECLARED 1
typedef union{
        struct ASTnode *node;   /*non-token*/
        struct ASTCaseNode *caseNode;
        struct terminal{    /*token*/
                        char *text;
                        int type;
        } token;
} YYSTYPE;
#endif /* !YYSTYPE_IS_DECLARED */
extern YYSTYPE yylval;
