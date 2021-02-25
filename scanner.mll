{ open Parser }

rule tokenize = parse
(*whitespace*)
  [' ' '\t' '\r' '\n'] { tokenize lexbuf }
(*comments*)
| "/*" { comment lexbuf }
| "//" { line_comment lexbuf}
(*operators*)
| '+'  { PLUS }
| '-'  { MINUS }
| '*'  { TIMES }
| '/'  { DIVIDE }
| '='  { ASSIGN }
| '^'  { POWER }
| '|'  { ABS }
(*logic*)
| "==" { EQUALS }
| "!=" { NOTEQ }
| '<'  { LESS }
| "<=" { LEQ }
| '>'  { GREAT }
| ">=" { GEQ }
| "&&" { AND }
| '!'  { NOT }
(*flow*)
| "if"       { IF }
| "else"     { ELSE }
| "for"      { FOR }
| "while"    { WHILE }
| "return"   { RETURN }
| "break"    { BREAK }
| "def"      { DEF}
| "continue" { CONTINUE }
(*types*)
| "int"    { INT }
| "bool"   { BOOL }
| "void"   { VOID }
| "matrix" { MATRIX }
| "true"   { TRUE }
| "false"  { FALSE }
(*organization*)
| '['      { LBRACK }
| ']'      { RBRACK }
| '('      { LPAREN }
| ')'      { RPAREN }
| '{'      { LBRACE }
| '}'      { RBRACE }
| ':'      { COLON }
| ';'      { SEMI }
| ','      { COMMA }
(*literals*)
| ['0'-'9']+ as lit { LITERAL(int_of_string lit) }
| (['0'-'9']*)'.'(['0'-'9']+) as dub { DOUBLE_LITERAL(float_of_string dub) }
| (['0'-'9']*)'.'(['0'-'9']*) as dub { DOUBLE_LITERAL(float_of_string dub) }
| '"' ([^ '"']* as str ) '"' { STRING_LITERAL(str) }
| ['a'-'z' 'A'-'Z' '_'] ['0'-'9' 'a'-'z' 'A'-'Z' '_']* as var { VARIABLE(var) }
| eof { EOF }
| _ as char { raise (Failure("illegal character " ^ Char.escaped car ))}

and comment = parse
  "*/" { token lexbuf }
  | _  { comment lexbuf }

and line_comment = parse
  "\n" { token lexbuf }
  | _  { line_comment lexbuf }