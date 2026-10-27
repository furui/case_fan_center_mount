// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// ==============================================================================
// CASE FAN CENTER MOUNT ADAPTER
// ==============================================================================
// Bracket spanning two fan mounting holes. Defaults to 120mm, with presets for
// 80/92/140mm fans or custom dimensions.
//
// - Countersunk holes for ST4.8 fan screws on the left and right.
// - Independently selectable left/right pad heights with a 45° ramp to the center.
// - Flat bottom at Z = 0.
// - Straight row of center holes for ~5mm chassis screws, through-hole only.
// - Optional sealed mode with a perimeter ring around the fan tunnel.
// - Blade clearance of 0mm by default.
// - Center holes can be threaded or smooth pilot holes.
// ==============================================================================

/* [Fan Configuration] */
// Fan size preset
fan_preset            = 120;  // [80: "80mm Fan", 92: "92mm Fan", 120: "120mm Fan", 140: "140mm Fan", 0: "Custom"]
// Custom dimensions (used when fan_preset is Custom)
custom_fan_size       = 120.0;
custom_hole_spacing   = 105.0;
custom_blade_dia      = 116.0;

/* [Mount Mode & Seal Options] */
// Generate top & bottom mounts connected by a fan tunnel perimeter seal
sealed                = true; // [true: "Sealed (Top & Bottom with Perimeter Seal)", false: "Single (Top Bracket Only)"]
// Radial wall thickness of the fan tunnel perimeter seal (mm)
seal_thickness        = 2.0;   // [1.0:0.5:6.0]

/* [Part Dimensions & Independent Heights] */
// Height of the left and right fan mounting pads (mm)
corner_pad_height     = 3;  // [2.0:0.5:15.0]
// Height of the bridge and center chassis section (mm)
part_thickness        = 9;  // [2.0:0.5:15.0]
// Transition ramp angle between corner pads and bridge (degrees)
ramp_angle            = 15;   // [15:15:60]
// Clearance around the fan blade opening (mm)
blade_clearance       = 0.0;  // [0.0:0.5:5.0]
// Fillet radius (mm)
fillet_radius         = 2.5;  // [1.0:0.5:5.0]
// Outer pad radius margin around fan mounting holes (mm)
corner_pad_extra      = 0.0;  // [0.0:0.5:4.0]

/* [Fan Mounting Screws (Outer Holes Only)] */
// Clearance hole diameter for ST4.8 (5mm OD) fan screw (mm)
fan_screw_hole_dia    = 5.2;  // [4.8:0.1:6.0]
// Countersunk head diameter (6.0 to 6.5 mm head)
fan_screw_head_dia    = 6.5;  // [5.5:0.1:8.0]
// Countersink angle in degrees
fan_screw_head_angle  = 90;   // [82: "82° (Imperial)", 90: "90° (Standard ISO)", 100: "100°"]

/* [Center Chassis Mounting Holes] */
// Center hole type
center_hole_mode      = "threaded"; // ["threaded": "Modeled 3D Helical Thread", "pilot": "Self-Tapping Pilot Hole"]
// Nominal thread / screw outer diameter (~5mm)
thread_major_dia      = 5.0;  // [4.0:0.1:6.0]
// Thread pitch in mm (1.41mm - 1.6mm / ~16 - 18 TPI)
thread_pitch          = 1.50; // [1.41:0.01:1.60]
// Radial clearance for modeled internal threads (mm)
thread_clearance      = 0.15; // [0.0:0.05:0.40]
// Pilot hole diameter if center_hole_mode == "pilot" (mm)
pilot_hole_dia        = 4.4;  // [3.8:0.1:5.0]
// Center-to-center distance between middle holes (mm)
center_hole_spacing   = 7; // [5.0:0.5:20.0]
// Number of middle chassis mounting holes
center_hole_count     = 3;    // [1:1:5]
// Margin of solid plastic around middle holes (mm)
center_tab_margin     = 4.2;  // [3.0:0.5:8.0]

/* [Preview Options] */
// Show fan ghost preview (viewer only)
show_fan_preview      = true;

/* [Resolution] */
// Segment resolution for smooth circles and cylinders
$fn = 120;

// ==============================================================================
// COMPUTED PARAMETERS
// ==============================================================================

fan_size = (fan_preset == 80)  ? 80.0 :
           (fan_preset == 92)  ? 92.0 :
           (fan_preset == 120) ? 120.0 :
           (fan_preset == 140) ? 140.0 : custom_fan_size;

hole_spacing = (fan_preset == 80)  ? 71.5 :
               (fan_preset == 92)  ? 82.5 :
               (fan_preset == 120) ? 105.0 :
               (fan_preset == 140) ? 125.0 : custom_hole_spacing;

blade_opening_dia = (fan_preset == 80)  ? 76.0 :
                    (fan_preset == 92)  ? 88.0 :
                    (fan_preset == 120) ? 116.0 :
                    (fan_preset == 140) ? 136.0 : custom_blade_dia;

corner_margin = (fan_size - hole_spacing) / 2;
corner_pad_r  = corner_margin + corner_pad_extra;

