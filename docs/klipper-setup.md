# Klipper Setup

> ⚠️ v0 draft. Klipper's load-cell support is official but evolving —
> **cross-check every section against the current docs at
> [klipper3d.org/Load_Cell.html](https://www.klipper3d.org/Load_Cell.html)**
> before trusting this page. Where this guide and the official docs
> disagree, the official docs win. Klipper version matters: load-cell
> support needs a recent release.

## 1. Register the Pico as a second MCU

In `printer.cfg`:

```ini
[mcu scale]
serial: /dev/serial/by-id/usb-Klipper_rp2040_XXXX-if00
# find yours with:  ls /dev/serial/by-id/
```

Restart Klipper; the console should greet both MCUs.

## 2. Add the load cell

```ini
[load_cell]
sensor_type: hx711
dout_pin: scale:gpio2
sclk_pin: scale:gpio3
# counts_per_gram gets filled in by calibration below
```

`FIRMWARE_RESTART`, then check it's alive:

```
LOAD_CELL_DIAGNOSTIC
```

You should see sample counts ticking. If not: wiring, pin names, or the
HX711's power.

## 3. Calibrate with pocket change

A US nickel is exactly **5.000 g** from the mint. Stack of 10 = 50 g.

```
LOAD_CELL_CALIBRATE
```

Follow the prompts (tare empty, then place the known weight and tell it
how much it is). `SAVE_CONFIG` writes the calibration into printer.cfg.

Sanity check afterward: tare, place one nickel, confirm ~5.0 g. Then
place your empty catch container and note its weight — if the container
ever reads different later, clay crumbs are hiding under it.

## 4. Hook up the flow macros

Copy [`macros/flow_check.cfg`](../macros/flow_check.cfg) next to your
printer.cfg and include it:

```ini
[include flow_check.cfg]
[save_variables]
filename: ~/printer_data/config/flow_variables.cfg
```

Edit the `_LDM_FLOW_CFG` block at the top for your machine (drop height,
where the scale sits, blob size). That file works **today with any
kitchen scale** — you type the readings in.

## 5. Go automatic (the whole point)

[`macros/flow_scale_auto.cfg`](../macros/flow_scale_auto.cfg) contains
the auto-reading layer: instead of typing `READING=12.3`, the macro asks
the load cell itself.

**Important honesty note:** the exact way a macro reads "current grams"
out of Klipper's load_cell object (the status field name) must be
verified against your Klipper version — the file marks the one line to
check. The delayed-gcode chaining pattern it uses (extrude → wait for
the blob to settle → read → decide → repeat) is standard Klipper, but
the whole file is a sketch until the first build validates it. The
manual-entry macros are the dependable path meanwhile.

## 6. One page cheat sheet

| Command | What it does |
|---|---|
| `LDM_FLOW_TUNE` | start an adaptive flow search (fastest) |
| `LDM_FLOW_PRIME` | purge into the container before measuring |
| `LDM_FLOW_NEXT READING=<g>` | feed it a reading; it does the rest |
| `LDM_FLOW_REDO READING=<g>` | last blob was bad (air pocket) — repeat it |
| `LDM_FLOW_START` / `LDM_FLOW_BLOB` | fixed sweep, one blob per tap |
| `LDM_FLOW_RESULT READINGS=...` | analyze a sweep |
| `LDM_FLOW_SET_BASELINE` | store a known-good load as reference |
| `_LDM_FLOW_APPLY` | apply the flow correction (put at end of PRINT_START) |
| `LDM_FLOW_STATUS` | show stored results |
