# ============================================================================
# UVM FIFO Testbench Makefile for VCS
# ============================================================================

# Tool settings
VCS = vcs
SIMV = simv

# UVM settings
UVM_HOME ?= $(VCS_HOME)/etc/uvm-1.2
UVM_VERBOSITY ?= UVM_MEDIUM

# Source files
RTL_SOURCES = fifo.sv
TB_SOURCES = fifo_if.sv fifo_pkg.sv tb_top.sv

ALL_SOURCES = $(RTL_SOURCES) $(TB_SOURCES)

# Test name (can override with: make run TEST=fifo_test)
TEST ?= fifo_test

# VCD dump file
VCD = dump.vcd

# VCS compilation flags
VCS_FLAGS = -sverilog \
            -debug_access+all \
            -lca \
            -kdb \
            +v2k \
            -full64 \
            -timescale=1ns/1ps \
            -ntb_opts uvm-1.2 \
            +incdir+$(UVM_HOME)/src \
            +incdir+. \
            -cm line+cond+branch+tgl+assert \
            -cm_dir cov.vdb \
            -cm_name fifo_cov

# Runtime flags
RUN_FLAGS = +UVM_TESTNAME=$(TEST) \
            +UVM_VERBOSITY=$(UVM_VERBOSITY)

# ============================================================================
# Targets
# ============================================================================

# Default target
all: compile run

# Compile the design
compile:
	$(VCS) $(VCS_FLAGS) $(ALL_SOURCES) -o $(SIMV)

# Run simulation
run: compile
	./$(SIMV) $(RUN_FLAGS)

# Run simulation with waves
run_waves: compile
	./$(SIMV) $(RUN_FLAGS) +fsdb+all

# Run with GUI debugger (DVE)
gui: compile
	./$(SIMV) $(RUN_FLAGS) -gui &

# Coverage report (runs URG on cov.vdb)
report: run
	urg -dir cov.vdb -format both -report cov_report

# View coverage in Verdi
cov_view:
	verdi -cov -covdir cov.vdb &

# Clean generated files
clean:
	rm -rf $(SIMV) $(SIMV).daidir csrc ucli.key vc_hdrs.h $(VCD)
	rm -rf *.log *.fsdb cov.vdb simv.vdb AN.DB novas.*
	rm -rf cov_report urgReport

# Clean everything including VCS work directories
cleanall: clean
	rm -rf DVEfiles simv.daidir .vcs_lib_lock .inter.vpd.uvm

# Help target
help:
	@echo "============================================================"
	@echo "UVM FIFO Testbench Makefile"
	@echo "============================================================"
	@echo ""
	@echo "Available targets:"
	@echo "  make              - Compile and run simulation"
	@echo "  make compile      - Compile only"
	@echo "  make run          - Run simulation (compiles if needed)"
	@echo "  make run_waves    - Run with waveform dumping"
	@echo "  make gui          - Run with DVE GUI"
	@echo "  make report       - Generate coverage report with URG"
	@echo "  make cov_view     - View coverage in Verdi"
	@echo "  make clean        - Remove generated files"
	@echo "  make cleanall     - Remove all VCS generated files"
	@echo "  make help         - Show this help message"
	@echo ""
	@echo "Variables:"
	@echo "  TEST=<name>       - Specify test name (default: fifo_test)"
	@echo "  UVM_VERBOSITY=X   - Set verbosity (UVM_LOW/MEDIUM/HIGH/DEBUG)"
	@echo ""
	@echo "Examples:"
	@echo "  make run TEST=fifo_test UVM_VERBOSITY=UVM_HIGH"
	@echo "============================================================"

.PHONY: all compile run run_waves gui report cov_view clean cleanall help
