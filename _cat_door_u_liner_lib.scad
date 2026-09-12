// Cat door U-shaped liner - shared geometry.
// Fits into a rectangular box cut into a door, lining the bottom and
// two sides with a thin wall so a smaller insert seats snugly in the gap.
// Top of the U is left open.
//
// Flanges at the front and/or back cap the ends, sitting flush against
// the door's face and overlapping the cut edge to hide it.
//
// The full part (10.5in wide) is too wide for a 256mm printer bed, so it's
// split down the middle of the bottom rail into two L-shaped halves - see
// cat_door_u_liner_left.scad / cat_door_u_liner_right.scad, which include
// this file and call render_liner(). This file has no directly renderable
// geometry of its own (build_stl.py skips files starting with "_").

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

split_x = box_width / 2; // where to cut the bottom rail into two halves
                          // (centered; well clear of the screw holes near
                          // each leg, so the cut doesn't hit any hardware)

eps = 0.01; // small overlap so flange and liner fuse into one solid
big = 1000; // far outside the model, used to build clipping half-spaces

// ---- Model ----
// U shape: two side rectangles + one bottom rectangle, open at the top.
// w/h are the outer footprint, wall_thick the leg width, spanning z0..z1,
// shifted by (x_off, y_off) so a flange can grow outward from the liner.
module u_shape(w, h, wall_thick, z0, z1, x_off = 0, y_off = 0) {
    zt = z1 - z0;
    translate([x_off, y_off, z0]) {
        cube([wall_thick, h, zt]);                       // left side
        translate([w - wall_thick, 0, 0])
            cube([wall_thick, h, zt]);                    // right side
        cube([w, wall_thick, zt]);                        // bottom
    }
}

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

module cat_door_liner() {
    difference() {
        union() {
            // Main liner, filling the through-hole depth
            u_shape(box_width, box_height, wall, 0, door_depth);

            // Front flange: sits in front of the door face (z < 0), wider
            // than the hole so it overlaps and hides the cut on 3 sides
            if (flange_front)
                u_shape(box_width + 2 * flange_overlap, box_height + flange_overlap,
                        wall + flange_overlap, -flange_thick, eps,
                        -flange_overlap, -flange_overlap);

            // Back flange: mirrors the front, behind the door face
            if (flange_back)
                u_shape(box_width + 2 * flange_overlap, box_height + flange_overlap,
                        wall + flange_overlap, door_depth - eps, door_depth + flange_thick,
                        -flange_overlap, -flange_overlap);
        }

        if (screw_holes) {
            y_pos = box_height - screw_hole_inset;
            screw_hole_leg(0, y_pos);                 // left leg, out through x=0
            screw_hole_leg(box_width - wall, y_pos);  // right leg, out through x=box_width

            if (countersink) {
                countersink_leg(wall, y_pos, -1);            // left leg, inner face
                countersink_leg(box_width - wall, y_pos, 1); // right leg, inner face
            }
        }
    }
}

// Keeps only the x <= split_x (or x >= split_x) portion of the liner, for
// printing as two separate pieces that join at the middle of the bottom rail.
module cat_door_liner_part(part) {
    if (part == "left")
        intersection() {
            cat_door_liner();
            translate([-big, -big, -big]) cube([big + split_x, 2 * big, 2 * big]);
        }
    else if (part == "right")
        intersection() {
            cat_door_liner();
            translate([split_x, -big, -big]) cube([big + (box_width - split_x), 2 * big, 2 * big]);
        }
    else
        cat_door_liner();
}

// All dimensions above are in inches; STL files carry no unit, and slicers
// (Elegoo/Cura/PrusaSlicer/etc.) assume mm, so scale the output to mm here
// to keep the real-world size correct on import.
module render_liner(part = "whole") {
    mm_per_inch = 25.4;
    scale([mm_per_inch, mm_per_inch, mm_per_inch])
        cat_door_liner_part(part);
}
