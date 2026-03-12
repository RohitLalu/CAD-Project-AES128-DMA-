# # set -o pipefail
# # export OPENRAM_REPO=/Users/hello.welcometothisdevice/tools/OpenRAM
# # export OPENRAM_HOME=${OPENRAM_REPO}/compiler
# # export PYTHONPATH=${OPENRAM_REPO}:${PYTHONPATH:-}
# # export OPENRAM_TECH=${OPENRAM_REPO}/technology/sky130
# # export PATH=${OPENRAM_REPO}/compiler:${PATH}

# # export PDK_ROOT=/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af
# # echo "[openram_setup] PDK_ROOT       = ${PDK_ROOT}"


# # echo "[openram_setup] OPENRAM_REPO = ${OPENRAM_REPO}"
# # echo "[openram_setup] OPENRAM_HOME = ${OPENRAM_HOME}"
# # echo "[openram_setup] OPENRAM_TECH = ${OPENRAM_TECH}"
# # echo "[openram_setup] PYTHONPATH    = ${PYTHONPATH}"

# # echo "[openram_setup] Checking Python dependencies..."
# # python3 "${OPENRAM_REPO}/py_check.py"


# # RUNDIR=~/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com
# # cd "${RUNDIR}"
# # echo "[openram_setup] Working directory: $(pwd)"

# # if [ -d sram_macro_output ]; then
# #     echo "[openram_setup] Removing old sram_macro_output/ ..."
# #     rm -rf sram_macro_output
# # fi


# # echo "[openram_setup] Starting OpenRAM compilation ..."
# # python3 "${OPENRAM_REPO}/sram_compiler.py" sram_creation.py
# # echo "[openram_setup] OpenRAM finished."


# # MACRO_DIR="${RUNDIR}/sram_macro_output"
# # MACRO_NAME="sram_1kbyte_1rw1r_32x256_8"

# # echo "[openram_setup] Checking generated files..."
# # for ext in lef lib v gds spice; do
# #     f="${MACRO_DIR}/${MACRO_NAME}.${ext}"
# #     if [ -f "${f}" ]; then
# #         echo "  [OK]  ${MACRO_NAME}.${ext}"
# #     else
# #         echo "  [!!]  MISSING: ${MACRO_NAME}.${ext}"
# #     fi
# # done

# # # Quick size sanity-check in the LEF
# # echo ""
# # echo "[openram_setup] LEF size check:"
# # grep -A 5 "SIZE" "${MACRO_DIR}/${MACRO_NAME}.lef" || true

# # # ── 6. Copy integration files to run_com ─────────────────────────────────────
# # echo ""
# # echo "[openram_setup] Copying integration files to ${RUNDIR} ..."
# # cp "${MACRO_DIR}/${MACRO_NAME}.lef"    "${RUNDIR}/"
# # cp "${MACRO_DIR}/${MACRO_NAME}.lib"    "${RUNDIR}/"
# # cp "${MACRO_DIR}/${MACRO_NAME}.v"      "${RUNDIR}/"

# # echo "[openram_setup] Done. Files in ${RUNDIR}:"
# # ls -lh "${RUNDIR}/${MACRO_NAME}".{lef,lib,v}

# # cd /Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com


# # # ── 7. Reminder ───────────────────────────────────────────────────────────────


# # # === Next steps ===
# # # 1. Confirm macro port names in the generated .v match the wrapper:
# # #      grep -E "input|output" sram_macro_output/sram_1kbyte_1rw1r_32x256_8.v | head -20

# # # 2. Add to your Yosys synthesis script (yosys.tcl):
# # #      read_verilog picosoc_mem_sram.v
# # #      # Do NOT synthesise the macro itself – treat it as a black-box:
# # #      read_verilog -lib sram_1kbyte_1rw1r_32x256_8.v

# # # 3. Add the LEF to your OpenROAD/tritonRoute flow (trial3.tcl / def2gds.sh):
# # #      read_lef sram_1kbyte_1rw1r_32x256_8.lef

# # # 4. Add timing constraints from the .lib to your SDC (aes_sdc.sdc).

# # # 5. In picosoc_aes.v, the macro is already selected via the `PICOSOC_MEM macro:
# # #      `define PICOSOC_MEM picosoc_mem   ← keep as-is; the wrapper reuses that name.


