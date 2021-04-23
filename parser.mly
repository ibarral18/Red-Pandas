

%{
open Ast
let parse_error s =
      begin
        try
          let start_pos = Parsing.symbol_start_pos ()
          and end_pos = Parsing.symbol_end_pos () in
          Printf.printf "File \"%s\", line %d, characters %d-%d: \n"
            start_pos.pos_fname
            start_pos.pos_lnum
            (start_pos.pos_cnum - start_pos.pos_bol)
            (end_pos.pos_cnum - start_pos.pos_bol)
        with Invalid_argument(_) -> ()
      end;
      Printf.printf "Syntax error: %s\n" s;
      raise Parsing.Parse_error

%}

%token SEMI LPAREN RPAREN LBRACE RBRACE COMMA 
%token LBRACK RBRACK PERIOD
%token PLUS MINUS TIMES DIVIDE ASSIGN
%token NOT EQ NEQ LT LEQ GT GEQ AND OR
%token RETURN IF ELSE FOR WHILE 
%token STRING MATRIX INT BOOL FLOAT VOID
%token COL ROW
%token DEF
%token <int> LITERAL
%token <bool> BLIT
%token <string> ID FLIT
%token <string> STRLIT
%token EOF

%start program
%type <Ast.program> program

%nonassoc NOELSE
%nonassoc ELSE
%right ASSIGN
%left OR
%left AND
%left EQ NEQ
%left LT GT LEQ GEQ
%left PLUS MINUS
%left TIMES DIVIDE
%right NOT

%%

program:
  decls EOF { $1 }

decls:
   /* nothing */ { ([], [])               }
 | decls vdecl { (($2 :: fst $1), snd $1) }
 | decls fdecl { (fst $1, ($2 :: snd $1)) }

fdecl:
   DEF typ ID LPAREN formals_opt RPAREN LBRACE vdecl_list stmt_list RBRACE
     { { typ = $2;
	 fname = $3;
	 formals = List.rev $5;
	 locals = List.rev $8;
	 body = List.rev $9 } }

formals_opt:
    /* nothing */ { [] }
  | formal_list   { $1 }

formal_list:
    typ ID                   { [($1,$2)]     }
  | formal_list COMMA typ ID { ($3,$4) :: $1 }

typ:
    INT        { Int           }
  | BOOL       { Bool          }
  | FLOAT      { Float         }
  | VOID       { Void          }
  | STRING     { String        }
  | MATRIX typ LBRACK LITERAL RBRACK LBRACK LITERAL RBRACK   { Matrix($2, $4, $7) }

vdecl_list:
    /* nothing */    { [] }
  | vdecl_list vdecl { $2 :: $1 }

vdecl:
   typ ID SEMI { ($1, $2) }

stmt_list:
    /* nothing */  { [] }
  | stmt_list stmt { $2 :: $1 }

stmt:
    expr SEMI                               { Expr $1               }
  | RETURN expr_opt SEMI                    { Return $2             }
  | LBRACE stmt_list RBRACE                 { Block(List.rev $2)    }
  | IF LPAREN expr RPAREN stmt %prec NOELSE { If($3, $5, Block([])) }
  | IF LPAREN expr RPAREN stmt ELSE stmt    { If($3, $5, $7)        }
  | FOR LPAREN expr_opt SEMI expr SEMI expr_opt RPAREN stmt
                                            { For($3, $5, $7, $9)   }
  | WHILE LPAREN expr RPAREN stmt           { While($3, $5)         }

expr_opt:
    /* nothing */ { Noexpr }
  | expr          { $1 }

expr:
    LITERAL          { Literal($1)            }
  | FLIT	           { Fliteral($1)           }
  | BLIT             { BoolLit($1)            }
  | ID               { Id($1)                 }
  | STRLIT           { StrLit($1)             }
  | expr PLUS   expr { Binop($1, Add,   $3)   }
  | expr MINUS  expr { Binop($1, Sub,   $3)   }
  | expr TIMES  expr { Binop($1, Mult,  $3)   }
  | expr DIVIDE expr { Binop($1, Div,   $3)   }
  | expr EQ     expr { Binop($1, Equal, $3)   }
  | expr NEQ    expr { Binop($1, Neq,   $3)   }
  | expr LT     expr { Binop($1, Less,  $3)   }
  | expr LEQ    expr { Binop($1, Leq,   $3)   }
  | expr GT     expr { Binop($1, Greater, $3) }
  | expr GEQ    expr { Binop($1, Geq,   $3)   }
  | expr AND    expr { Binop($1, And,   $3)   }
  | expr OR     expr { Binop($1, Or,    $3)   }
  | MINUS expr %prec NOT { Unop(Neg, $2)      }
  | NOT expr         { Unop(Not, $2)          }
  | ID ASSIGN expr   { Assign($1, $3)         }
  | ID LPAREN args_opt RPAREN { Call($1, $3)  }
  | LPAREN expr RPAREN        { $2            }
  | LBRACK mat_opt RBRACK     { Mat($2)       }
  | ID PERIOD COL             { Col($1)       }
  | ID PERIOD ROW             { Row($1)       }
  | ID LBRACK expr RBRACK LBRACK expr RBRACK
                      { Access($1, $3, $6)    }
                      

mat_opt:
    /* nothing */ { [] }
  | row_list      { List.rev $1 }

row_list:
    LBRACK row_expr RBRACK                { [(List.rev $2)]        }
  | row_list COMMA LBRACK row_expr RBRACK {  (List.rev $4) :: $1 }

row_expr:
    /* nothing */            { []       }
  | expr                     { [$1]    }
  | row_expr COMMA expr      { $3 :: $1 }


args_opt:
    /* nothing */ { [] }
  | args_list  { List.rev $1 }

args_list:
    expr                    { [$1] }
  | args_list COMMA expr { $3 :: $1 }
