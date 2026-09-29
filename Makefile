# --- Variables ---
# Apuntar a la carpeta 'tb' para encontrar testbench.sv
TB_FILE = tb/testbench.sv
OUT_BIN = salida
SEED   ?= 1

# Agregar +incdir+ para incluir las carpetas con el código fuente y el banco de pruebas
VCS_FLAGS = -Mupdate -full64 -sverilog -kdb -lca -debug_acc+all -debug_region+cell +incdir+src +incdir+tb

.PHONY: all compilar simular regresion grafico limpiar

# --- Reglas ---
all: compilar simular

compilar:
	vcs $(VCS_FLAGS) $(TB_FILE) -o $(OUT_BIN)

simular:
	./$(OUT_BIN) +ntb_random_seed=$(SEED)
	mkdir -p results
	cp reporte_paquetes.csv results/reporte_seed$(SEED).csv

regresion: compilar
	for s in 1 2 3 4 5; do $(MAKE) simular SEED=$$s; done

grafico:
	gnuplot scripts/histograma_retardos.plt

limpiar:
	rm -rf csrc simv.daidir *.key $(OUT_BIN) *.vpd DVEfiles *.fsdb vc_hdrs.h

barrido_pckgsz: compilar
	mkdir -p results
	for sz in 16 32 64; do \
	  vcs $(VCS_FLAGS) $(TB_FILE) \
	    -pvalue+testbench.PCKG_SZ=$$sz \
	    -pvalue+testbench.BITS=$$sz \
	    +define+PCKG_SZ=$$sz \
	    -o $(OUT_BIN)_sz$$sz \
	    -l compile_sz$$sz.log; \
	  ./$(OUT_BIN)_sz$$sz +ntb_random_seed=1; \
	  cp reporte_paquetes.csv results/reporte_pckgsz$$sz.csv; \
	done
