(* Semantic checking for the RedPandas compiler *)

open Ast
open Sast

module StringMap = Map.Make(String)

(* Semantic checking of the AST. Returns an SAST if successful,
   throws an exception if something is wrong.

   Check each global variable, then check each function *)

let check (globals, functions) =

  (* Verify a list of bindings has no void types or duplicate names *)
  let check_binds (kind : string) (binds : bind list) =
    List.iter (function
	(Void, b) -> raise (Failure ("illegal void " ^ kind ^ " " ^ b))
      | _ -> ()) binds;
    let rec dups = function
        [] -> ()
      |	((_,n1) :: (_,n2) :: _) when n1 = n2 ->
	  raise (Failure ("duplicate " ^ kind ^ " " ^ n1))
      | _ :: t -> dups t
    in dups (List.sort (fun (_,a) (_,b) -> compare a b) binds)
  in

  (**** Check global variables ****)

  check_binds "global" globals;

  (**** Check functions ****)

  (* Collect function declarations for built-in functions: no bodies *)
  let built_in_decls = 
    let add_bind map (name, ty) = StringMap.add name {
      typ = Void;
      fname = name; 
      formals = [(ty, "x")];
      locals = []; body = [] } map
    in List.fold_left add_bind StringMap.empty [ ("print", Int);
			                         ("printb", Bool);
			                         ("printf", Float);
			                         ("printbig", Int);
                               ("printStr", String) ]
  in

  (* Add function name to symbol table *)
  let add_func map fd = 
    let built_in_err = "function " ^ fd.fname ^ " may not be defined"
    and dup_err = "duplicate function " ^ fd.fname
    and make_err er = raise (Failure er)
    and n = fd.fname (* Name of the function *)
    in match fd with (* No duplicate functions or redefinitions of built-ins *)
         _ when StringMap.mem n built_in_decls -> make_err built_in_err
       | _ when StringMap.mem n map -> make_err dup_err  
       | _ ->  StringMap.add n fd map 
  in

  (* Collect all function names into one symbol table *)
  let function_decls = List.fold_left add_func built_in_decls functions
  in
  
  (* Return a function from our symbol table *)
  let find_func s = 
    try StringMap.find s function_decls
    with Not_found -> raise (Failure ("unrecognized function " ^ s))
  in

  let _ = find_func "main" in (* Ensure "main" is defined *)

  let check_function func =
    (* Make sure no formals or locals are void or duplicates *)
    check_binds "formal" func.formals;
    check_binds "local" func.locals;

    (* Raise an exception if the given rvalue type cannot be assigned to
       the given lvalue type *)
    let check_assign lvaluet rvaluet err =
       if lvaluet = rvaluet then lvaluet else raise (Failure err)
    in   

    (* Build local symbol table of variables for this function *)
    let symbols = List.fold_left (fun m (ty, name) -> StringMap.add name ty m)
	                StringMap.empty (globals @ func.formals @ func.locals )
    in

    (* Return a variable from our local symbol table *)
    let type_of_identifier s =
      try StringMap.find s symbols
      with Not_found -> raise (Failure ("undeclared identifier " ^ s))
    in

    (* Return a semantically-checked expression, i.e., with a type *)
    let rec expr = function
        Literal  l -> (Int, SLiteral l)
      | Fliteral l -> (Float, SFliteral l)
      | BoolLit l  -> (Bool, SBoolLit l)
      | StrLit l   -> (String, SStrLit l)
      | Noexpr     -> (Void, SNoexpr)
      | Id s       -> (type_of_identifier s, SId s)
      | Assign(var, e) as ex -> 
          let (lt, var') = expr var
          and (rt, e') = expr e in
          let err = "illegal assignment " ^ string_of_typ lt ^ " = " ^ 
            string_of_typ rt ^ " in " ^ string_of_expr ex
          in (check_assign lt rt err, SAssign((lt, var'), (rt, e')))
      | Unop(op, e) as ex -> 
          let (t, e') = expr e in
          let ty = match op with
            Neg when t = Int || t = Float -> t
          | Not when t = Bool -> Bool
          | _ -> raise (Failure ("illegal unary operator " ^ 
                                 string_of_uop op ^ string_of_typ t ^
                                 " in " ^ string_of_expr ex))
          in (ty, SUnop(op, (t, e')))
      | Binop(e1, op, e2) as e -> 
          let (t1, e1') = expr e1 
          and (t2, e2') = expr e2 in
          (* All binary operators require operands of the same type *)
          let same = t1 = t2 in
          let error = "illegal binary operator " ^
          string_of_typ t1 ^ " " ^ string_of_op op ^ " " ^
          string_of_typ t2 ^ " in " ^ string_of_expr e in 
          (* Determine expression type based on operator and operand types *)
          let ty = match op with
            Add | Sub | Mult | Div when same && t1 = Int   -> Int
          | Add | Sub | Mult | Div when same && t1 = Float -> Float
          | Add | Sub | Elmult| Eldiv -> (match t1, t2 with 
                Matrix(s1,a1,b1), Matrix(s2,a2,b2) ->
                  if s1=s2 && a1 = a2 && b1 = b2 then Matrix(s1,a1,b1)
                  else raise (Failure "illegal binary operator for matrix of different sizes")
                   | _ -> raise (Failure error))
          | Mult  -> (match t1, t2 with 
                Matrix(s1,a1,b1), Matrix(s2,a2,b2) ->
                  if s1=s2 && b1 = a2 then Matrix(s1,a1,b2)
                  else raise (Failure "illegal dimensions for matrix mult")
                  | _ -> raise (Failure error))
          | Equal | Neq            when same               -> Bool
          | Less | Leq | Greater | Geq
                     when same && (t1 = Int || t1 = Float) -> Bool
          | And | Or when same && t1 = Bool -> Bool
          | _ -> raise (Failure error)
          in (ty, SBinop((t1, e1'), op, (t2, e2')))
      | Call(fname, args) as call -> 
          let fd = find_func fname in
          let param_length = List.length fd.formals in
          if List.length args != param_length then
            raise (Failure ("expecting " ^ string_of_int param_length ^ 
                            " arguments in " ^ string_of_expr call))
          else let check_call (ft, _) e = 
            let (et, e') = expr e in 
            let err = "illegal argument found " ^ string_of_typ et ^
              " expected " ^ string_of_typ ft ^ " in " ^ string_of_expr e
            in (check_assign ft et err, e')
          in 
          let formals = List.map (fun (tp, var) -> (tp,var)) fd.formals in
          let args' = List.map2 check_call formals args
          in (fd.typ, SCall(fname, args'))
      
      | Mat(arr) ->
        let sArr = (List.map (fun l -> (List.map expr l)) arr) in
          let row_lengths = List.map List.length arr in 
          if not (List.for_all (fun l -> if List.hd(row_lengths) = l then true else false) row_lengths) then
            raise (Failure ("Matrix rows must be of same length"))
          else 
            let (wt, _) = expr (List.hd(List.hd(arr))) in
            let r = List.length arr in 
            let c = List.length (List.hd arr) in
            let expr_check = function 
                (Int, _) when wt = Int -> true 
              | (Float, _) when wt = Float -> true
              | _ -> raise (Failure("Matrix types don't match")) 
            in
            ignore(List.for_all (fun j -> List.for_all (fun k -> expr_check (expr k)) j) arr);
            (Matrix (wt, r, c), SMat(wt, sArr))
      | Col(s)     -> 
          (match type_of_identifier s with
            Matrix(_,_,c) -> 
              (match c with 
              c -> (Int, SCol(c))
              | _ -> raise(Failure "Add int column value to matrix decl"))
            |_ -> raise(Failure "Cannot find column value of non-matrix"))
      | Row(s)     -> 
          (match type_of_identifier s with
            Matrix(_,r,_) -> 
              (match r with 
              r -> (Int, SRow(r))
              | _ -> raise(Failure "Add int column value to matrix decl"))
            |_ -> raise(Failure "Cannot find column value of non-matrix"))
      | Tran(s)    -> 
          (match type_of_identifier s with
            Matrix(t,r,c) -> (Matrix(t,c,r), STran(s, Matrix(t,r,c)))
            |_ -> raise(Failure "Cannot find column value of non-matrix"))
      | Access(s, r, c) -> let (row, row') = expr r in
                      let(col,col') = expr c in
                      if (col = Int)
                        then (if(row = Int)
                                then ()
                                else raise(Failure "row value is non-integer");)
                        else raise(Failure "column value is non-integer");
                      (match type_of_identifier s with
                      Matrix(t,_,_) -> (t, SAccess(s, (row, row'), (col,col')))
                      | _ -> raise(Failure "Cannot perform access operation on a non-matrix type")
                      )

       


            
    in

    let check_bool_expr e = 
      let (t', e') = expr e
      and err = "expected Boolean expression in " ^ string_of_expr e
      in if t' != Bool then raise (Failure err) else (t', e') 
    in

    (* Return a semantically-checked statement i.e. containing sexprs *)
    let rec check_stmt = function
        Expr e -> SExpr (expr e)
      | If(p, b1, b2) -> SIf(check_bool_expr p, check_stmt b1, check_stmt b2)
      | For(e1, e2, e3, st) ->
	  SFor(expr e1, check_bool_expr e2, expr e3, check_stmt st)
      | While(p, s) -> SWhile(check_bool_expr p, check_stmt s)
      | Return e -> let (t, e') = expr e in
        if t = func.typ then SReturn (t, e') 
        else raise (
	  Failure ("return gives " ^ string_of_typ t ^ " expected " ^
		   string_of_typ func.typ ^ " in " ^ string_of_expr e))
	    
	    (* A block is correct if each statement is correct and nothing
	       follows any Return statement.  Nested blocks are flattened. *)
      | Block sl -> 
          let rec check_stmt_list = function
              [Return _ as s] -> [check_stmt s]
            | Return _ :: _   -> raise (Failure "nothing may follow a return")
            | Block sl :: ss  -> check_stmt_list (sl @ ss) (* Flatten blocks *)
            | s :: ss         -> check_stmt s :: check_stmt_list ss
            | []              -> []
          in SBlock(check_stmt_list sl)

    in (* body of check_function *)
    { styp = func.typ;
      sfname = func.fname;
      sformals = func.formals;
      slocals  = func.locals;
      sbody = match check_stmt (Block func.body) with
	SBlock(sl) -> sl
      | _ -> raise (Failure ("internal error: block didn't become a block?"))
    }
  in (globals, List.map check_function functions)
