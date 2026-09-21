XRUN?=xrun
VERILATOR?=verilator-cli
TEST?=async_fifo_test
SEED?=random
.PHONY: uvm regress lint smoke clean
uvm:
	mkdir -p results
	$(XRUN) -64bit -sv -uvm -f sim/files.f -top tb_top +UVM_TESTNAME=$(TEST) \
	 -svseed $(SEED) -access +rwc -coverage all -covoverwrite -covworkdir results/xcelium_cov \
	 -l results/xrun_$(TEST).log
regress:
	@for seed in 13 31 59 97 127; do $(MAKE) uvm SEED=$$seed || exit 1; done
lint:
	$(VERILATOR) --lint-only --sv --timing -Wall -Wno-fatal rtl/async_fifo.sv
smoke:
	rm -rf build/obj_async_fifo
	mkdir -p build
	$(VERILATOR) --binary --sv --timing --assert -Wall -Wno-fatal -Wno-SYNCASYNCNET --top-module tb_async_fifo_smoke \
	 --Mdir build/obj_async_fifo rtl/async_fifo.sv tb/assertions/async_fifo_sva.sv \
	 tb/smoke/tb_async_fifo_smoke.sv
	bash -o pipefail -c './build/obj_async_fifo/Vtb_async_fifo_smoke | tee results_smoke.log'
clean:
	rm -rf build xcelium.d INCA_libs waves.shm results *.log *.key
