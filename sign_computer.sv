module sign_computer(input logic [31:0] y,
                    input logic [31:0] z,
                    input logic mode,
                    input logic [1:0] coord_syst,
                    output logic sign_x,
                    output logic sign_y,
                    output logic sign_z);

    // Sign is 0 to add and 1 to subtract
    logic delta_k;
    always_comb
    begin
        case (mode)
            1'b0:
                delta_k = z[31];
            1'b1:
                delta_k = ~y[31];
        endcase
    end

    assign sign_x = ~delta_k;
    assign sign_y = delta_k;
    assign sign_z = ~delta_k;

endmodule