tab_half_width = (center_hole_count - 1) * center_hole_spacing / 2 + (thread_major_dia / 2) + center_tab_margin;
tab_y_bottom   = -(thread_major_dia / 2 + center_tab_margin);

max_h = max(corner_pad_height, part_thickness);

// ==============================================================================
// INTERNAL THREAD CUTTER
// ==============================================================================

module continuous_thread_cutter(d_major=5.0, pitch=1.5, length=10, clearance=0.15, steps_per_turn=32) {
    d = d_major + 2 * clearance;
    h_thread = 0.54127 * pitch; // Standard metric thread engagement depth
    r_maj = d / 2;
    r_min = max(0.5, r_maj - h_thread);
    overlap = 0.3;              // Overlap into the core to avoid tangent artifacts
    r_core = r_min;
    r_root = r_min - overlap;
    
    extra_turns = 2;
    turns = ceil(length / pitch) + extra_turns * 2;
    n_steps = turns * steps_per_turn;
    z_offset = -extra_turns * pitch;
    total_height = turns * pitch + 4;
    tooth_h = 0.9 * pitch;       // Prevents inter-turn self-intersection at root
    
    pts = [
        for (i = [0 : n_steps])
            let (
                a = i * 360 / steps_per_turn,
                c = cos(a),
                s = sin(a),
                z = (i / steps_per_turn) * pitch + z_offset
            )
            each [
                [r_root * c, r_root * s, z],
                [r_maj * c, r_maj * s, z + tooth_h * 0.5],
                [r_root * c, r_root * s, z + tooth_h]
            ]
    ];
    
    faces = concat(
        // Continuous helical quad bands
        [
            for (i = [0 : n_steps - 1])
                let (b = i * 3, nb = (i + 1) * 3)
                each [
                    [b + 0, b + 1, nb + 1],
                    [b + 0, nb + 1, nb + 0],
                    [b + 1, b + 2, nb + 2],
                    [b + 1, nb + 2, nb + 1],
                    [b + 2, b + 0, nb + 0],
                    [b + 2, nb + 0, nb + 2]
                ]
        ],
        // Start cap
        [[0, 2, 1]],
        // End cap
        let (last = n_steps * 3)
        [[last + 0, last + 1, last + 2]]
    );
    
    union() {
        translate([0, 0, z_offset - 2])
            cylinder(r = r_core, h = total_height, $fn = steps_per_turn);
        polyhedron(points = pts, faces = faces, convexity = 10);
    }
}

// ==============================================================================
// 2D PROFILE & 3D HEIGHT PROFILE
// ==============================================================================

module adapter_profile_2d() {
    // The bridge web survives the fillet only where it is at least
    // 2 * fillet_radius thick. Connector blocks make up the difference
    // if the center tab is too narrow to reach that point.
    blade_r     = blade_opening_dia / 2 + blade_clearance;
    web_y       = corner_margin - 2 * fillet_radius;
    web_dy      = web_y + hole_spacing / 2;
    web_x       = sqrt(max(0, blade_r * blade_r - web_dy * web_dy));
    conn_h      = 2 * fillet_radius + 1;
    conn_w      = max(6, web_x - tab_half_width + 2);
    conn_needed = tab_half_width < web_x - fillet_radius;

    difference() {
        // Smooth the profile corners
        offset(r = fillet_radius) offset(r = -fillet_radius) {
            union() {
                // Outer bridge between corner pads
                difference() {
                    hull() {
                        translate([-hole_spacing / 2, 0]) circle(r = corner_pad_r);
                        translate([hole_spacing / 2, 0]) circle(r = corner_pad_r);
                    }
                    // Cut out the fan blade opening
                    translate([0, -hole_spacing / 2])
                        circle(d = blade_opening_dia + 2 * blade_clearance);
                }
                // Central tab holding the middle chassis screw holes
                hull() {
                    r_tab = 3.0;
                    translate([-tab_half_width + r_tab, tab_y_bottom + r_tab]) circle(r = r_tab);
                    translate([tab_half_width - r_tab, tab_y_bottom + r_tab]) circle(r = r_tab);
                    translate([-tab_half_width + r_tab, corner_margin - r_tab]) circle(r = r_tab);
                    translate([tab_half_width - r_tab, corner_margin - r_tab]) circle(r = r_tab);
                }
                // Connector blocks tying the center tab to the corner pads
                if (conn_needed)
                    for (sx = [-1, 1])
                        translate([
                            sx * (tab_half_width - 2) - (sx < 0 ? conn_w : 0),
                            corner_margin - conn_h
                        ])
                            square([conn_w, conn_h]);
            }
        }
        // Trim flush along the top outer edge of the fan frame
        translate([-fan_size, corner_margin])
            square([fan_size * 2, 30]);
    }
}

// X-Z height profile: bottom face is flat at Z = 0
module height_profile_xz() {
    x_outer = fan_size / 2 + 5;
    x_pad = hole_spacing / 2 - corner_pad_r; // Boundary where corner pad ends
    
