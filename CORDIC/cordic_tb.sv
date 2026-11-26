`timescale 1ns/1ps

module cordic_tb;

function signed [31:0] to_q30(input real val);
    real scaled;
    begin
        scaled = val * 1_073_741_824.0; // * 2^30
        to_q30 = $rtoi(scaled);
    end
endfunction

function real from_q30(input signed [31:0] val);
    begin
        from_q30 = val / 1_073_741_824.0; // 2^30
    end
endfunction

function real abs_real(input real val);
    begin
        abs_real = (val < 0.0) ? -val : val;
    end
endfunction

localparam real K_CIRC = 0.607252935009;
localparam real K_HYPERBOLIC = 1.205136358446;
localparam real TOL = 0.00001;
localparam real TOL_HYPERBOLIC = 0.005;

logic clk, rst, start;
logic signed [31:0] x_init, y_init, z_init;
logic mode;
logic [1:0] coord_syst;
logic signed [31:0] x_out, y_out, z_out;
logic done;


cordic dut(
    .clk(clk), .rst(rst), .start(start),
    .x_init(x_init), .y_init(y_init), .z_init(z_init),
    .mode(mode), .coord_syst(coord_syst),
    .x_out(x_out), .y_out(y_out), .z_out(z_out),
    .done(done)
);

always #5 clk = ~clk;

task test;
    input real test_x, test_y, test_z;
    input logic test_mode;
    input [1:0] test_coord_syst;
    input real expected_x, expected_y, expected_z;
    input logic [2:0] to_test;
    input real tolerance;

    begin
        @(negedge clk)
        x_init = to_q30(test_x);
        y_init = to_q30(test_y);
        z_init = to_q30(test_z);
        mode = test_mode;
        coord_syst = test_coord_syst;
        start = 1'b1;

        @(posedge clk)
        #1;
        start = 1'b0;

        @(posedge done)
        #1;
        case (to_test)
            3'b111: begin
                if ((abs_real(from_q30(x_out) - expected_x) <= tolerance) &&
                    (abs_real(from_q30(y_out) - expected_y) <= tolerance) &&
                    (abs_real(from_q30(z_out) - expected_z) <= tolerance))
                    $display("PASS | x=%f y=%f z=%f mode=%b coord_syst=%b| x_out=%f, y_out=%f, z_out=%f",
                            test_x, test_y, test_z, test_mode, test_coord_syst, 
                            from_q30(x_out), from_q30(y_out), from_q30(z_out));
                else
                    $display("FAIL | x=%f y=%f z=%f mode=%b coord_syst=%b| x_out=%f (expected %f), y_out=%f (expected %f), z_out=%f (expected %f)",
                            test_x, test_y, test_z, test_mode, test_coord_syst, 
                            from_q30(x_out), expected_x, from_q30(y_out), expected_y, from_q30(z_out), expected_z);
            end
            3'b001: begin
                if ((abs_real(from_q30(z_out) - expected_z) <= tolerance))
                    $display("PASS | x=%f y=%f z=%f mode=%b coord_syst=%b| x_out=%f, y_out=%f, z_out=%f",
                            test_x, test_y, test_z, test_mode, test_coord_syst, 
                            from_q30(x_out), from_q30(y_out), from_q30(z_out));
                else
                    $display("FAIL | x=%f y=%f z=%f mode=%b coord_syst=%b| z_out=%f (expected %f)",
                            test_x, test_y, test_z, test_mode, test_coord_syst, 
                            from_q30(z_out), expected_z);
            end
            3'b010:begin
                if ((abs_real(from_q30(y_out) - expected_y) <= tolerance))
                    $display("PASS | x=%f y=%f z=%f mode=%b coord_syst=%b| x_out=%f, y_out=%f, z_out=%f",
                            test_x, test_y, test_z, test_mode, test_coord_syst, 
                            from_q30(x_out), from_q30(y_out), from_q30(z_out));
                else
                    $display("FAIL | x=%f y=%f z=%f mode=%b coord_syst=%b| y_out=%f (expected %f)",
                            test_x, test_y, test_z, test_mode, test_coord_syst, 
                            from_q30(y_out), expected_y);
            end
            default:begin
                if ((abs_real(from_q30(x_out) - expected_x) <= tolerance) &&
                    (abs_real(from_q30(y_out) - expected_y) <= tolerance) &&
                    (abs_real(from_q30(z_out) - expected_z) <= tolerance))
                    $display("PASS | x=%f y=%f z=%f mode=%b coord_syst=%b| x_out=%f, y_out=%f, z_out=%f",
                            test_x, test_y, test_z, test_mode, test_coord_syst, 
                            from_q30(x_out), from_q30(y_out), from_q30(z_out));
                else
                    $display("FAIL | x=%f y=%f z=%f mode=%b coord_syst=%b| x_out=%f (expected %f), y_out=%f (expected %f), z_out=%f (expected %f)",
                            test_x, test_y, test_z, test_mode, test_coord_syst, 
                            from_q30(x_out), expected_x, from_q30(y_out), expected_y, from_q30(z_out), expected_z);
            end
        endcase
        

        @(posedge clk);
        // Break between tests
    end
endtask

initial
begin
    clk = 0;
    rst = 1;
    #10;
    rst = 0;
    #10;

	// -----------------------------
	// ----- CIRCULAR ROTATION -----
	// -----------------------------
	// z_in = 0° = 0.0 rad
	// cos(z_in) = 1.0
	// sin(z_in) = 0.0
	test(K_CIRC, 0, 0.0, 1'b0, 2'b01, 1.0, 0.0, 0, 3'b111, TOL);

	// z_in = 5° = 0.0872664626 rad
	// cos(z_in) = 0.9961946981
	// sin(z_in) = 0.0871557427
	test(K_CIRC, 0, 0.0872664626, 1'b0, 2'b01, 0.9961946981, 0.0871557427, 0, 3'b111, TOL);

	// z_in = -21° = -0.3665191429 rad
	// cos(z_in) = 0.9335804265
	// sin(z_in) = -0.3583679495
	test(K_CIRC, 0, -0.3665191429, 1'b0, 2'b01, 0.9335804265, -0.3583679495, 0, 3'b111, TOL);

	// z_in = 33° = 0.5759586532 rad
	// cos(z_in) = 0.8386705679
	// sin(z_in) = 0.5446390351
	test(K_CIRC, 0, 0.5759586532, 1'b0, 2'b01, 0.8386705679, 0.5446390351, 0, 3'b111, TOL);

	// z_in = 45° = 0.7853981634 rad
	// cos(z_in) = 0.7071067812
	// sin(z_in) = 0.7071067812
	test(K_CIRC, 0, 0.7853981634, 1'b0, 2'b01, 0.7071067812, 0.7071067812, 0, 3'b111, TOL);

	// z_in = -67° = -1.1693705988 rad
	// cos(z_in) = 0.3907311285
	// sin(z_in) = -0.9205048534
	test(K_CIRC, 0, -1.1693705988, 1'b0, 2'b01, 0.3907311285, -0.9205048534, 0, 3'b111, TOL);

	// z_in = -90° = -1.5707963268 rad
	// cos(z_in) = -0.0
	// sin(z_in) = -1.0
	test(K_CIRC, 0, -1.5707963268, 1'b0, 2'b01, -0.0, -1.0, 0, 3'b111, TOL);

	// ------------------------------
	// ----- CIRCULAR VECTORING -----
	// ------------------------------
	// arg = 0 = 0.0 / 0.5
	// arctan(arg) = 0.0 (rad)
	test(0.5, 0.0, 0, 1'b1, 2'b01, 0, 0, 0.0, 3'b001, TOL);

	// arg = -0.5 = -0.25 / 0.5
	// arctan(arg) = -0.463647609 (rad)
	test(0.5, -0.25, 0, 1'b1, 2'b01, 0, 0, -0.463647609, 3'b001, TOL);

	// arg = 1 = 0.5 / 0.5
	// arctan(arg) = 0.7853981634 (rad)
	test(0.5, 0.5, 0, 1'b1, 2'b01, 0, 0, 0.7853981634, 3'b001, TOL);

	// arg = 1.7320508076 = 0.5 / 0.2886751346
	// arctan(arg) = 1.0471975512 (rad)
	test(0.2886751346, 0.5, 0, 1'b1, 2'b01, 0, 0, 1.0471975512, 3'b001, TOL);

	// arg = -2.5 = 0.5 / -0.2
	// arctan(arg) = -1.1902899497 (rad)
	test(-0.2, 0.5, 0, 1'b1, 2'b01, 0, 0, -1.1902899497, 3'b001, TOL);

	// arg = 3 = 0.5 / 0.1666666667
	// arctan(arg) = 1.2490457724 (rad)
	test(0.1666666667, 0.5, 0, 1'b1, 2'b01, 0, 0, 1.2490457724, 3'b001, TOL);

	// arg = -6.7 = 0.5 / -0.0746268657
	// arctan(arg) = -1.4226363061 (rad)
	test(-0.0746268657, 0.5, 0, 1'b1, 2'b01, 0, 0, -1.4226363061, 3'b001, TOL);

	// ---------------------------
	// ----- LINEAR ROTATION -----
	// ---------------------------
	// 0.6 * 0.7 = 0.42
	test(0.6, 0, 0.7, 1'b0, 2'b00, 0.6, 0.42, 0, 3'b010, TOL);

	// 0 * 0.8 = 0.0
	test(0, 0, 0.8, 1'b0, 2'b10, 0, 0.0, 0, 3'b010, TOL);

	// 0.5 * 0.5 = 0.25
	test(0.5, 0, 0.5, 1'b0, 2'b00, 0.5, 0.25, 0, 3'b010, TOL);

	// -0.8 * 0.8 = -0.64
	test(-0.8, 0, 0.8, 1'b0, 2'b10, -0.8, -0.64, 0, 3'b010, TOL);

	// -0.5 * -0.5 = 0.25
	test(-0.5, 0, -0.5, 1'b0, 2'b00, -0.5, 0.25, 0, 3'b010, TOL);

	// ----------------------------
	// ----- LINEAR VECTORING -----
	// ----------------------------
	// 0.42 / 0.7 = 0.6
	test(0.7, 0.42, 0, 1'b1, 2'b10, 0.7, 0, 0.6, 3'b001, TOL);

	// 0.06 / -0.7 = -0.0857142857
	test(-0.7, 0.06, 0, 1'b1, 2'b10, -0.7, 0, -0.0857142857, 3'b001, TOL);

	// 0.19 / 0.1 = 1.9
	test(0.1, 0.19, 0, 1'b1, 2'b00, 0.1, 0, 1.9, 3'b001, TOL);

	// -0.1 / -0.1 = 1.0
	test(-0.1, -0.1, 0, 1'b1, 2'b10, -0.1, 0, 1.0, 3'b001, TOL);

	// 0 / 1 = 0.0
	test(1, 0, 0, 1'b1, 2'b00, 1, 0, 0.0, 3'b001, TOL);

	// -------------------------------
	// ----- HYPERBOLIC ROTATION -----
	// -------------------------------
	// z_in = 0° = 0.0 rad
	// cosh(z_in) = 1.0
	// sinh(z_in) = 0.0
	test(K_HYPERBOLIC, 0, 0.0, 1'b0, 2'b11, 1.0, 0.0, 0, 3'b111, TOL_HYPERBOLIC);

	// z_in = 11° = 0.1919862177 rad
	// cosh(z_in) = 1.0184860303
	// sinh(z_in) = 0.1931677871
	test(K_HYPERBOLIC, 0, 0.1919862177, 1'b0, 2'b11, 1.0184860303, 0.1931677871, 0, 3'b111, TOL_HYPERBOLIC);

	// z_in = -27° = -0.471238898 rad
	// cosh(z_in) = 1.1131030424
	// sinh(z_in) = -0.4888746088
	test(K_HYPERBOLIC, 0, -0.471238898, 1'b0, 2'b11, 1.1131030424, -0.4888746088, 0, 3'b111, TOL_HYPERBOLIC);

	// z_in = 40° = 0.6981317008 rad
	// cosh(z_in) = 1.2537539341
	// sinh(z_in) = 0.7562399932
	test(K_HYPERBOLIC, 0, 0.6981317008, 1'b0, 2'b11, 1.2537539341, 0.7562399932, 0, 3'b111, TOL_HYPERBOLIC);

	// z_in = 67° = 1.1693705988 rad
	// cosh(z_in) = 1.7652638493
	// sinh(z_in) = 1.4547015012
	test(K_HYPERBOLIC, 0, 1.1693705988, 1'b0, 2'b11, 1.7652638493, 1.4547015012, 0, 3'b111, TOL_HYPERBOLIC);

	// z_in = 90° = 1.5707963268 rad
	// cosh(z_in) = 2.5091784787
	// sinh(z_in) = 2.3012989023
	test(K_HYPERBOLIC, 0, 1.5707963268, 1'b0, 2'b11, 2.5091784787, 2.3012989023, 0, 3'b111, TOL_HYPERBOLIC);

	// --------------------------------
	// ----- HYPERBOLIC VECTORING -----
	// --------------------------------
	// arg = 0 = 0.0 / 0.5
	// arctanh(0) = 0.0 (rad)
	test(0.5, 0.0, 0, 1'b1, 2'b11, 0, 0, 0.0, 3'b001, TOL_HYPERBOLIC);

	// arg = 0.13 = 0.065 / 0.5
	// arctanh(0.13) = 0.13073985 (rad)
	test(0.5, 0.065, 0, 1'b1, 2'b11, 0, 0, 0.13073985, 3'b001, TOL_HYPERBOLIC);

	// arg = -0.42 = -0.21 / 0.5
	// arctanh(-0.42) = -0.4476920235 (rad)
	test(0.5, -0.21, 0, 1'b1, 2'b11, 0, 0, -0.4476920235, 3'b001, TOL_HYPERBOLIC);

	// arg = 0.67 = 0.335 / 0.5
	// arctanh(0.67) = 0.8107431255 (rad)
	test(0.5, 0.335, 0, 1'b1, 2'b11, 0, 0, 0.8107431255, 3'b001, TOL_HYPERBOLIC);

	// arg = -0.9 = -0.45 / 0.5
	// arctanh(-0.9) = -1.4722194896 (rad)
	test(0.5, -0.45, 0, 1'b1, 2'b11, 0, 0, -1.4722194896, 3'b001, TOL_HYPERBOLIC);

    // $finish;
end

endmodule