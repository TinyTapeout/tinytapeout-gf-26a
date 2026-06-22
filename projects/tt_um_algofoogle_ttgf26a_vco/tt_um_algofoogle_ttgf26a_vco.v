/*
 * Copyright (c) 2026 Anton Maurovic
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

//////// !!NOTE!! This isn't the real module.
// This 1x1 tile is a custom layout, and this file
// is just included here to keep various scripts happy.
// The real layout is supplied directly as
//    ./gds/tt_um_algofoogle_ttgf26a_vco.gds
// and is generated from
//    ./magic/tt_um_algofoogle_ttgf26a_vco.mag
// It is represented by ./verilog/dv/top.v
// and its digital block is hardened using config in
//    ./librelane/digital/config9t.json
// and from source in
//    ./verilog/rtl/digital.v
//
// The code below is just a copy of ./verilog/dv/top.v...
//
module tt_um_algofoogle_ttgf26a_vco (
    input  wire       VGND,
    input  wire       VDPWR,    // 3.3v core power supply
//    input  wire       VAPWR,    // second analog power supply (VAA)
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    wire vco_osc; // Oscillating output from the VCO.
    wire [8:0] vco_dn; // Negated binary inputs (9 bits) for DAC that produces 0..3.3V vin for the VCO.

    digital digital_0 (
        .VDD        (VDPWR),
        .VSS        (VGND),
        .clk        (clk),
        .rst_n      (rst_n),
        .ui_in      (ui_in),
        .uio_in     (uio_in),
        .uio_oe     (uio_oe),
        .uio_out    (uio_out),
        .uo_out     (uo_out),
        .vco_dn     (vco_dn), // Out to DAC/VCO combo (vco_combo).
        .vco_osc    (vco_osc) // Clk in from DAC/VCO combo.
    );

    vco_combo vco_combo_0 (
        .VPWR       (VDPWR),
        .VGND       (VGND),
        .dn         (vco_dn),
        .vco_osc    (vco_osc)
    );

endmodule
