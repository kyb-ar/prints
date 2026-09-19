// HomeRacker switch edge bracket - shared geometry.
//
// A U-channel that slides along a HomeRacker support (used here as a
// horizontal rail) and locks in place with the support's own lock pins.
// The channel's cavity runs its full length, uninterrupted, so the rail
// passes freely through. A single straight stop hangs off the bottom of
// the U - off the outer face of the floor, the flat side with no pin
// holes - flush with one of the channel's two side walls, running the
// entire length of the part. Unlike
// _homeracker_switch_corner_bracket_lib.scad's L shape, there is no
// second arm bending sideways - this stop only blocks movement off the
// rail (sideways, in X), not movement along the rail (in Y). It's used to
// hold a motherboard's edge in over the support rails when the board is
// just barely too narrow to rest on them on its own.
//
// Since the stop side's wall now runs edge-to-edge with the stop, it no
// longer carries lock-pin holes - only the other side wall does (see
// lockpin_holes_hole_side()).
//
// The stop side (wall + stop) can be made to run past the lock-pin grip
// zone via extra_len below, so the edge can extend further along the
// rail than the pins need to reach, without moving the pin holes. The
// grip zone (floor, cavity, hole-side wall) always stays at sleeve_len.
//
// The stop only sits against one side wall, so it's handed - flip the
// part end-for-end, or mirror it in X, to move it to the other side.
//
// See homeracker_switch_edge_bracket.scad, which includes this file and
// calls render_bracket(). This file has no directly renderable geometry
// of its own (build_stl.py skips files starting with "_").
//
// HomeRacker (https://homeracker.org) supports are solid 15x15mm printed
// posts (their BASE_UNIT). Their official system locks accessories to the
// post using 4mm square "lock pins" through holes spaced every 15mm (see
// sample.stl in this directory, one of their real parts) - this bracket
// uses that same hole pattern through a side wall, but stays an open
// U-channel rather than sample.stl's closed 4-wall box (that box is a
// coupler meant to sleeve over two abutting support rods end-to-end; this
// piece only ever needs to grip one support from three sides).
//
// PRINTABILITY: printed standing on the end of the channel, rotated 90
// degrees about the X axis from how it's drawn/used here (see
// render_bracket() at the bottom), rather than lying on its side. In
// that orientation the rail direction (Y) becomes the print's vertical
// axis, so the U-channel's cross-section - constant along its whole
// length - just extrudes straight up with no bridge and no cavity roof
// to print. The stop lands at the base, printed first, so it's resting
// directly on the bed rather than needing anything below it. Zero
// overhangs anywhere in the part.

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
sleeve_len = 2 * base_unit; // how much of the rail's length the channel grips
                    // (floor, cavity, hole-side wall, lock-pin holes) -
                    // keep this a multiple of base_unit so the lock-pin
                    // holes below land where the rail's own holes do

// Extra length appended to the stop side only (its wall + the stop below
// it), past the end of the grip zone above - use this to make the edge
// that blocks the motherboard reach further along the rail without
// moving the grip zone or its lock-pin holes. 0 = stop side ends flush
// with the grip zone.
extra_len = 0 / mm_per_inch;

// Lock-pin holes, matching the real HomeRacker part in sample.stl - one
// per base_unit of length, centered in each unit, same 4mm square size
// they use, through the hole-side wall only (the stop side has no holes -
// see lockpin_holes_hole_side()). Push one of their lock pins (or a snug
// scrap of 4mm square rod) through to keep the bracket from sliding once
// you've picked a position.
lockpin_holes = true;
lockpin_side  = 4 / mm_per_inch; // hole side length (4mm, matches their
                    // LOCKPIN_HOLE_SIDE_LENGTH)

// Stop hanging off the bottom of the channel (the floor, the flat face
// with no pin holes) - a single straight wall, flush with the stop-side
// wall, running the part's entire length (sleeve_len + extra_len). Flip
// the part end-for-end, or mirror it in X, to move the stop to wherever
// it needs to be, or to the other side wall.
stop_thick   = 5 / mm_per_inch;   // (5mm) thickness of the stop along X
stop_height  = 5 / mm_per_inch;   // how far the stop drops below the
                     // floor (5mm) - tune this to what the stop needs to
                     // catch

eps = 0.02 / mm_per_inch; // small overlap/overshoot so booleans stay watertight
$fn = 32;

// ---- Derived dimensions ----
Wc = post_size + 2 * wall + tol;             // outer width of the channel
channel_height = wall + post_size + tol;     // height of the channel's side rails
total_len = sleeve_len + extra_len;          // full length of the part -
                    // the stop-side wall and the stop both run this whole
                    // length; the floor, cavity, and hole-side wall stay
                    // at sleeve_len

// ---- Modules ----

// The U-channel: floor across the grip zone, hole-side rail across the
// grip zone, stop-side rail across the whole part (see total_len), open
// top. The rail threads through freely along its whole length (open at
// both ends in Y), so it can continue past the bracket in either
// direction.
module channel() {
    difference() {
        union() {
            // floor - grip zone only
            translate([-Wc / 2, 0, 0]) cube([Wc, sleeve_len, wall]);
            // hole-side rail - grip zone only
            translate([Wc / 2 - wall, 0, 0]) cube([wall, sleeve_len, channel_height]);
            // stop-side rail - runs the part's full length
            translate([-Wc / 2, 0, 0]) cube([wall, total_len, channel_height]);
        }
        // rail cavity, open at the top - grip zone only
        translate([-(post_size + tol) / 2, -eps, wall])
            cube([post_size + tol, sleeve_len + 2 * eps, channel_height + eps]);
    }
}

// One square lock-pin hole through the hole-side wall, centered on the
// channel's height, at unit index i (0-based) along the grip zone.
module lockpin_hole(x0) {
    translate([x0, -eps, wall + (post_size + tol) / 2 - lockpin_side / 2])
        cube([wall + 2 * eps, lockpin_side, lockpin_side]);
}

module lockpin_holes_hole_side() {
    num_units = floor(sleeve_len / base_unit);
    for (i = [0 : num_units - 1]) {
        y0 = i * base_unit + base_unit / 2 - lockpin_side / 2;
        translate([0, y0, 0]) lockpin_hole(Wc / 2 - wall - eps);
    }
}

// The stop: a single straight wall hanging off the bottom of the channel
// (the floor's outer face, no pin holes), flush with the stop-side wall,
// running the part's entire length (sleeve_len + extra_len). The
// channel's cavity itself is left untouched - grip zone only, nothing
// plugged - so the rail still passes all the way through underneath.
module stop_wall() {
    translate([-Wc / 2, 0, -stop_height])
        cube([stop_thick, total_len, stop_height]);
}

module switch_edge_bracket() {
    difference() {
        union() {
            channel();
            stop_wall();
        }
        if (lockpin_holes) {
            lockpin_holes_hole_side();
        }
    }
}

// Flips the part onto its best print orientation (see PRINTABILITY above)
// and scales the whole thing from the inch-based working units up to
// real-world millimeters for the exported STL. mirror_piece=true mirrors
// the stop to the other side wall (in X).
module render_bracket(mirror_piece = false) {
    scale([mm_per_inch, mm_per_inch, mm_per_inch])
        translate([0, 0, total_len])
            rotate([-90, 0, 0])
                if (mirror_piece)
                    mirror([1, 0, 0]) switch_edge_bracket();
                else
                    switch_edge_bracket();
}
