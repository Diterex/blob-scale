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

### Verified per-board quick reference (direct-wire)

Pin assignments below were read from each board's **official BigTreeTech
pinout diagram** (`Hardware/` folder of the board's GitHub repo) — but
boards get revised, so treat this as a strong starting point and glance at
YOUR board's diagram before soldering. Signals are 3.3 V logic on all
three; the differences are where 3.3 V *power* is available.

| | HX711 **DOUT** | HX711 **SCK** | HX711 **GND** | HX711 **VCC (3.3 V!)** |
|---|---|---|---|---|
| **BTT Octopus / Octopus Pro** (STM32) | `PE9` (EXP1 pin 3) | `PE10` (EXP1 pin 4) | EXP1 pin 9 | **Accelerometer/ADXL SPI header 3.3 V** (⚠ meter-verify: some early boards have 3.3V/GND silkscreen swapped) |
| **BTT SKR Pico v1.0** (RP2040) | `gpio22` (PROBE pin) | `gpio29` (SERVOS signal pin — ignore that header's 5 V) | any endstop/servo GND | ⚠ **No 3.3 V on any connector** — every header carries 5 V or 12/24 V. Take VCC from the **Raspberry Pi's 3V3** (40-pin header, physical pin 1 or 17; the Pi is your Klipper host and shares ground via its wiring to the board). Solder-comfortable? The SWD pads carry 3.3 V. **Never 5 V — the RP2040 is not 5 V-tolerant.** |
| **BTT Manta M5P** (STM32G0B1) | `PC13` (Probe header signal) | `PC15` (same Probe header, servo/control pin) | Probe header GND | **SPI/ADXL header 3.3 V** (top-left 2×4 header: it has both 3.3 V and GND; don't touch its SPI signal pins) |

Alternates if the primary pins are taken on your machine: SKR Pico —
`gpio16` (E0-STOP) for DOUT, `gpio24` (RGB) for SCK; Manta M5P — EXP1
`PD5`/`PD4` (display header, free when you have no onboard LCD), or the
MIN4 endstop `PC2`. Endstop/probe/RGB headers on BOTH boards put **5 V**
on their power pin — use only their *signal* and *GND* pins, and power
the HX711 from the 3.3 V source in the table.

Matching `[load_cell]` pin lines:

```ini
# Octopus / Octopus Pro          # SKR Pico v1.0            # Manta M5P
dout_pin: PE9                    dout_pin: gpio22           dout_pin: PC13
sclk_pin: PE10                   sclk_pin: gpio29           sclk_pin: PC15
```

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

Wiring **direct to a printer mainboard** instead of a Pico? Drop the
`scale:` prefix and use your board's own pin names, e.g. `dout_pin: PE9`
/ `sclk_pin: PE10`. **Power the HX711 from 3.3V, not 5V**, when wiring
straight to a 3.3V-logic MCU (STM32, RP2040) — at 5V VCC the HX711's
DOUT/SCK would drive 5V onto GPIO that expects 3.3V. Take 3.3V from a
3.3V-carrying header and **verify the pin with a multimeter** (some
boards, e.g. early BTT Octopus, have swapped 3.3V/GND silkscreen labels).

`FIRMWARE_RESTART`, then check it's alive:

```
LOAD_CELL_DIAGNOSTIC
```

You should see sample counts ticking. If not: wiring, pin names, or the
HX711's power.

## 3. Calibrate with pocket change

A US nickel is exactly **5.000 g** from the mint. Stack of 10 = 50 g.

`LOAD_CELL_CALIBRATE` starts an **interactive tool**. The sequence:

```
LOAD_CELL_CALIBRATE          ; starts the tool
TARE                         ; with NOTHING on the plate — sets zero
                             ; (now place the known weight, e.g. 10 nickels = 50 g)
CALIBRATE GRAMS=50           ; tell it the exact grams you placed
ACCEPT                       ; saves counts_per_gram (ABORT bails without saving)
```

`ACCEPT` writes `counts_per_gram` into printer.cfg (via SAVE_CONFIG) —
don't hand-edit it.

Sanity check afterward: `LOAD_CELL_TARE`, place one nickel, `LOAD_CELL_READ`,
confirm ~5.0 g. Then place your empty catch container and note its weight
— if the container ever reads different later, clay crumbs are hiding
under it.

> Note: the `force_g` status field only reads once the cell is **calibrated
> AND tared** (before that it's undefined) — that's the normal state during
> a flow run, which always tares first, so the auto layer reads it fine.

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

## 4b. Detect your scale's timeout (one-time diagnostic)

Different kitchen scales have different auto-power-off timers (typically
5–30 seconds). Before running a flow calibration, detect yours:

```
LDM_FLOW_DETECT_SCALE_TIMEOUT
```

The macro extrudes a dummy blob and monitors when your scale stops
responding. It stores the result and warns you if your calibration
settings risk timing out (scale powers off before the blob lands).

Record the detected timeout. If you get "scale reads 0g" errors during
calibration, re-run this diagnostic and use the suggested blob_e or
rate_start values it recommends.

## 5. Go automatic (the whole point)

[`macros/flow_scale_auto.cfg`](../macros/flow_scale_auto.cfg) contains
the auto-reading layer: instead of typing `READING=12.3`, the macro asks
the load cell itself.

Auto-reading mode **automatically detects which Klipper version's
load_cell field name your system uses** on first run — no manual edits
needed. The delayed-gcode chaining pattern it uses (extrude → wait for
the blob to settle → read → decide → repeat) is standard Klipper.

### Troubleshooting auto-reading

If the macro reads `0g` repeatedly:

1. Check that your load cell is connected and calibrated (run
   `LOAD_CELL_DIAGNOSTIC`; you should see non-zero values when you place
   weight on it).
2. If the scale reads correctly in DIAGNOSTIC but auto-reading still shows
   0g, the field-name detection may have failed. File a GitHub issue with:
   - Your Klipper version (run `FIRMWARE_RESTART` and check the console)
   - The output of `LOAD_CELL_DIAGNOSTIC` (to see which fields are
     available)

Meanwhile, the manual-entry macros (`LDM_FLOW_TUNE` → `LDM_FLOW_NEXT
READING=<grams>`) work reliably on any Klipper version.

## 5b. Optional: reservoir refill tracking

`flow_check.cfg`'s comments mention a few macros this repo doesn't
include — `SYRINGE_CHANGE`, `LDM_RESERVOIR_STATUS`,
`LDM_RESERVOIR_CHECKPOINT`. Those live in a separate, optional companion
file, `klipper_syringe_change.cfg`, from the CeramicaSlicer project (the
LDM Vase Plus slicer fork this hardware was built for) — it tracks how
much clay has been dispensed since the last reservoir refill and prompts
you to keep-or-rerun the flow calibration on a new load. Not needed for
flow_check.cfg itself to work; grab it from that project's `corpus/`
directory if you want the refill-tracking layer too.

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
