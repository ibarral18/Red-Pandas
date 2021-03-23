

## TO-DO
- Update variable declarations to our own style of in-line variable and assignment.
- add matrices
- add more math functions
- fix variable declaration to be prettier
- add "def" to test cases
- fix file extensions

## To build and run hello world

```
//building
make redpandas.native

//compiling test case
./redpandas.native hello_world_2.mc > hello_world_2.ll
llc -relocation-model=pic hello_world_2.ll > hello_world_2.s
cc -o hello_world_2.exe hello_world_2.s printbig.o
./hello_world_2.exe

// or you can just do the printing thing after building
./redpandas.native -a tests/test-gcd.mc
```
