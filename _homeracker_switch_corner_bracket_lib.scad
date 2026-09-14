// HomeRacker switch corner bracket - shared geometry.
//
// A U-channel that slides along a HomeRacker support (used here as a
// horizontal rail) and locks in place with the support's own lock pins.
// The channel's cavity runs its full length, uninterrupted, so the rail
// passes freely through. An L-shaped bracket hangs off the bottom of the
// U - off the outer face of the floor, the flat side with no pin holes,
// at one end, dropping down past the floor (negative Z, in this same
// orientation). The L shape is in plan view (look straight down the Z
// axis to see it): one arm runs back along the rail, the other bends 90
// degrees and runs sideways, so the corner of the L catches the corner
// of the switch.
//
// The L only catches one corner, so it's handed: this file's default
// (unmirrored) orientation catches one side, and mirroring it (see
// homeracker_switch_corner_bracket_mirrored.scad) catches the other.
// Print FOUR total: 2 unmirrored + 2 mirrored, two on one rail catching
// one edge of the switch, two on a second, parallel rail catching the
// other edge.
//
// See homeracker_switch_corner_bracket.scad /
// _mirrored.scad, which include this file and call render_bracket().
// This file has no directly renderable geometry of its own (build_stl.py
// skips files starting with "_").
//
// HomeRacker (https://homeracker.org) supports are solid 15x15mm printed
// posts (their BASE_UNIT). Their official system locks accessories to the
// post using 4mm square "lock pins" through holes spaced every 15mm (see
// sample.stl in this directory, one of their real parts) - this bracket
// uses that same hole pattern through its two side walls, but stays an
// open U-channel rather than sample.stl's closed 4-wall box (that box is
// a coupler meant to sleeve over two abutting support rods end-to-end;
// this piece only ever needs to grip one support from three sides).
//
// PRINTABILITY: printed standing on the end of the channel, rotated 90
// degrees about the X axis from how it's drawn/used here (see
// render_bracket() at the bottom), rather than lying on its side. In
// that orientation the rail direction (Y) becomes the print's vertical
// axis, so the U-channel's cross-section - constant along its whole
// length - just extrudes straight up with no bridge and no cavity roof
// to print. The L-bracket lands at the base, printed first, so it's
// resting directly on the bed rather than needing anything below it.
// Zero overhangs anywhere in the part.

mm_per_inch = 25.4;

// ---- Parameters (inches) ----
// Values are HomeRacker's real millimeter spec (see comments) converted
// to inches, so the geometry below can stay in one consistent unit and
// scale to the correct real-world size at the very end (render_bracket).

// Post / rail fit - matches the real HomeRacker support (15x15mm).
base_unit = 15 / mm_per_inch;    // HomeRacker's base unit (15mm) - support
                    // cross-section and lock-pin hole spacing both derive
                    // from this
post_size = base_unit; // support cross-section (both axes)
wall      = 2.5 / mm_per_inch;   // channel wall thickness (2.5mm)
tol       = 0.3 / mm_per_inch;   // clearance so the channel slides freely
                    // along the rail (0.3mm) - loosen/tighten this if it
                    // binds or wobbles
sleeve_len = 2 * base_unit; // how much of the rail's length the channel grips -
                    // keep this a multiple of base_unit so the lock-pin
                    // holes below land where the rail's own holes do

// Lock-pin holes through both side walls, matching the real HomeRacker
// part in sample.stl - one per base_unit of length, centered in each
// unit, same 4mm square size they use. Push one of their lock pins (or
// a snug scrap of 4mm square rod) through to keep the bracket from
// sliding once you've picked a position.
lockpin_holes = true;
lockpin_side  = 4 / mm_per_inch; // hole side length (4mm, matches their
                    // LOCKPIN_HOLE_SIDE_LENGTH)

