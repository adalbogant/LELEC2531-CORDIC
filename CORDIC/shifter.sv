module shifter(input logic signed [31:0] in,
                input logic [4:0] shift_amt,            // 32 iterations fits on 5 bits
                output logic signed [31:0] result);

    assign result = in >>> shift_amt;

endmodule