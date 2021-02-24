%{ open Ast %}

%token LBRACK RBRACK LPAREN RPAREN LCURLY RCURLY SEMI COMMA PERIOD
%token DEFINE STATIC RETURN
%token INT DOUBLE ASSIGN
%token FOR WHILE CONTINUE BREAK
%token IF ELSE 
%token GEQ GREAT LESS LEQ EQUALS NOTEQ OR AND NOT 
%token PLUS MINUS TIMES DIVIDE POWER 
%token INTMATRIX DUBMATRIX 
%token TRUE FALSE
%token EOF


%token <int> LITERAL
%token <float> DOUBLE_LITERAL
%token <string> VARIABLE
%token <int list> INT_MATRIX
%token <float list> DUB_MATRIX

%nonassoc ELSE NOELSE COLON
%left SEQUENCE
%right ASSIGN
%left OR
%left AND
%left EQUALS NOTEQ 
%left GREAT LESS GEQ LEQ 
%left PLUS MINUS
%left TIMES DIVIDE
%left PERIOD
%left POWER

%start expr
%type <Ast.expr> expr

%%

stmt_list:
  /* empty */   { [] }
  | stmt_list stmt { $2 :: $1 }
  
stmt:
    expr SEMI                                 { Expr $1               }
  | BREAK SEMI                                { Break Noexpr          }
  | CONTINUE SEMI                             { Continue Noexpr       }
  | RETURN SEMI                               { Return Noexpr         }
  | RETURN expr_opt SEMI                      { Return $2             }
  | LBRACE stmt_list RBRACE                   { Block(List.rev $2)    }
  | IF LPAREN expr RPAREN stmt %prec NOELSE   { If($3, $5, Block([])) }
  | IF LPAREN stmt_list RBRACE stmt ELSE stmt { If($3, $5, $7)        }
  | MAP LPAREN expr COMMA expr RPAREN         { Map($3, $5)           }
  | FOR LPAREN expr SEMI expr SEMI expr RPAREN stmt 
                                              { For($3, $5, $7, $9)   }
  | WHILE LPAREN expr RPAREN stmt             { While($3, $5)         }

expr_opt:
  /* empty */ { Noexpr  }
  | expr      { $1      }

expr:
  expr PLUS   expr { Binop($1, Add, $3) }
| expr MINUS  expr { Binop($1, Sub, $3) }
| expr TIMES  expr { Binop($1, Mul, $3) }
| expr DIVIDE expr { Binop($1, Div, $3) }
| expr POWER expr  { Binop($1, Pow, $3) }
| VARIABLE EQUALS expr { Equi($1, $3) }
| expr EQUALS expr  { Binop($1, Equals, $3) }
| expr NOTEQ expr  { Binop($1, Noteq, $3) }
| expr LESS expr  { Binop($1, Less, $3) }
| expr GREAT expr  { Binop($1, Great, $3) }
| expr LEQ expr   { Binop($1, Leq, $3) }
| expr GEQ expr     { Binop($1, Geq, $3)}
| expr AND expr  { Binop($1, And, $3) }
| expr OR expr  { Binop($1, Or, $3) }
| expr LESS expr  { Binop($1, Less, $3) }
| expr SEQUENCE expr { Seq($1, $3) } 
| expr COLON expr   { Range($1, $3)}
| TRUE              {Bool(true)}
| FALSE             {Bool(false)}
| VARIABLE         { Var($1) }
| DOUBLE           { Dub($1)}
| LITERAL          { Lit($1) }