# set -o pipefail
# export OPENRAM_REPO=/Users/hello.welcometothisdevice/tools/OpenRAM
# export OPENRAM_HOME=${OPENRAM_REPO}/compiler
# export OPENRAM_TECH=${OPENRAM_REPO}/technology/sky130
# export PATH=${OPENRAM_REPO}/compiler:${PATH}

# # Use the framework Python 3.10 which has numpy.
# # The nix devshell python3 does NOT have numpy; system python3.10 does.
# PYTHON=/Library/Frameworks/Python.framework/Versions/3.10/bin/python3.10
# export PYTHONPATH=${OPENRAM_REPO}:${PYTHONPATH:-}

# export PDK_ROOT=/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af
# echo "[openram_setup] PDK_ROOT       = ${PDK_ROOT}"


# echo "[openram_setup] OPENRAM_REPO = ${OPENRAM_REPO}"
# echo "[openram_setup] OPENRAM_HOME = ${OPENRAM_HOME}"
# echo "[openram_setup] OPENRAM_TECH = ${OPENRAM_TECH}"
# echo "[openram_setup] PYTHONPATH    = ${PYTHONPATH}"

# echo "[openram_setup] Checking Python dependencies..."
# $PYTHON "${OPENRAM_REPO}/py_check.py"


# RUNDIR=~/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com
# cd "${RUNDIR}"
# echo "[openram_setup] Working directory: $(pwd)"

# if [ -d sram_macro_output ]; then
#     echo "[openram_setup] Removing old sram_macro_output/ ..."
#     rm -rf sram_macro_output
# fi


# echo "[openram_setup] Starting OpenRAM compilation ..."
# $PYTHON "${OPENRAM_REPO}/sram_compiler.py" sram_creation.py
# echo "[openram_setup] OpenRAM finished."


# MACRO_DIR="${RUNDIR}/sram_macro_output"
# MACRO_NAME="sram_1kbyte_1rw1r_32x256_8"

# echo "[openram_setup] Checking generated files..."
# for ext in lef lib v gds spice; do
#     f="${MACRO_DIR}/${MACRO_NAME}.${ext}"
#     if [ -f "${f}" ]; then
#         echo "  [OK]  ${MACRO_NAME}.${ext}"
#     else
#         echo "  [!!]  MISSING: ${MACRO_NAME}.${ext}"
#     fi
# done

# # Quick size sanity-check in the LEF
# echo ""
# echo "[openram_setup] LEF size check:"
# grep -A 5 "SIZE" "${MACRO_DIR}/${MACRO_NAME}.lef" || true

# # ── 6. Copy integration files to run_com ─────────────────────────────────────
# echo ""
# echo "[openram_setup] Copying integration files to ${RUNDIR} ..."
# cp "${MACRO_DIR}/${MACRO_NAME}.lef"    "${RUNDIR}/"
# cp "${MACRO_DIR}/${MACRO_NAME}.lib"    "${RUNDIR}/"
# cp "${MACRO_DIR}/${MACRO_NAME}.v"      "${RUNDIR}/"

# echo "[openram_setup] Done. Files in ${RUNDIR}:"
# ls -lh "${RUNDIR}/${MACRO_NAME}".{lef,lib,v}

# cd /Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com


# # ── 7. Reminder ───────────────────────────────────────────────────────────────


# # === Next steps ===
# # 1. Confirm macro port names in the generated .v match the wrapper:
# #      grep -E "input|output" sram_macro_output/sram_1kbyte_1rw1r_32x256_8.v | head -20

# # 2. Add to your Yosys synthesis script (yosys.tcl):
# #      read_verilog picosoc_mem_sram.v
# #      # Do NOT synthesise the macro itself – treat it as a black-box:
# #      read_verilog -lib sram_1kbyte_1rw1r_32x256_8.v

# # 3. Add the LEF to your OpenROAD/tritonRoute flow (trial3.tcl / def2gds.sh):
# #      read_lef sram_1kbyte_1rw1r_32x256_8.lef

# # 4. Add timing constraints from the .lib to your SDC (aes_sdc.sdc).

# # 5. In picosoc_aes.v, the macro is already selected via the `PICOSOC_MEM macro:
# #      `define PICOSOC_MEM picosoc_mem   ← keep as-is; the wrapper reuses that name.