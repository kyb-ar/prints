// Cat door U-shaped liner
// Fits into a rectangular box cut into a door, lining the bottom and
// two sides with a thin wall so a smaller insert seats snugly in the gap.
// Top of the U is left open.
//
// Flanges at the front and/or back cap the ends, sitting flush against
// the door's face and overlapping the cut edge to hide it.

// ---- Parameters (inches) ----
door_depth      = 1.5;   // door thickness (liner spans this, Z)
box_width       = 10.5;  // width of the cutout in the door (X)
box_height      = 7.75;  // height of the cutout in the door (Y)
wall            = 0.25;  // thickness of the liner material (the gap it fills)

flange_front    = true;  // add a flange on the front face
flange_back     = true;  // add a flange on the back face
flange_overlap  = 0.25;  // how far the flange extends past the cut edge
flange_thick    = 0.1;   // flange thickness (Z), kept small/low-profile

eps = 0.01; // small overlap so flange and liner fuse into one solid

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

module cat_door_liner() {
    // Main liner, filling the through-hole depth
    u_shape(box_width, box_height, wall, 0, door_depth);

    // Front flange: sits in front of the door face (z < 0), wider than
    // the hole so it overlaps and hides the cut on 3 sides (not the top)
    if (flange_front)
        u_shape(box_width + 2 * flange_overlap, box_height + flange_overlap,
                wall + flange_overlap, -flange_thick, eps,
                -flange_overlap, -flange_overlap);

    // Back flange: mirrors the front, behind the door face (z > door_depth)
    if (flange_back)
        u_shape(box_width + 2 * flange_overlap, box_height + flange_overlap,
                wall + flange_overlap, door_depth - eps, door_depth + flange_thick,
                -flange_overlap, -flange_overlap);
}

cat_door_liner();
