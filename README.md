# blob-scale

**A ~$15 scale your 3D printer reads by itself — for automatic clay and
paste flow calibration.**

> ⚠️ **Status: v0 draft.** First hardware build in progress (July 2026).
> Early fixes from testing are integrated here. Until the first build is
> photographed and fully validated, treat every step as "check this yourself."
> Found a problem? Open an issue!
>
> **Note**: This repo is a working branch for calibration macro development.
> Fixes discovered here sync upstream to [CeramicaSlicer](https://github.com/Diterex/CeramicaSlicer)
> once validated.

## What is this?

If you print with clay (or any paste), you know the problem: every batch
of material flows a little differently. Too wet, too dry, mixed on a
different day — the same print settings give different results.

The fix is simple in principle: **extrude a test blob, weigh it, and
compare to what the printer *thinks* it extruded.** From that you get:

- a **flow multiplier** — how much material actually comes out per
  commanded millimeter, so the printer can correct itself;
- a **flow ceiling** — the speed where the extruder starts slipping, so
  you know how fast you can safely print;
- a **consistency fingerprint** — a number that tells you "this batch is
  stiffer than last time" *before* you waste a 2-hour print.

You can do all that with a kitchen scale and a notepad (the included
macros support exactly that). **blob-scale removes the notepad**: a small
load-cell platform sits under the nozzle, a container on top catches the
test blobs, and the printer reads the weight itself — no typing, no
transcription mistakes, fully automatic calibration.

```
                nozzle
                  ║
                  ▼  (blob drops ~100 mm)
             ┌─────────┐
             │container│   ← any yogurt tub
            ┌┴─────────┴┐
            │ top plate │
            │ ═load═cell═ │ ← the $6 sensor doing the work
            │ base plate│
            └───────────┘
             HX711 board ──► Klipper MCU (e.g. a $5 Pi Pico)
```

## Everything is low-voltage

The whole project runs on 3.3–5 V DC. Nothing here touches mains power.
The only tool that gets hot is a soldering iron (and you can even avoid
that with pre-crimped jumper wires) — a great first electronics build,
with adult supervision for the iron.

## Get building

1. **[Bill of materials](docs/BOM.md)** — what to buy (~$12–20 total).
2. **[Build guide](docs/build-guide.md)** — step-by-step assembly,
   written so a young teen can follow it.
3. **[Klipper setup](docs/klipper-setup.md)** — wiring the sensor into
   your printer's brain, calibrating with pocket change, and detecting
   your scale's timeout (§ 4b). Auto-reading handles Klipper version
   differences automatically.
4. **[Macros](macros/)** — the flow-calibration routines (manual-entry
   mode works with ANY kitchen scale today; auto mode uses the blob-scale).
5. **[Printed parts](hardware/)** — parametric OpenSCAD platform; adjust
   two numbers to fit any standard bar load cell.
6. **[Roadmap](docs/roadmap.md)** — where this goes next: validating the
   blob-drop loop (M1), then a staged toolhead **force-sensing** mode (M2)
   for consistency, ooze/pressure-advance, and clog detection.

## Where this comes from

blob-scale grew out of the [CeramicaSlicer](https://github.com/Diterex/CeramicaSlicer)
project's research into measuring wet-clay consistency (six research
phases, from clay-printing practitioners to concrete printers to the
baking industry — short version: *measure flow, not moisture*). The
method is the clay adaptation of CNC Kitchen's extrusion benchmark,
run by the printer itself.

## License

[GNU AGPLv3](LICENSE) — free to use, study, modify, share, and sell. If
you distribute a modified version — **or run one as a network service** —
you must make your modified source available under this same license.
Improvements flow back to everyone; nobody gets to take this closed.
