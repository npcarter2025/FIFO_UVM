# ============================================================================
# UVM FIFO Testbench Makefile for VCS
# ============================================================================

# Tool settings
VCS = vcs
SIMV = simv

# UVM settings
UVM_HOME ?= $(VCS_HOME)/etc/uvm-1.2
UVM_VERBOSITY ?= UVM_MEDIUM

# Source files (with paths)
RTL_SOURCES = dut/fifo.sv
TB_SOURCES = dut/fifo_if.sv tests/fifo_pkg.sv tb/tb_top.sv

ALL_SOURCES = $(RTL_SOURCES) $(TB_SOURCES)

# Test name (can override with: make run TEST=fifo_test)
BASICTEST = 0
OVERFLOWTEST = 0
ALLTESTS = 1

ifeq ($(BASICTEST), 1)
	TEST ?= fifo_test
else
	ifeq ($(OVERFLOWTEST), 1)

		TEST ?= fifo_overflow_test
	else 

		TEST ?= fifo_test

		
	endif
endif


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

# Default target - use run_all if ALLTESTS=1, otherwise use run
ifeq ($(ALLTESTS), 1)
all: compile run_all
else
all: compile run
endif

# Compile the design
compile:
	$(VCS) $(VCS_FLAGS) $(ALL_SOURCES) -o $(SIMV)

# Run simulation
run: compile
	./$(SIMV) $(RUN_FLAGS) -cm line+cond+branch+tgl+assert


run_all: compile
	@echo "============================================================"
	@echo "Running fifo_test..."
	@echo "============================================================"
	./$(SIMV) +UVM_TESTNAME=fifo_test +UVM_VERBOSITY=$(UVM_VERBOSITY) -cm line+cond+branch+tgl+assert -cm_dir cov.vdb -cm_name fifo_test_cov || true
	@echo ""
	@echo "============================================================"
	@echo "Running fifo_overflow_test..."
	@echo "============================================================"
	./$(SIMV) +UVM_TESTNAME=fifo_overflow_test +UVM_VERBOSITY=$(UVM_VERBOSITY) -cm line+cond+branch+tgl+assert -cm_dir cov.vdb -cm_name fifo_overflow_test_cov || true
	@echo ""
	@echo "============================================================"
	@echo "All tests finished!"
	@echo "============================================================"

# Run simulation with waves
run_waves: compile
	./$(SIMV) $(RUN_FLAGS) +fsdb+all

# Run with GUI debugger (DVE)
gui: compile
	./$(SIMV) $(RUN_FLAGS) -gui &

# Coverage report (runs URG on cov.vdb)
report: run
	urg -dir cov.vdb -format both -report cov_report

# View coverage in Verdi (Note: requires Verdi version matching VCS version)
# Current VCS is T-2022.06-SP2-9, but Verdi is T-2022.06-SP2 (incompatible)
# Use 'make report' for HTML coverage reports instead
cov_view:
	@echo "Warning: Verdi version mismatch. VDB created with VCS T-2022.06-SP2-9"
	@echo "but Verdi T-2022.06-SP2 is available. Use 'make report' for HTML reports."
	verdi -cov -covdir cov.vdb &

# ============================================================================
# Phase 1: Register Test (Non-UVM directed test)
# ============================================================================

# Register test source files
REG_RTL_SOURCES = dut/fifo_regs.sv dut/fifo_core.sv dut/fifo_top.sv
REG_TB_SOURCES = tb/tb_fifo_regs.sv

# Compile register test
compile_regs:
	$(VCS) -sverilog -debug_access+all -full64 -timescale=1ns/1ps \
	       $(REG_RTL_SOURCES) $(REG_TB_SOURCES) -o simv_regs

# Run register test
run_regs: compile_regs
	./simv_regs
	@echo ""
	@echo "============================================================"
	@echo "Register test complete! Check output above for PASS/FAIL"
	@echo "============================================================"

# Run register test with waves
run_regs_waves: compile_regs
	./simv_regs
	@echo "Waveform saved to tb_fifo_regs.vcd"

# ============================================================================
# Phase 2: UVM Register Agent Test
# ============================================================================

# Register agent source files
REG_AGENT_RTL = dut/fifo_regs.sv dut/fifo_core.sv dut/fifo_top.sv
REG_AGENT_IF  = reg_agent/reg_if.sv
REG_AGENT_PKG = reg_agent/reg_pkg.sv
REG_AGENT_TB  = tb/tb_reg_agent.sv

