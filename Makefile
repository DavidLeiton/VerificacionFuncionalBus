# ============================================================================
# Makefile - Proyecto 1: Verificacion funcional de un bus con arbitraje
#            round-robin distribuido (DUT: bs_gnrtr_n_rbtr)
# ============================================================================

# --- Variables ---
TB_FILE = tb/testbench.sv
OUT_BIN = salida
SEED   ?= 1
DRVRS   ?= 4
PCKG_SZ ?= 16

VCS_FLAGS = -Mupdate -full64 -sverilog -kdb -lca -debug_acc+all -debug_region+cell +incdir+src +incdir+tb

.PHONY: all compilar simular regresion agregar_regresion barrido_pckgsz \
        barrido_drvrs grafico grafico_de corrida_especifica verificacion_completa limpiar

# --- Reglas basicas ---
all: compilar simular

compilar:
	vcs $(VCS_FLAGS) $(TB_FILE) -o $(OUT_BIN)

simular:
	./$(OUT_BIN) +ntb_random_seed=$(SEED)
	mkdir -p results
	cp reporte_paquetes.csv results/reporte_seed$(SEED).csv

# --- Regresion: 5 semillas con la configuracion por defecto (pckg_sz=16, drvrs=4) ---
regresion: compilar
	for s in 1 2 3 4 5; do $(MAKE) simular SEED=$$s; done

# Junta las 5 corridas de regresion en un solo CSV, para el histograma
# "caso general" del informe (misma configuracion en las 5, asi que sumar
# las muestras es estadisticamente valido).
agregar_regresion:
	head -1 results/reporte_seed1.csv > results/reporte_agregado.csv
	tail -n +2 -q results/reporte_seed1.csv results/reporte_seed2.csv \
	  results/reporte_seed3.csv results/reporte_seed4.csv \
	  results/reporte_seed5.csv >> results/reporte_agregado.csv

# --- Barrido de ancho de payload (bits/pckg_sz): 16, 32 y 64 ---
# (8 bits queda fuera a proposito
barrido_pckgsz: compilar
	mkdir -p results
	set -e; \
	for sz in 16 32 64; do \
	  rm -f reporte_paquetes.csv; \
	  vcs $(VCS_FLAGS) $(TB_FILE) \
	    -pvalue+testbench.PCKG_SZ=$$sz \
	    -pvalue+testbench.BITS=$$sz \
	    +define+PCKG_SZ=$$sz \
	    -o $(OUT_BIN)_sz$$sz \
	    -l compile_sz$$sz.log; \
	  ./$(OUT_BIN)_sz$$sz +ntb_random_seed=1; \
	  cp reporte_paquetes.csv results/reporte_pckgsz$$sz.csv; \
	done

# --- Barrido de numero de dispositivos (drvrs): 2, 4 y 8 ---
barrido_drvrs: compilar
	mkdir -p results
	set -e; \
	for dv in 2 4 8; do \
	  rm -f reporte_paquetes.csv; \
	  vcs $(VCS_FLAGS) $(TB_FILE) \
	    -pvalue+testbench.DRVRS=$$dv \
	    +define+DRVRS=$$dv \
	    -o $(OUT_BIN)_dv$$dv \
	    -l compile_dv$$dv.log; \
	  ./$(OUT_BIN)_dv$$dv +ntb_random_seed=1; \
	  cp reporte_paquetes.csv results/reporte_drvrs$$dv.csv; \
	done

# --- Corrida especifica: una sola combinacion de semilla, drvrs y pckg_sz ---


corrida_especifica:
	vcs $(VCS_FLAGS) $(TB_FILE) \
	  -pvalue+testbench.DRVRS=$(DRVRS) \
	  -pvalue+testbench.PCKG_SZ=$(PCKG_SZ) \
	  -pvalue+testbench.BITS=$(PCKG_SZ) \
	  +define+DRVRS=$(DRVRS) \
	  +define+PCKG_SZ=$(PCKG_SZ) \
	  -o $(OUT_BIN)_custom
	./$(OUT_BIN)_custom +ntb_random_seed=$(SEED)
	mkdir -p results
	cp reporte_paquetes.csv results/reporte_drvrs$(DRVRS)_sz$(PCKG_SZ)_seed$(SEED).csv

# --- Graficos (GNUplot) ---
# Uso simple: genera histograma_retardos.png a partir de reporte_paquetes.csv
grafico:
	gnuplot scripts/histograma_retardos.plt

# Uso parametrizado: make grafico_de ARCHIVO=results/reporte_pckgsz64.csv SALIDA=results/hist_pckgsz64.png
grafico_de:
	gnuplot -e "archivo='$(ARCHIVO)'; salida='$(SALIDA)'" scripts/histograma_retardos.plt

# --- Corrida completa: genera toda la evidencia usada en el informe ---
verificacion_completa:
	$(MAKE) regresion
	$(MAKE) agregar_regresion
	$(MAKE) barrido_pckgsz
	$(MAKE) barrido_drvrs
	$(MAKE) grafico_de ARCHIVO=results/reporte_agregado.csv  SALIDA=results/hist_pckgsz16.png
	$(MAKE) grafico_de ARCHIVO=results/reporte_pckgsz64.csv  SALIDA=results/hist_pckgsz64.png

limpiar:
	rm -rf csrc simv.daidir *.key salida* *.vpd DVEfiles *.fsdb vc_hdrs.h *.daidir *.vdb compile_*.log