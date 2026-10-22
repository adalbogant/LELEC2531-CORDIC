module mux_2to1(input logic signed [31:0] select0,
                input logic signed [31:0] select1,
                input logic select,
                output logic result);

    always_comb
    begin
        case (select)
            1'b0: result = select0;
            1'b1: result = select1;
        endcase
    end

endmodule