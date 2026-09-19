// HomeRacker switch U bracket - shared geometry.
//
// A plain U-channel that slides along a HomeRacker support (used here as
// a horizontal rail) and locks in place with the support's own lock
// pins. The channel's cavity runs its full length, uninterrupted, so the
// rail passes freely through. No stop, lip, or corner catch - just the
// channel itself.
//
// See homeracker_switch_u_bracket.scad, which includes this file and
// calls render_bracket(). This file has no directly renderable geometry
// of its own (build_stl.py skips files starting with "_").
//
// HomeRacker (https://homeracker.org) supports are solid 15x15mm printed
// posts (their BASE_UNIT). Their official system locks accessories to the
// post using 4mm square "lock pins" through holes spaced every 15mm (see
// sample.stl in this directory, one of their real parts) - this bracket
// uses that same hole pattern through both side walls, but stays an open
// U-channel rather than sample.stl's closed 4-wall box (that box is a
// coupler meant to sleeve over two abutting support rods end-to-end;
// this piece only ever needs to grip one support from three sides).
//
// PRINTABILITY: printed standing on the end of the channel, rotated 90
// degrees about the X axis from how it's drawn/used here (see
// render_bracket() at the bottom), rather than lying on its side. In
// that orientation the rail direction (Y) becomes the print's vertical
// axis, so the U-channel's cross-section - constant along its whole
// length - just extrudes straight up with no bridge and no cavity roof
// to print. Zero overhangs anywhere in the part.

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

module u_bracket() {
    difference() {
        channel();
        if (lockpin_holes) {
            lockpin_holes_both_sides();
        }
    }
}

// Flips the part onto its best print orientation (see PRINTABILITY above)
// and scales the whole thing from the inch-based working units up to
// real-world millimeters for the exported STL.
module render_bracket() {
    scale([mm_per_inch, mm_per_inch, mm_per_inch])
        translate([0, 0, sleeve_len])
            rotate([-90, 0, 0])
                u_bracket();
}
