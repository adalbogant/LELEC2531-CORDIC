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
                if ((abs_real(from_q30(x_out) - expected_x) <= TOL) &&
                    (abs_real(from_q30(y_out) - expected_y) <= TOL) &&
                    (abs_real(from_q30(z_out) - expected_z) <= TOL))
                    $display("PASS | x=%f y=%f z=%f mode=%b coord_syst=%b| x_out=%f, y_out=%f, z_out=%f",
                            test_x, test_y, test_z, test_mode, test_coord_syst, 
                            from_q30(x_out), from_q30(y_out), from_q30(z_out));
                else
                    $display("FAIL | x=%f y=%f z=%f mode=%b coord_syst=%b| x_out=%f (expected %f), y_out=%f (expected %f), z_out=%f (expected %f)",
                            test_x, test_y, test_z, test_mode, test_coord_syst, 
                            from_q30(x_out), expected_x, from_q30(y_out), expected_y, from_q30(z_out), expected_z);
            end
            3'b001: begin
                if ((abs_real(from_q30(z_out) - expected_z) <= TOL))
                    $display("PASS | x=%f y=%f z=%f mode=%b coord_syst=%b| x_out=%f, y_out=%f, z_out=%f",
                            test_x, test_y, test_z, test_mode, test_coord_syst, 
                            from_q30(x_out), from_q30(y_out), from_q30(z_out));
                else
                    $display("FAIL | x=%f y=%f z=%f mode=%b coord_syst=%b| z_out=%f (expected %f)",
                            test_x, test_y, test_z, test_mode, test_coord_syst, 
                            from_q30(z_out), expected_z);
            end
            3'b010:begin
                if ((abs_real(from_q30(y_out) - expected_y) <= TOL))
                    $display("PASS | x=%f y=%f z=%f mode=%b coord_syst=%b| x_out=%f, y_out=%f, z_out=%f",
                            test_x, test_y, test_z, test_mode, test_coord_syst, 
                            from_q30(x_out), from_q30(y_out), from_q30(z_out));
                else
                    $display("FAIL | x=%f y=%f z=%f mode=%b coord_syst=%b| y_out=%f (expected %f)",
                            test_x, test_y, test_z, test_mode, test_coord_syst, 
                            from_q30(y_out), expected_y);
            end
            default:begin
                if ((abs_real(from_q30(x_out) - expected_x) <= TOL) &&
                    (abs_real(from_q30(y_out) - expected_y) <= TOL) &&
                    (abs_real(from_q30(z_out) - expected_z) <= TOL))
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

    // sin(33°) = sin(0.5759586532) et cos(33°)
    test(K_CIRC, 0, 0.5759586532, 1'b0, 2'b01, 0.8386705679, 0.544639035, 0, 3'b111);
    
    // arctan(sqrt(3))
    test(1, 1.732050808, 0, 1'b1, 2'b01, 0, 0, 1.047197551, 3'b001);

    // 0.6 * 0.7
    test(0.6, 0, 0.7, 1'b0, 2'b00, 0, 0.42, 0, 3'b010);

    // 0.42 / 0.7 + test default to linear
    test(0.7, 0.42, 0, 1'b1, 2'b10, 0, 0, 0.6, 3'b001);

    // cosh(40°) et sinh(40°)
    test(K_HYPERBOLIC, 0, 0.6981317008, 1'b0, 2'b11, 1.25375393409, 0.756239993158, 0, 3'b111);

    // arctanh(0.67)
    test(1, 0.67, 0, 1'b1, 2'b11, 0, 0, 0.810743125475, 3'b001);

    // $finish;
end

endmodule