// Stop bracket hanging off the bottom of the channel (the floor, the flat
// face with no pin holes), at one end - an L shape in plan view (looking
// down the Z axis): one arm runs back along the rail's length, the other
// bends 90 degrees and runs sideways, so the corner of the L is what
// actually catches the switch's corner. Flip the part end-for-end, or
// mirror it in X, to move the L to wherever it needs to be.
stop_thick   = 5 / mm_per_inch;   // thickness of each arm of the L (5mm)
stop_height  = 10 / mm_per_inch;  // how far the L drops below the floor
                     // (10mm) - tune this to your switch's edge
leg_length_y = 20 / mm_per_inch; // how far the arm along Y (the rail
                     // direction) extends (20mm) - keep this <= sleeve_len
leg_length_x = 15 / mm_per_inch; // how far the arm along X (sideways)
                     // extends (15mm) - keep this <= Wc so the L stays
                     // within the channel's own footprint, nothing
                     // hanging off it

eps = 0.02 / mm_per_inch; // small overlap/overshoot so booleans stay watertight
$fn = 32;

// ---- Derived dimensions ----
Wc = post_size + 2 * wall + tol;             // outer width of the channel
channel_height = wall + post_size + tol;     // height of the channel's side rails

// ---- Modules ----

// The U-channel: floor across the full width, two side rails, open top.
// The rail threads through freely along its whole length (open at both
// ends in Y), so it can continue past the bracket in either direction.
module channel() {
    difference() {
        union() {
            // floor
            translate([-Wc / 2, 0, 0]) cube([Wc, sleeve_len, wall]);
            // side rails
            translate([-Wc / 2, 0, 0]) cube([wall, sleeve_len, channel_height]);
            translate([Wc / 2 - wall, 0, 0]) cube([wall, sleeve_len, channel_height]);
        }
        // rail cavity, open at the top
        translate([-(post_size + tol) / 2, -eps, wall])
            cube([post_size + tol, sleeve_len + 2 * eps, channel_height + eps]);
    }
}

// One square lock-pin hole through a side wall, centered on the channel's
// height, at unit index i (0-based) along the sleeve's length.
module lockpin_hole(x0) {
    translate([x0, -eps, wall + (post_size + tol) / 2 - lockpin_side / 2])
        cube([wall + 2 * eps, lockpin_side, lockpin_side]);
}

module lockpin_holes_both_sides() {
    num_units = floor(sleeve_len / base_unit);
    for (i = [0 : num_units - 1]) {
        y0 = i * base_unit + base_unit / 2 - lockpin_side / 2;
        translate([0, y0, 0]) {
            lockpin_hole(-Wc / 2 - eps);
            lockpin_hole(Wc / 2 - wall - eps);
        }
    }
}

// The stop: an L-shaped bracket hanging off the bottom of the channel
// (the floor's outer face, no pin holes), both arms at the same depth
// below the floor - the L shape is in the X-Y footprint (visible looking
// down the Z axis), not in cross-section. The channel's cavity itself is
// left untouched - full length, nothing plugged - so the rail still
// passes all the way through underneath.
module stop_wall() {
    union() {
        // arm along Y: runs back along the rail's length
        translate([-Wc / 2, sleeve_len - leg_length_y, -stop_height])
            cube([stop_thick, leg_length_y, stop_height]);
        // arm along X: bends 90 degrees, runs sideways, at the same end
        translate([-Wc / 2, sleeve_len - stop_thick, -stop_height])
            cube([leg_length_x, stop_thick, stop_height]);
    }
}

module switch_corner_bracket() {
    difference() {
        union() {
            channel();
            stop_wall();
        }
        if (lockpin_holes) {
            lockpin_holes_both_sides();
        }
    }
}

// Flips the part onto its best print orientation (see PRINTABILITY above)
// and scales the whole thing from the inch-based working units up to
// real-world millimeters for the exported STL. mirror_piece=true mirrors
// the L-bracket to the other side (in X), for the opposite corner.
module render_bracket(mirror_piece = false) {
    scale([mm_per_inch, mm_per_inch, mm_per_inch])
        translate([0, 0, sleeve_len])
            rotate([-90, 0, 0])
                if (mirror_piece)
                    mirror([1, 0, 0]) switch_corner_bracket();
                else
                    switch_corner_bracket();
}
