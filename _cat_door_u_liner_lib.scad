// Cat door U-shaped liner - shared geometry.
// Fits into a rectangular box cut into a door, lining the bottom and
// two sides with a thin wall so a smaller insert seats snugly in the gap.
//
// Flanges at the front and/or back cap the ends, sitting flush against
// the door's face and overlapping the cut edge to hide it.
//
// PRINTABILITY: a single piece with a 90-degree bend (leg+rail) can't be
// oriented to avoid supports, because the leg's flange overhang needs
// rotation about one axis while the rail's needs rotation about the other.
// So the part is split into 3 straight pieces - left leg, right leg, and
// the full-width bottom rail - each printable with zero overhangs, joined
// with a peg-and-hole press fit at the two corners. The rail (10.5in =
// 266.7mm) is also individually longer than a 256mm bed, so it's printed
// at a 45-degree diagonal, which brings its footprint to ~219x219mm.
//
// See cat_door_u_liner_leg_left.scad / _leg_right.scad / _rail.scad, which
// include this file and call the render_*() entry points. This file has no
// directly renderable geometry of its own (build_stl.py skips files
// starting with "_").

// ---- Parameters (inches) ----
door_depth      = 1.5;   // door thickness (liner spans this, Z)
box_width       = 10.5;  // width of the cutout in the door (X)
box_height      = 7.75;  // height of the cutout in the door (Y)
wall            = 0.25;  // thickness of the liner material (the gap it fills)

flange_front    = true;  // add a flange on the front face
flange_back     = true;  // add a flange on the back face
flange_overlap  = 0.25;  // how far the flange extends past the cut edge
flange_thick    = 0.1;   // flange thickness (Z), kept small/low-profile

screw_holes     = true;  // add mounting screw holes through the two legs
screw_hole_dia  = 0.19;  // clearance diameter for the screw shank (~#8 screw)
screw_hole_inset = 0.5;  // distance in from the tip (open end) of each leg

countersink       = true; // recess for a flat/flush screw head, on the inner face
countersink_dia   = 0.36; // head diameter (~#8 flat-head screw)
countersink_depth = 0.1;  // how deep the taper cuts into the leg (< wall)

// Corner joint: a round peg on each leg presses into a hole in the rail.
// The peg runs along the leg's own length, so it's a horizontal, in-plane
// extension of the print (no added overhang) rather than a feature that
// has to stick straight up off the bed. hole is slightly smaller than the
// peg for a firm friction/snap fit - sand the peg or reprint with
// adjusted diameters if it's too tight/loose.
joint_peg_dia   = 0.16;
joint_hole_dia  = 0.15;
joint_peg_height = 0.25;
joint_hole_depth = 0.32;

rail_print_angle = 45; // diagonal rotation so the rail fits a 256mm bed

eps = 0.01; // small overlap so parts fuse into one solid in unions

// ---- Shared sub-features ----

// Horizontal screw hole through one leg only (not the flange), so a screw
// bites into the solid door beside the cutout. Bored outward through the
// leg's outer face (x_start), centered on the leg's depth (Z), clear of
// the flanges which only occupy the ends of the Z range.
module screw_hole_leg(x_start, y_pos) {
    translate([x_start - eps, y_pos, door_depth / 2])
        rotate([0, 90, 0])
            cylinder(h = wall + 2 * eps, d = screw_hole_dia, $fn = 32);
}

// Countersink taper on the inner face (box-interior side) of a leg, where
// the screw head seats. dir = -1 for the left leg (inner face is the leg's
// high-x side, cone narrows toward -x); dir = +1 for the right leg (inner
// face is the low-x side, cone narrows toward +x).
module countersink_leg(x_face, y_pos, dir) {
    d1 = (dir < 0) ? screw_hole_dia : countersink_dia;
    d2 = (dir < 0) ? countersink_dia : screw_hole_dia;
    x0 = (dir < 0) ? x_face - countersink_depth : x_face;
    translate([x0, y_pos, door_depth / 2])
        rotate([0, 90, 0])
            cylinder(h = countersink_depth, d1 = d1, d2 = d2, $fn = 32);
}

// ---- Leg (a straight bar; the rail owns the corner squares, so a leg's
// own Y range starts at "wall", not 0) ----
// Built for the left side; the right leg is this shape mirrored about the
// box's centerline, which correctly flips the screw hole/countersink too.
module leg_shape(dir) {
    if (dir > 0) {
        translate([box_width, 0, 0]) mirror([1, 0, 0]) leg_shape(-1);
    } else {
        y0 = wall;
        y1 = box_height;
        h = y1 - y0;
        difference() {
            union() {
                translate([0, y0, 0]) cube([wall, h, door_depth]);
                if (flange_front)
                    translate([-flange_overlap, y0, -flange_thick])
                        cube([wall + flange_overlap, h, flange_thick + eps]);
                if (flange_back)
                    translate([-flange_overlap, y0, door_depth - eps])
                        cube([wall + flange_overlap, h, flange_thick + eps]);

                // Peg extending off the bottom face, into the rail's mortise
                translate([wall / 2, y0 - joint_peg_height, door_depth / 2])
                    rotate([-90, 0, 0])
                        cylinder(h = joint_peg_height + eps, d = joint_peg_dia, $fn = 32);
            }

            if (screw_holes) {
                y_pos = box_height - screw_hole_inset;
                screw_hole_leg(0, y_pos);
                if (countersink) countersink_leg(wall, y_pos, -1);
            }
        }
    }
}

// ---- Rail (full width; owns both bottom corner squares plus a mortise
// hole at each end that receives the matching leg's peg) ----
module rail_hole_at(x) {
    translate([x, wall - joint_hole_depth, door_depth / 2])
        rotate([-90, 0, 0])
            cylinder(h = joint_hole_depth + eps, d = joint_hole_dia, $fn = 32);
}

module rail_shape() {
    difference() {
        union() {
            cube([box_width, wall, door_depth]);
            if (flange_front)
                translate([-flange_overlap, -flange_overlap, -flange_thick])
                    cube([box_width + 2 * flange_overlap, wall + flange_overlap, flange_thick + eps]);
            if (flange_back)
                translate([-flange_overlap, -flange_overlap, door_depth - eps])
                    cube([box_width + 2 * flange_overlap, wall + flange_overlap, flange_thick + eps]);
        }

        rail_hole_at(wall / 2);
        rail_hole_at(box_width - wall / 2);
    }
}

// ---- Print-orientation wrappers ----
// Each piece is rotated so its "spine" (the inner face shared with the box
// opening) sits on the bed and the flange tips are at the top - going up,
// the cross-section only ever shrinks, so nothing overhangs and no
// supports are needed.
mm_per_inch = 25.4;

// The left and right legs are the same physical part: the flanges are
// front/back symmetric and the screw hole/countersink are centered on that
// same axis, so a 180-degree flip about the leg's own length swaps "left"
// for "right". One file, printed twice - flip one copy end-for-end when
// installing it on the other side of the door.
module render_leg() {
    scale([mm_per_inch, mm_per_inch, mm_per_inch])
        translate([0, 0, wall])
            rotate([0, 90, 0])
                leg_shape(-1);
}

module render_rail() {
    z_shift = wall;
    scale([mm_per_inch, mm_per_inch, mm_per_inch])
        rotate([0, 0, rail_print_angle])
            translate([0, 0, z_shift])
                rotate([-90, 0, 0])
                    rail_shape();
}
