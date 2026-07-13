// blob-scale platform - parametric plates for a standard bar load cell
// (DRAFT v0 - UNTESTED. Verify hole spacing against YOUR cell's datasheet
// before printing; cheap cells vary.)
//
// The design is the classic kitchen-scale sandwich:
//   [ top plate ]        <- container sits here; bolted to ONE end of the bar
//     = load cell =      <- floats: only its ends touch anything
//   [ base plate ]       <- sits on the bed; bolted to the OTHER end
//
// Spacer bosses on each plate lift the bar so it can flex freely.
// Print: PETG or PLA, 5+ perimeters or ~50% infill, no supports needed.
//
// Set these from your load cell's datasheet (defaults fit common
// TAL220-style 5kg bars, ~80 x 12.7 x 12.7 mm):

cell_length      = 80;    // bar length, mm
cell_width       = 12.7;  // bar width, mm
hole_spacing_a   = 15;    // distance between the two holes on end A (M5), mm
hole_dia_a       = 5.3;   // M5 clearance
hole_spacing_b   = 15;    // distance between the two holes on end B (M4), mm
hole_dia_b       = 4.3;   // M4 clearance
hole_end_offset  = 5;     // first hole center from the bar's end, mm

plate_size       = 110;   // square plates, mm (>= container footprint)
plate_thickness  = 6;
boss_height      = 6;     // spacer height: bar-to-plate air gap
boss_width       = 20;    // spacer footprint under the bar end

$fn = 32;

module plate(hole_spacing, hole_dia) {
    difference() {
        union() {
            // the plate
            cube([plate_size, plate_size, plate_thickness]);
            // spacer boss under one end of the bar, centered on the plate's X
            translate([(plate_size - boss_width) / 2,
                       (plate_size - cell_width) / 2,
                       plate_thickness])
                cube([boss_width, cell_width, boss_height]);
        }
        // two bolt holes through boss + plate
        for (i = [0, 1])
            translate([plate_size / 2 - hole_spacing / 2 + i * hole_spacing,
                       plate_size / 2,
                       -1])
                cylinder(h = plate_thickness + boss_height + 2, d = hole_dia);
    }
}

// base plate (M5 end by default)
plate(hole_spacing_a, hole_dia_a);

// top plate (M4 end), laid out beside it for printing
translate([plate_size + 10, 0, 0])
    plate(hole_spacing_b, hole_dia_b);
