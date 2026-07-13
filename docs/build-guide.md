# Build Guide

Written to be followable by a young teen with adult supervision on the
soldering iron. Total build time: about an afternoon, most of it waiting
for the printed parts.

> ⚠️ v0 draft — nobody has built this exact design yet. If a step doesn't
> match reality, trust reality and open an issue so we can fix the guide.

**Before you start soldering:** Steps 1–3 below are the same no matter
what. Step 4 branches — read
[klipper-setup.md's "Do you even need the Pico?"](klipper-setup.md#do-you-even-need-the-pico)
first if your printer's mainboard is a modern/high-pin-count board (BTT
Octopus, SKR3, etc.) — you can likely skip the Pico entirely and wire
straight to two spare pins on your existing board.

## How a load cell works (30 seconds of theory)

A bar load cell is a metal bar that bends a *tiny* bit when you push on
it. Glued to the bar are strain gauges — resistors that change value when
stretched. The HX711 board measures that change and turns it into a
number. Bolt one end of the bar to a base, bolt a platform to the other
end, and you've built exactly what's inside every kitchen scale.

The one rule that matters: **the bar must float.** Only the ends get
bolted. The middle of the bar must never touch anything, or the reading
jams.

## Step 1 — Print the platform parts

Print `base_plate` and `top_plate` from [hardware/](../hardware/)
(see that folder's README for slicing notes — rigid material, high infill).
Before printing, check the two hole-spacing numbers against your load
cell's datasheet and adjust the `.scad` file if needed — cells vary.

## Step 2 — Bolt the sandwich together

1. Find the **arrow** on your load cell (usually on a sticker or etched).
   It shows the direction of load — it must point **down** on the
   platform end.
2. Bolt the **base plate** to one end of the cell (usually the M5 end).
   The printed spacer bumps face the cell, so the bar hovers above the
   plate.
3. Bolt the **top plate** to the other end (usually M4), spacer bumps
   down. Same rule: bar floats, only the end touches.
4. Push gently on the top plate. It should give springily by a hair's
   width and come right back. If it feels solid as a rock, something is
   touching that shouldn't be.

## Step 3 — Wire the load cell to the HX711

The cell has 4 wires. The *usual* colors (check your datasheet — cheap
cells sometimes swap them):

| Wire | Goes to HX711 pad |
|------|-------------------|
| Red | E+ |
| Black | E− |
| White | A− |
| Green | A+ |

Solder them to the HX711's pads (adult on the iron: it's quick — tin the
wire, tin the pad, touch together). Twist-and-tape is NOT reliable here;
the signals are microvolts.

## Step 4 — Give it a Klipper brain: pick ONE path

### Path A — Pico (default; works the same on any printer)

Four jumper wires, HX711 → Pico:

| HX711 pin | Pico pin |
|-----------|----------|
| VCC | 3V3 (pin 36) |
| GND | GND (pin 38) |
| DT (data) | GP2 (pin 4) |
| SCK (clock) | GP3 (pin 5) |

(Any two free GPIOs work — GP2/GP3 are just what the example config
uses. The HX711 is happy at 3.3 V.)

Then flash the Pico with Klipper firmware — full walkthrough in
[klipper-setup.md §0](klipper-setup.md) (it has to be *built*, not just
downloaded — that doc explains why and shows the exact commands). Once
it's flashed and plugged into the Pi, continue to
[klipper-setup.md §1](klipper-setup.md).

### Path B — straight to your printer's mainboard (skip the Pico)

If your mainboard has 2 free GPIO pins (common on modern boards — BTT
Octopus, SKR3, etc.), wire the HX711's four pins (VCC, GND, DT, SCK)
directly to your mainboard instead: VCC/GND to any spare 3.3V/5V + GND
pair, DT/SCK to two free GPIOs. Which pins are actually free depends on
your specific board and config — check your board's pinout diagram
against your `printer.cfg`. See
[klipper-setup.md's "Do you even need the Pico?"](klipper-setup.md#do-you-even-need-the-pico)
for the full trade-off and a tip on where free pins often hide. No
firmware flashing needed — your mainboard is already running Klipper.
Skip straight to [klipper-setup.md §2](klipper-setup.md).

## Step 6 — Place it and test

1. Put the assembled scale on the printer bed (or any surface under the
   nozzle's drop position — it doesn't need to be *on* the bed).
2. Sit the catch container on the top plate.
3. Do the calibration in [klipper-setup.md](klipper-setup.md) — that's
   where the nickels come in.
4. Poke the container. Watch the number move. Congratulations, your
   printer can weigh things.

## Troubleshooting

- **Reading stuck / barely moves** → something is touching the middle of
  the load-cell bar, or a bolt is bottoming out against the bar. The bar
  must float.
- **Reading drifts constantly** → normal for the first minutes as things
  warm up; the software re-tares. If it never settles: check solder
  joints, keep the cell away from drafts/heat lamps.
- **Reading is negative when you press down** → load cell is upside down
  relative to the arrow, or A+/A− are swapped. Either flip the cell or
  swap the two wires.
- **Number jumps wildly** → loose wire. Re-check every connection;
  microvolt signals hate loose crimps.
