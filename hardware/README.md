# Printed parts

One file: [`platform.scad`](platform.scad) (open with the free
[OpenSCAD](https://openscad.org/)) — it generates **both plates** of the
scale sandwich.

## Before you print

1. Open the `.scad` file. The first block of numbers describes your load
   cell — **check them against your cell's datasheet** (or measure with
   calipers): bar length/width, the two bolt-hole spacings and sizes, and
   how far the holes sit from each end. Cheap cells vary; the defaults
   fit the common TAL220-style 5 kg bar.
2. Press F6 (render), export STL, slice.

## Print settings

- Material: PETG or PLA — anything rigid.
- Strength: 5+ perimeters or ~50 % infill. The plates carry only grams,
  but stiffness = measurement quality; floppy plates make noisy readings.
- No supports needed. Layer height doesn't matter.

## Assembly reminder

The whole trick of a load-cell scale: **the bar only touches at its two
ends** — the base plate bolts to one end, the top plate to the other,
each on its spacer boss, and the bar floats in between. If any bolt or
surface touches the middle of the bar, readings jam. See the
[build guide](../docs/build-guide.md) step 2.

## STLs

Deliberately not committed yet — the first real build should validate the
parametric defaults before anyone downloads a fixed STL. Once a build is
photographed and confirmed, exported STLs for the common cells will land
here.
