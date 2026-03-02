---

# Physical Design Implementation Report: PicoSoC with AES-128

## 1. Executive Summary

The physical design implementation of the PicoSoC integrated with an AES-128 cryptographic core has been successfully completed. The design achieved **zero DRC violations** after detailed routing. By transitioning from a flat synthesis approach to a carefully guided hierarchical floorplan, we completely eliminated severe routing congestion, dropping initial detailed routing violations from over 243,000 to 0. The design is now timing-clean for hold violations and physically viable for signoff.

---

## 2. Key Implementation Metrics

### Floorplan & Placement (`fp.log` & `place.log`)

The floorplan was sized to accommodate the CPU, SRAM, and the AES engine, with a specific physical constraint to isolate the cryptography logic.

| Metric | Value |
| --- | --- |
| **Core Area (um)** | (30.360, 32.640) to Upper Bounds |
| **Standard Cell Rows** | 491 |
| **Tapcells Inserted** | 23,664 |
| **AES Instances Grouped** | 18,202 cells |
| **Placement Region (AES)** | 400x350um (South-West Corner) |

### Clock Tree Synthesis (`cts.log`)

The clock tree was synthesized with excellent balance, achieving a strict path depth of 5 across nearly 15,000 sinks.

| Metric | Value |
| --- | --- |
| **Clock Sinks** | 14,720 |
| **Clock Buffers Inserted** | 1,101 |
| **Path Depth (Min - Max)** | 5 - 5 |
| **Hold Buffers Inserted** | 16,552 |

### Detailed Routing (`route.log`)

TritonRoute successfully resolved all design rules across 46 optimization iterations.

| Metric | Value |
| --- | --- |
| **Total Wire Length** | ~2.80 meters (2,804,557 um) |
| **Total Vias** | 598,498 |
| **Final DRC Violations** | 0 |
| **Peak Memory Usage** | 5.42 GB |

---

## 3. Challenges Faced & Resolutions

This implementation required overcoming several critical architecture and tooling bottlenecks. Here is a breakdown of the major issues and how they were resolved.

### Issue 1: Severe Routing Congestion (243,000+ Violations)

* **The Problem:** The initial flat synthesis approach allowed the placement engine to scatter the 18,000+ AES logic cells randomly across the entire 1400x1400um die, deeply tangling them with the PicoRV32 CPU and memory buses. This caused an unroutable "rat's nest" of congestion.
* **The Resolution:** We engineered a "peaceful" hierarchical floorplan. First, the 32-bit `iomem` data buses were physically pinned to the South edge of the chip. Then, using OpenROAD's `odb::dbRegion` API, we created a 400x350um bounding box in the South-West corner and explicitly locked all 18,202 AES cells inside it. This segregated the heavy cryptographic data flow from the CPU, entirely eliminating the congestion.

### Issue 2: "Ghost" Netlists and Lost Hierarchy

* **The Problem:** The OpenROAD placer continuously threw `[WARNING] Could not find AES instance` errors. The Yosys synthesis script had flattened the netlist, destroying the `aes_inst` hierarchy, meaning the placement scripts couldn't grab the AES logic to put it in the bounding box.
* **The Resolution:** A new top-level wrapper (`picosoc_aes.v`) was created to cleanly instantiate the AES core. The Yosys synthesis script was updated to target this new module (`synth -top picosoc_aes`) without flattening, preserving the physical grouping for OpenROAD.

### Issue 3: Stale Database Synchronization

* **The Problem:** After fixing the RTL, the placement script continued to fail because the downstream tools (`pins.tcl`, `pdn.tcl`, `place.tcl`) were silently reading old `.odb` files from previous failed runs.
* **The Resolution:** A strict cache-clearing protocol was implemented. All stale `.odb` outputs were purged, and the `read_db` sequence at the top of every script was re-linked to ensure a clean data handoff from Floorplan -> Pins -> PDN -> Placement.

### Issue 4: Post-CTS Hold Violations

* **The Problem:** Immediately following Clock Tree Synthesis, the timing engine reported 13,752 endpoints with hold violations. This occurred because the dense placement created ultra-fast data paths that outpaced the newly introduced clock skew.
* **The Resolution:** The OpenROAD resizer was allowed to perform standard post-CTS timing recovery. It successfully evaluated the fast paths and inserted 16,552 low-power delay buffers, achieving hold-timing closure with only a micro-shift (1.0 um average) to standard cell legalization.

### Issue 5: Linux OOM (Out of Memory) Kills During Routing

* **The Problem:** During Iteration 0 of detailed routing, the 14-thread TritonRoute process was forcefully terminated by the operating system. The massive spatial search trees required to route 18,000 localized cells caused a sudden RAM spike that triggered the Linux OOM killer.
* **The Resolution:** We managed system memory overhead by throttling the multi-threading overhead down. Giving the router sufficient memory runway allowed it to survive the peak math phases (hitting ~5.4 GB) and successfully complete Iteration 46 with zero violations.

---
