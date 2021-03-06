CC = clang

# set OPT_FLAGS to -DUSE_BLAS to use BLAS backend
OPT_FLAGS?=

debug:   CFLAGS = -std=c89 -g -O0 -DDEBUG
release: CFLAGS = -std=c89 -O3 -march=native

LFLAGS = -lm

# Detect OS
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
    MKL_OS = linux
endif
ifeq ($(UNAME_S),Darwin)
    MKL_OS = mac
endif

MKL_BASE = /opt/intel/compilers_and_libraries/$(MKL_OS)

ifeq ($(UNAME_S),Linux)
    MKL_PATH1 = $(MKL_BASE)/mkl/lib/intel64
    MKL_PATH2 = $(MKL_BASE)/lib/intel64
endif
ifeq ($(UNAME_S),Darwin)
    MKL_PATH1 = $(MKL_BASE)/mkl/lib
    MKL_PATH2 = $(MKL_BASE)/lib
endif

CFLAGS += -I$(MKL_PATH1)/include

MKLFLAGS =  $(MKL_PATH1)/libmkl_intel_lp64.a
MKLFLAGS += $(MKL_PATH1)/libmkl_intel_thread.a
MKLFLAGS += $(MKL_PATH1)/libmkl_core.a

# TODO(jonas): cleanup later
ifeq ($(UNAME_S),Linux)
    MKLFLAGS += $(MKL_PATH1)/*.a $(MKL_PATH1)_lin/*.a
endif

MKLFLAGS += $(MKL_PATH2)/libiomp5.a
MKLFLAGS += -lpthread -ldl


TARGET = main
TEST_TARGET = $(TARGET)_tests
TEST_MAIN = $(TARGET)_tests.c
TEST_LOG = $(TARGET)_tests.log

all: debug

debug:   clean $(TARGET)
release: clean $(TARGET)

$(TARGET):
	$(CC) src/main.c -o $(TARGET) $(CFLAGS) $(LFLAGS) $(MKLFLAGS) $(OPT_FLAGS)


disassembly:
	$(CC) src/main.c -S -o $(TARGET)_asm.txt $(CFLAGS) $(LFLAGS) $(MKLFLAGS) $(OPT_FLAGS)


preprocessor:
	$(CC) src/main.c -E -o $(TARGET)_pp.c $(OPT_FLAGS)	


tests/naive:
	@echo "Tests without BLAS / LAPACK:"
	@rm -f $(TEST_TARGET) $(TEST_LOG) $(TEST_MAIN)
	@./scripts/gen_test_main.sh > $(TEST_MAIN)
	@$(CC) $(TEST_MAIN) -o $(TEST_TARGET) $(CFLAGS) -DTEST $(LFLAGS)
	@./$(TEST_TARGET) 2> $(TEST_LOG)
	@rm -f $(TEST_TARGET) $(TEST_MAIN)

tests/blas:
	@echo "Tests with BLAS / LAPACK:"
	@rm -f $(TEST_TARGET) $(TEST_LOG) $(TEST_MAIN)
	@./scripts/gen_test_main.sh > $(TEST_MAIN)
	@$(CC) $(TEST_MAIN) -o $(TEST_TARGET) $(CFLAGS) -DTEST -DUSE_BLAS $(LFLAGS) $(MKLFLAGS)
	@./$(TEST_TARGET) 2> $(TEST_LOG)
	@rm -f $(TEST_TARGET) $(TEST_MAIN)

tests: tests/blas tests/naive

clean:
	rm -f $(TARGET)

.PHONY: all clean debug release tests


