module cordic (input logic clk, rst, start,
              input logic signed [31:0] x_init, y_init, z_init,
              input logic mode,
              input logic [1:0] coord_syst,
              output logic signed [31:0] x_out, y_out, z_out,
              output logic done);

logic signed [31:0] x_in, y_in, z_in;      // Input values of registers (after multiplexers)
logic signed [31:0] x_reg, y_reg, z_reg;
logic signed [31:0] x_k, y_k, z_k;
logic signed [31:0] shifted_x, shifted_y;
logic signed [31:0] second_input_adder_x;
logic [31:0] result_angle_LUT;
logic sign_x, sign_y, sign_z;
logic mode_reg;
logic [1:0] coord_syst_reg;

logic enable_cfg, enable_reg, select_init;
logic [4:0] iter_idx;

FSM_control_unit FSM_CU(
    .clk(clk), .rst(rst), .start(start),
    .coord_syst(coord_syst_reg),
    .enable_cfg(enable_cfg), .enable_reg(enable_reg), .select_init(select_init),
    .iter_idx(iter_idx),
    .done(done)
);

angle_lut ANGLE_LUT(
    .iter_idx(iter_idx), 
    .coord_syst(coord_syst_reg), 
    .result(result_angle_LUT)
);

mux_2to1 MUX_X(
    .select0(x_k), 
    .select1(x_init),
    .select(select_init),
    .result(x_in)
);
mux_2to1 MUX_Y(
    .select0(y_k), 
    .select1(y_init),
    .select(select_init),
    .result(y_in)
);
mux_2to1 MUX_Z(
    .select0(z_k), 
    .select1(z_init),
    .select(select_init),
    .result(z_in)
);
mux_2to1 MUX_ADDER_X(
    .select0(32'sd0),
    .select1(shifted_y),
    .select(coord_syst_reg[0]),         // Linear mode is the default
    .result(second_input_adder_x)
);

shifter SHIFT_Y(.in(y_reg), .shift_amt(iter_idx), .result(shifted_y));
shifter SHIFT_X(.in(x_reg), .shift_amt(iter_idx), .result(shifted_x));

sign_computer SIGN_COMP(
    .y(y_reg), .z(z_reg), .mode(mode_reg), 
    .coord_syst(coord_syst_reg),
    .sign_x(sign_x), .sign_y(sign_y), .sign_z(sign_z)
);

adder ADDER_X(
    .a(x_reg),
    .b(second_input_adder_x),
    .sign(sign_x),
    .result(x_k)
);
adder ADDER_Y(
    .a(y_reg),
    .b(shifted_x),
    .sign(sign_y),
    .result(y_k)
);
adder ADDER_Z(
    .a(z_reg),
    .b(result_angle_LUT),
    .sign(sign_z),
    .result(z_k)
);

always_ff@(posedge clk, posedge rst)
    if (rst) begin
        coord_syst_reg <= 2'b00;
        mode_reg <= 1'b0;
        x_reg <= 32'sd0;
        y_reg <= 32'sd0;
        z_reg <= 32'sd0;
    end
    else begin
        if (enable_cfg) begin
            coord_syst_reg <= coord_syst;
            mode_reg <= mode;
        end
        if (enable_reg) begin
            x_reg <= x_in;
            y_reg <= y_in;
            z_reg <= z_in;
        end
    end

assign x_out = x_reg;
assign y_out = y_reg;
assign z_out = z_reg;


endmodule