# blob-scale roadmap

blob-scale measures **how much material actually comes out** by weighing
dropped test blobs. This roadmap tracks where that goes next. The guiding
rule: **each milestone earns the next by producing real data** — we don't
chase new sensing until the current method is validated and feeding the
slicer.

## M0 — blob-drop, manual + auto *(current, v0 draft)*

Weigh a commanded test blob, compare to expected, derive:

- **flow multiplier** (material per commanded mm),
- **flow ceiling** (speed where the extruder slips),
- **consistency fingerprint** (batch-to-batch stiffness signal).

Manual-entry mode works with any kitchen scale today; auto mode reads a
$6 load-cell platform via HX711 → Klipper. See the [macros](../macros/)
and [build guide](build-guide.md).

**Status:** written and logic-audited; **not yet hardware-validated.** First
physical build in progress (July 2026).

## M1 — validate the blob-drop loop on real hardware *(the current gate)*

Nothing below M1 should start until this passes. M1 is done when a real
build has:

1. Calibrated the load cell with known coins/weights (klipper-setup §4).
2. Run `flow_scale_auto` end to end — blob drops, weight read, multiplier
   computed — with no transcription step.
3. Produced a flow multiplier + consistency number that a subsequent print
   visibly benefits from.

This is the same hardware-session gate as CeramicaSlicer's **Track D**
calibration — run them together. The blob-sweep flow check is Track D's
consistency measurement; validating one validates the other.

## M2 — force-sensing extension *(staged; do NOT start before M1)*

Weighing dropped blobs tells you the **mass** that came out. Measuring the
**force/pressure it takes to extrude** tells you the *dynamics* — and for a
paste/auger extruder, the dynamics are where the hard problems live (ooze,
stringing, lag, clogs). This milestone adds a toolhead force sensor as a
complementary mode to the blob drop.

### Prior art we build on (don't reinvent)

- **[bd_pressure](https://github.com/markniu/bd_pressure) — MIT, mature,
  fully open** (firmware + hardware + CAD). A strain gauge (BF350) on the
  toolhead PCB measures extruder force during a controlled motor sweep and
  fits a pressure-vs-acceleration curve to derive Pressure Advance. This is
  essentially the *automated, real-time* version of our blob-sweep. Because
  it is MIT, its firmware approach — ADC sampling, force-curve fitting, the
  calibration state machine — is directly reusable as a reference. **Primary
  reference for M2.**
- **[Amplify Hotend](https://github.com/EllaFoxo/Amplify-Hotend) —
  CERN-OHL-W, beta, sources unreleased (targeting late 2026).** A load-cell
  hotend for probing + filament-pressure monitoring, Voron/Kalico-native.
  Slicker, but bound to filament hotends and not yet copyable. **Watch, do
  not base on.**

Both are filament-oriented. The **nozzle-probing** half of each (Z offset
from bed contact) does **not** carry over — a clay nozzle can't tap a bed
like a hardened filament nozzle. We take only the *extrusion-force* half.

### Why this is worth more on clay than on filament

A paste/auger extruder has enormous "pressure advance": the paste column
compresses and lags, which is exactly why clay oozes, strings, and blobs at
starts/stops. A toolhead force sensor could plausibly:

- **Measure consistency directly** — force-to-extrude at constant flow is a
  moisture/stiffness proxy that needs *no* blob catch (the blob-sweep,
  automated and inline).
- **Calibrate clay start/stop/coast** — the paste-pressure-advance analog
  that no clay toolchain has really solved.
- **Detect clogs and air pockets** in the paste column mid-print.
- **Close the loop with [CeramicaSlicer](https://github.com/Diterex/CeramicaSlicer)** —
  the slicer *predicts* collapse/flow risk; a force sensor *confirms*
  extrusion is nominal. The predict→measure→correct loop is the genuinely
  novel combination here.

### Rough shape (subject to M1 findings)

1. **Bench first, no new toolhead.** Reuse the existing 1 kg load cell +
   HX711 + Klipper `load_cell` (native, already on this machine's Klipper)
   to log auger/ram force during a controlled extrusion sweep. Confirm there
   is a usable force signal that tracks flow rate and consistency *before*
   any custom hardware.
2. **Correlate** the logged force against M0's weighed flow multiplier /
   consistency fingerprint — does force-at-constant-flow predict the same
   batch differences the scale sees?
3. **Only if the signal is real:** design a dedicated force-sensing auger
   toolhead mount, using bd_pressure's PCB/firmware as the reference.

### M2 exit criterion

A force-only reading that reproduces the blob-drop consistency ranking
across ≥3 clay batches within a documented tolerance — i.e. the sensor can
replace the blob catch for consistency, and adds ooze/clog signal the scale
can't see.

## Not on the roadmap (and why)

- **Nozzle/bed probing** — clay nozzles don't Z-probe like filament nozzles.
- **A separate "force-sensing" repo** — this belongs *in* blob-scale as a
  second sensing mode, not as a fragmented parallel project. Same load cell,
  same Klipper integration, same consumer (the slicer).

---

*Sequencing note: M1 (and Track D) is the real unlock — it validates that
the whole measurement approach matches physical reality. M2 is deliberately
gated behind it so a shiny new sensor doesn't substitute for validating the
one we already have.*
