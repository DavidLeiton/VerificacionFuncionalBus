# --- Variables ---
# Apuntar a la carpeta 'tb' para encontrar testbench.sv
TB_FILE = tb/testbench.sv
OUT_BIN = salida

# Agregar +incdir+ para incluir las carpetas con el código fuente y el banco de pruebas
VCS_FLAGS = -Mupdate -full64 -sverilog -kdb -lca -debug_acc+all -debug_region+cell +incdir+src +incdir+tb

# --- Reglas ---
all: compilar simular

compilar:
	vcs $(VCS_FLAGS) $(TB_FILE) -o $(OUT_BIN)

simular:
	./$(OUT_BIN)

limpiar:
	rm -rf csrc simv.daidir *.key $(OUT_BIN) *.vpd DVEfiles *.fsdb vc_hdrs.h