REG_AGENT_TEST ?= reg_sanity_test

# VCS flags for UVM register agent test
REG_VCS_FLAGS = -sverilog \
                -debug_access+all \
                -full64 \
                -timescale=1ns/1ps \
                -ntb_opts uvm-1.2 \
                +incdir+$(UVM_HOME)/src \
                +incdir+reg_agent

# Compile UVM register agent test
compile_reg_agent:
	$(VCS) $(REG_VCS_FLAGS) $(REG_AGENT_RTL) $(REG_AGENT_IF) $(REG_AGENT_PKG) $(REG_AGENT_TB) -o simv_reg_agent

# Run UVM register agent test
run_reg_agent: compile_reg_agent
	./simv_reg_agent +UVM_TESTNAME=$(REG_AGENT_TEST) +UVM_VERBOSITY=$(UVM_VERBOSITY)
	@echo ""
	@echo "============================================================"
	@echo "Register agent test complete!"
	@echo "============================================================"

# ============================================================================
# Phase 3: RAL Model Compilation Check
# ============================================================================

# RAL source files
RAL_SOURCES = ral/fifo_ral_pkg.sv

# Compile RAL model (checks that it compiles correctly)
compile_ral:
	$(VCS) -sverilog \
	       -full64 \
	       -timescale=1ns/1ps \
	       -ntb_opts uvm-1.2 \
	       +incdir+$(UVM_HOME)/src \
	       +incdir+reg_agent \
	       +incdir+ral \
	       $(REG_AGENT_IF) $(REG_AGENT_PKG) $(RAL_SOURCES) \
	       -top fifo_ral_pkg \
	       -o simv_ral_check
	@echo ""
	@echo "============================================================"
	@echo "RAL model compiled successfully!"
	@echo "============================================================"

# Clean generated files
clean:
	rm -rf $(SIMV) $(SIMV).daidir csrc ucli.key vc_hdrs.h $(VCD)
	rm -rf *.log *.fsdb cov.vdb simv.vdb AN.DB novas.*
	rm -rf cov_report urgReport
	rm -rf simv_regs simv_regs.daidir tb_fifo_regs.vcd
	rm -rf simv_reg_agent simv_reg_agent.daidir tb_reg_agent.vcd
	rm -rf simv_ral_check simv_ral_check.daidir

# Clean everything including VCS work directories
cleanall: clean
	rm -rf DVEfiles simv.daidir .vcs_lib_lock .inter.vpd.uvm

html: 
	@echo "Starting HTTP server on port 8000..."
	@cd cov_report && python3 -m http.server 8000 &
	@sleep 2
	@echo "Opening Firefox..."
	@if [ -z "$$DISPLAY" ]; then export DISPLAY=:0.0; fi; \
	firefox http://localhost:8000/dashboard.html &
	@echo "Server running. Press Ctrl+C to stop, or run: pkill -f 'python3 -m http.server 8000'"

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
	@echo "Phase 1 Register Test (Non-UVM):"
	@echo "  make run_regs       - Compile and run register directed test"
	@echo "  make compile_regs   - Compile register test only"
	@echo "  make run_regs_waves - Run register test with VCD dump"
	@echo ""
	@echo "Phase 2 UVM Register Agent Test:"
	@echo "  make run_reg_agent     - Compile and run UVM register agent test"
	@echo "  make compile_reg_agent - Compile UVM register agent test only"
	@echo ""
	@echo "Phase 3 RAL Model:"
	@echo "  make compile_ral       - Compile RAL model (verification)"
	@echo ""
	@echo "Variables:
	@echo "  TEST=<name>       - Specify test name (default: fifo_test)"
	@echo "  UVM_VERBOSITY=X   - Set verbosity (UVM_LOW/MEDIUM/HIGH/DEBUG)"
	@echo ""
	@echo "Examples:"
	@echo "  make run TEST=fifo_test UVM_VERBOSITY=UVM_HIGH"
	@echo "  make run_regs  # Run Phase 1 register sanity test"
	@echo "============================================================"

.PHONY: all compile run run_waves gui report cov_view clean cleanall help run_all html compile_regs run_regs run_regs_waves compile_reg_agent run_reg_agent compile_ral
