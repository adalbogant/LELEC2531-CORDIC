module adder(input logic signed [31:0] a,
            input logic signed [31:0] b,
            input logic sign,
            output logic [31:0] result);

    // TODO : est-ce qu'il faut diviser en partie entière et partie décimale
    always_comb
    begin
        case (sign)
            1'b0: result = a + b;
            1'b1: result = a - b;
        endcase
    end

endmodule