    // Ramp length along X (dx = dz / tan(angle))
    dh = abs(corner_pad_height - part_thickness);
    ramp_len = (dh > 0) ? (dh / tan(ramp_angle)) : 0;
    x_ramp = max(tab_half_width + 1, x_pad - ramp_len);
    
    polygon(points = [
        [x_outer,  0],
        [-x_outer, 0],
        [-x_outer, corner_pad_height],
        [-x_pad,   corner_pad_height],
        [-x_ramp,  part_thickness],
        [x_ramp,   part_thickness],
        [x_pad,    corner_pad_height],
        [x_outer,  corner_pad_height]
    ]);
}

// Single bracket body with independent corner heights and sloped ramps
module single_mount_body_3d() {
    if (corner_pad_height == part_thickness) {
        linear_extrude(height = part_thickness)
            adapter_profile_2d();
    } else {
        intersection() {
            linear_extrude(height = max_h + 10, center = true)
                adapter_profile_2d();
            translate([0, fan_size, 0])
                rotate([90, 0, 0])
                    linear_extrude(height = fan_size * 2)
                        height_profile_xz();
        }
    }
}

// ==============================================================================
// HOLE MODULES
// ==============================================================================

// Countersunk through-hole for ST4.8 fan screw
module fan_screw_hole() {
    cone_h = (fan_screw_head_dia - fan_screw_hole_dia) / (2 * tan(fan_screw_head_angle / 2));
    
    union() {
        // Through-bore
        translate([0, 0, -5])
            cylinder(d = fan_screw_hole_dia, h = max_h + 10);
            
        // Countersink at the front face (Z = corner_pad_height)
        translate([0, 0, corner_pad_height - cone_h])
            cylinder(d1 = fan_screw_hole_dia, d2 = fan_screw_head_dia + 2 * 2 * tan(fan_screw_head_angle / 2), h = cone_h + 2);
    }
}

// Center chassis hole, through the full part
module chassis_center_hole() {
    z_cut_start = -5;
    cut_length  = max_h + 10;

    if (center_hole_mode == "threaded") {
        translate([0, 0, z_cut_start])
            continuous_thread_cutter(
                d_major = thread_major_dia,
                pitch = thread_pitch,
                length = cut_length,
                clearance = thread_clearance,
                steps_per_turn = 32
            );
    } else {
        // Smooth through-hole
        translate([0, 0, z_cut_start])
            cylinder(d = pilot_hole_dia, h = cut_length, $fn = 64);
    }
}

// ==============================================================================
// SINGLE ADAPTER
// ==============================================================================

// Single adapter bracket
module single_adapter() {
    difference() {
        single_mount_body_3d();
            
        // Left fan mounting hole (countersunk)
        translate([-hole_spacing / 2, 0, 0])
            fan_screw_hole();
            
        // Right fan mounting hole (countersunk)
        translate([hole_spacing / 2, 0, 0])
            fan_screw_hole();
            
        // Center chassis holes
        for (i = [0 : center_hole_count - 1]) {
            x_pos = (i - (center_hole_count - 1) / 2) * center_hole_spacing;
            translate([x_pos, 0, 0])
                chassis_center_hole();
        }
    }
}

// Cylindrical perimeter seal around the fan tunnel at part_thickness
module sealing_ring() {
    translate([0, -hole_spacing / 2, 0])
        linear_extrude(height = part_thickness)
            difference() {
                circle(d = blade_opening_dia + 2 * seal_thickness);
                circle(d = blade_opening_dia);
            }
}

// ==============================================================================
// MAIN ASSEMBLY
// ==============================================================================

module case_fan_center_mount_adapter() {
    if (!sealed) {
        // Single bracket mode (top mount only)
        single_adapter();
    } else {
        // Sealed mode: top adapter, bottom adapter, and sealing ring
        union() {
            // Top adapter
            single_adapter();
            
            // Bottom adapter, rotated 180° about the fan center
            translate([0, -hole_spacing / 2, 0])
                rotate([0, 0, 180])
                    translate([0, hole_spacing / 2, 0])
                        single_adapter();
                        
            // Sealing ring around the fan tunnel
            sealing_ring();
        }
    }
}

// ==============================================================================
// PREVIEW HELPERS
// ==============================================================================

module fan_ghost_preview() {
    color([0.25, 0.25, 0.25, 0.35]) {
        translate([0, -hole_spacing / 2, -25]) {
            difference() {
                // Square fan frame with rounded corners
                linear_extrude(height = 25) {
                    offset(r = 5) offset(r = -5)
                        square([fan_size, fan_size], center = true);
                }
                // Central circular inlet opening
                translate([0, 0, -1])
                    cylinder(d = blade_opening_dia, h = 27);
                // 4 fan corner mounting holes
                for (mx = [-1, 1], my = [-1, 1]) {
                    translate([mx * hole_spacing / 2, my * hole_spacing / 2, -1])
                        cylinder(d = 4.3, h = 27);
                }
            }
        }
    }
}

// ==============================================================================
// TOP-LEVEL RENDER
// ==============================================================================

case_fan_center_mount_adapter();

// Fan preview (viewer only)
if ($preview && show_fan_preview) {
    %fan_ghost_preview();
}
