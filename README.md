WORKING IN THE "HELLO" BRANCH
currently just microC with our def function syntax

## TO-DO

- add strings and matrices
- add more math functions
- fix variable declaration to be prettier
- add "def" to test cases

## To build and run hello world

```
//building
ocamlbuild -use-ocamlfind -pkgs llvm,llvm analysis -cflags -w,+a-4 microc.native

//compiling test case
./redpandas.native tests/test-gcd.mc > test-gcd.ll
llc -relocation-model=pic test-gcd.ll > test-gcd.s
cc -o test-gcd.exe test-gcd.s printbig.o
./test-gcd.exe

// or you can just do the printing thing after building
./redpandas.native -a tests/test-gcd.mc
```
