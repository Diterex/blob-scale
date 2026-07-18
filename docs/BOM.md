# Bill of Materials

Everything together: **roughly $12–20**, mostly from Amazon/AliExpress/
your parts drawer. Nothing exotic.

| # | Part | Qty | ~Cost | Notes |
|---|------|-----|-------|-------|
| 1 | **Bar load cell, 1–5 kg** (TAL220 style, straight bar w/ 4 wires) | 1 | $4–8 | The sensor. **1 kg is the sweet spot** — your loads (container + clay across a sweep) stay well under 1 kg, and a lower-capacity cell gives *finer* resolution on 5–30 g blobs. 5 kg also works (more headroom, slightly coarser). Both use the same ~80 mm bar and the same platform. Often sold *with* the HX711 board as a kit — buy the kit. |
| 2 | **HX711 amplifier board** (the little green breakout) | 1 | $2–4 | Translates the load cell's tiny signal into numbers a microcontroller can read. Included in most load-cell kits. |
| 3 | **Raspberry Pi Pico** *(optional — see below)* | 1 | $4–6 | The clean way to connect: the Pico runs Klipper as a *second* controller over USB, so you don't touch your printer's main board. **Skip items 3–5 entirely if your printer's mainboard has 2 free GPIO pins** — modern boards (BTT Octopus, SKR3, etc.) usually do; see [klipper-setup.md](klipper-setup.md#do-you-even-need-the-pico) for the trade-offs and where to look for free pins. |
| 4 | **Jumper wires** (female-female Dupont, ~20 cm) | 4+ | $1–2 | HX711 → Pico (or → your mainboard if skipping the Pico). Pre-crimped = no soldering on that side. |
| 5 | **USB cable** (matching the Pico: micro-USB) | 1 | $0–3 | Pico → the computer running Klipper (usually your printer's Pi). Data cable, not charge-only. Not needed if wiring directly to your mainboard. |
| 6 | **M4 and M5 bolts** for the load cell | 2+2 | $1 | Check YOUR cell's datasheet: TAL220-style cells typically take M5 on one end, M4 on the other. Length = plate thickness + ~8 mm. |
| 7 | **3D-printed platform** (2 parts) | — | pennies | Print from [hardware/](../hardware/) in any rigid filament (PETG/PLA fine). |
| 8 | **Catch container** | 1 | free | Any light, rigid tub — yogurt container, deli cup. Must fit your blobs; wider is better. |

## Might also need

- **Soldering iron** — the load cell's 4 wires usually come bare and need
  tinning or crimping to connect to the HX711's screw-less pads. Some
  HX711 boards have through-holes you can solder to; some kits come
  pre-soldered (buy those if you want a solder-free build).
- **Calibration weights** — pocket change works: a US nickel is
  **exactly 5.000 g** by mint specification. Ten nickels = a 50 g
  calibration stack. (Non-US: check your mint's coin specs — most
  publish exact masses.)

## What NOT to buy

- A "kitchen scale to hack" — bare load cells are cheaper and cleaner
  than gutting a scale.
- A 20 kg+ load cell — more range = less resolution; blobs are 5–30 g.
- An "HX711 with display" module — you want the plain breakout that
  exposes DT/SCK pins.
