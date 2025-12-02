`default_nettype none

module test_mux_tb (
    // the user module's interface
    input wire clk,
    input wire rst_n,
    input wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input wire [7:0] uio_in,  // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path

    // control interface
    input wire ctrl_sel_rst_n,
    input wire ctrl_sel_inc,
    input wire ctrl_ena
);

`ifdef SIM_ICARUS
  initial begin
    string f_name;
    $timeformat(-9, 2, " ns", 20);
    if ($value$plusargs("WAVE_FILE=%s", f_name)) begin
      $display("%0t: Capturing wave file %s", $time, f_name);
      $dumpfile(f_name);
      $dumpvars(0, test_mux_tb);
    end else begin
      $display("%0t: No filename provided - disabling wave capture", $time);
    end
  end
`endif

  wire [73:0] pad_raw;
  assign pad_raw[0] = ctrl_ena;
  assign pad_raw[1] = ctrl_sel_inc;
  assign pad_raw[2] = ctrl_sel_rst_n;
  assign uo_out = pad_raw[16:9];
  assign pad_raw[44:37] = uio_in;
  assign uio_out = pad_raw[44:37];
  assign pad_raw[53:46] = ui_in;
  assign pad_raw[54] = rst_n;
  assign pad_raw[55] = clk;

  wire dvss = 1'b0;
  wire dvdd = 1'b1;

  tt_gf_wrapper tt_chip (
`ifdef GL_TEST
      .dvss (dvss),
      .dvdd (dvdd),
`endif
      .pad_raw(pad_raw)
  );

endmodule
