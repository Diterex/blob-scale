# Klipper Setup

> ⚠️ v0 draft. Klipper's load-cell support is official but evolving —
> **cross-check every section against the current docs at
> [klipper3d.org/Load_Cell.html](https://www.klipper3d.org/Load_Cell.html)**
> before trusting this page. Where this guide and the official docs
> disagree, the official docs win. Klipper version matters: load-cell
> support needs a recent release.

## Do you even need the Pico?

**No — it's the default because it works the same way for everyone,
regardless of what printer mainboard they have. It is not required.**

Klipper's HX711 support just needs two free GPIO pins on *any* board
already running Klipper firmware — including your printer's own
mainboard. If you'd rather not add a second controller:

- Skip §0–1 below entirely.
- In `[load_cell]` (§2), use your main `mcu` instead of `scale:` — e.g.
  `dout_pin: PC4` instead of `dout_pin: scale:gpio2` (real pin names
  depend on your board and what's already used).
- Everything from §2 onward (calibration, macros) is identical either
  way.

**Trade-offs, honestly:**

| | Pico (default) | Direct to mainboard |
|---|---|---|
| Parts/cost | +1 board, +1 USB cable | none extra |
| Firmware upkeep | rebuild+reflash on every Klipper update | none (already handled for your printer) |
| Finding free pins | never an issue (Pico is dedicated) | you have to find & confirm 2 free GPIOs |
| Portability | unplug, use on any printer | wired into this one printer |
| Best for | "just make it work," unknown/low-pin boards | modern boards with GPIO to spare, builders comfortable editing printer.cfg |

**Powerful modern boards** (BTT Octopus Pro, SKR3, etc. — plenty of spare
GPIO, fast MCU, no real contention risk from a slow periodic HX711 read)
are good direct-wire candidates. One place to look for free pins: if you
run KlipperScreen (or Mainsail/Fluidd only) rather than a physical
onboard mini LCD, the **EXP1/EXP2 display header** many boards have is
often entirely unused and breaks out several individually addressable
GPIOs on a convenient pin header — worth checking against your board's
pinout diagram and your own `printer.cfg` before committing to specific
pins.

## 0. Flash the Pico — yes, it needs firmware

(Skip this whole section if you're wiring directly to your mainboard —
its firmware is already Klipper, nothing to flash.)

A brand-new Pico is a blank chip. To become a Klipper "second brain" it
must run **Klipper's microcontroller firmware** — and there's no
download-a-file shortcut: **you build the firmware yourself on the Pi**,
from the same Klipper installation your printer already runs. (That
matters: Klipper insists the firmware on every MCU matches the version
of the Klipper software on the Pi. Building it on the Pi guarantees the
match; a random UF2 from the internet won't.)

On the Pi (SSH in, or use the terminal in Mainsail/Fluidd):

```bash
cd ~/klipper
make menuconfig
```

A blue menu appears. Set exactly one thing:

- **Micro-controller Architecture** → `Raspberry Pi RP2040`

Leave everything else at defaults. Press `Q`, save, then:

```bash
make
```

A couple of minutes later the firmware exists at
`~/klipper/out/klipper.uf2`.

Now put the Pico in bootloader mode: **hold down the white BOOTSEL
button** on the Pico while plugging its USB cable into the Pi, then let
go. The Pico shows up as a little USB drive called `RPI-RP2`. Copy the
firmware onto it:

```bash
sudo mount /dev/sda1 /mnt && sudo cp ~/klipper/out/klipper.uf2 /mnt && sudo umount /mnt
```

(If `/dev/sda1` doesn't exist, run `lsblk` right after plugging in to
see what name the Pico got.)

The Pico reboots itself instantly, the drive disappears, and it is now —
permanently, until you ever reflash it — a Klipper MCU. No button
pressing needed on normal power-up.

**When you update Klipper later**, the Pico's firmware must be rebuilt
and reflashed the same way, or Klipper will refuse to start with a
version-mismatch error. This bites everyone once; now it won't bite you.

## 1. Register the Pico as a second MCU

(Also skip this if wiring directly to your mainboard — there's no
second MCU to register, just use your existing `mcu` name in §2.)

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
