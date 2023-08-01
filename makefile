#.SILENT:
-include makefile.local
ifndef compiler
compiler := gcc -Wall -Werror -c
endif

ifndef linker
linker := gcc -Wall -Werror
endif

ifndef thundertester_linker_flags
thundertester_linker_flags := -lthundertester 
endif

ifndef thundertester_compiler_flags
thundertester_compiler_flags := -DTEST
endif

ifndef utilities_linker_flags
utilities_linker_flags := -L$(HOME)/Projects/Utilities/release/lib/ -lutilities
endif

ifndef utilities_compiler_flags
utilities_compiler_flags := -I$(HOME)/Projects/Utilities/release/include/utilities/
endif

compiler_flags := -I./src -ggdb $(utilities_compiler_flags) 
linker_flags := -lm -llapack -lblas $(utilities_linker_flags)

source_path := src
mode_path := .tmp
object_path := .tmp/objects
dependencies_path := .tmp/dependencies
include_files_path := release/include/minerva

all_source_files := $(shell find $(source_path) -regex [^\#]*\\.c$)
program_source_files := $(filter $(source_path)/programs/%.c,$(all_source_files))
function_source_files := $(filter-out $(source_path)/programs/%.c $(source_path)/tests/%.c,$(all_source_files))
function_object_files := $(function_source_files:$(source_path)/%.c=$(object_path)/%.o)
dependencies_files := $(all_source_files:$(source_path)/%.c=$(dependencies_path)/%.d)
program_names := $(program_source_files:$(source_path)/programs/%.c=./release/%.x)
test_program_names := $(program_source_files:$(source_path)/programs/%.c=./test/%.x)

all: compiler_flags+=-DNDEBUG -DNLOGING
all: $(mode_path)/release.mode
	make $(program_names)

test: $(mode_path)/test.mode
	make $(test_program_names)

.PRECIOUS: $(dependencies_files) $(function_object_files)

clear:
	echo "Cleaning up"
	rm -rf ./.tmp/
	rm -rf ./release/
	rm -rf ./test/

$(mode_path)/%.mode: 
	echo "Generating: $@"
	rm -rf ./.tmp/
	mkdir -p $(@D)
	echo "Intentionaly empty" > $@

release/%.x: compiler_flags+=-O3 -DNDEBUG -DNLOGING
release/%.x: $(object_path)/programs/%.o $(function_object_files)
	echo "Linking: $@"
	mkdir -p $(@D)
	$(linker) -o $(@) $^ $(linker_flags)

test/%.x: linker_flags+=$(thundertester_linker_flags)
test/%.x: compiler_flags+=-ggdb $(thundertester_compiler_flags) -DTEST_DATA="\"./test_data/\""
test/%.x: $(object_path)/programs/%.o $(function_object_files)
	echo "Linking test: $@"
	mkdir -p $(@D)
	$(linker) -o $(@) $^ $(linker_flags)

-include $(dependencies_files)

$(object_path)/%.o: $(source_path)/%.c $(dependencies_path)/%.d
	echo "Compiling: $@"
	mkdir -p $(@D)
	$(compiler) -o $@ $< $(compiler_flags)

$(dependencies_path)/%.d: $(source_path)/%.c
	echo "Generating: $@"
	mkdir -p $(@D)
	$(compiler) -o /dev/null -M -MF $@ -MT $(@:$(dependencies_path)/%.d=$(object_path)/%.o) $< $(compiler_flags)

