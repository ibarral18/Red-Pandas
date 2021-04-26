# "make test" Compiles everything and runs the regression tests

.PHONY : test
test : all testall.sh
	./testall.sh

# "make all" builds the executable as well as the "printbig" library designed
# to test linking external code

.PHONY : all
all : redpandas.native printbig.o

# "make redpandas.native" compiles the compiler
#
# The _tags file controls the operation of ocamlbuild, e.g., by including
# packages, enabling warnings
#
# See https://github.com/ocaml/ocamlbuild/blob/master/manual/manual.adoc

redpandas.native :
	opam config exec -- \
	ocamlbuild -use-ocamlfind redpandas.native

# "make clean" removes all generated files

.PHONY : clean
clean :
	ocamlbuild -clean
	rm -rf testall.log ocamlllvm *.diff *.err *.ll *.s *.exe

.PHONY : smallclean
smallclean :
	rm -rf testall.log *.diff *.err *.ll
	rm *.exe *.s *.out

# Testing the "printbig" example

printbig : printbig.c
	cc -o printbig -DBUILD_TEST printbig.c

# Building the tarball

TESTS = \
  add1 arith1 arith2 arith3 fib float1 float2 float3 for1 for2 func1 \
  func2 func3 func4 func5 func6 func7 func8 func9 gcd2 gcd global1 \
  global2 global3 hello if1 if2 if3 if4 if5 if6 local1 local2 ops1 \
  ops2 printbig var1 var2 while1 while2

FAILS = \
  assign1 assign2 assign3 dead1 dead2 expr1 expr2 expr3 float1 float2 \
  for1 for2 for3 for4 for5 func1 func2 func3 func4 func5 func6 func7 \
  func8 func9 global1 global2 if1 if2 if3 nomain printbig printb print \
  return1 return2 while1 while2

TESTFILES = $(TESTS:%=test-%.rp) $(TESTS:%=test-%.out) \
	    $(FAILS:%=fail-%.rp) $(FAILS:%=fail-%.err)

TARFILES = ast.ml sast.ml codegen.ml Makefile _tags redpandas.ml parser.mly \
	README.md scanner.mll semant.ml testall.sh \
	printbig.c arcade-font.pbm font2c \
	Dockerfile hello_world.rp hello_world_2.rp \
	$(TESTFILES:%=tests/%) 

redpandas.tar.gz : $(TARFILES)
	cd .. && tar czf Red-Pandas/redpandas.tar.gz \
		$(TARFILES:%=Red-Pandas/%)
