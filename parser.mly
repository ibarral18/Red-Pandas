%{ open Ast %}

%token PLUS MINUS TIMES DIVIDE EQUALS SEQUENCE EOF
%token <int> LITERAL
%token <string> VARIABLE

%left SEQUENCE
%right EQUALS
%left PLUS MINUS
%left TIMES DIVIDE

%start expr
%type <Ast.expr> expr

%%

expr:
  expr PLUS   expr { Binop($1, Add, $3) }
| expr MINUS  expr { Binop($1, Sub, $3) }
| expr TIMES  expr { Binop($1, Mul, $3) }
| expr DIVIDE expr { Binop($1, Div, $3) }
| VARIABLE EQUALS expr { Equi($1, $3) }
| expr SEQUENCE expr { Seq($1, $3) } 
| VARIABLE         { Var($1) }
| LITERAL          { Lit($1) }
