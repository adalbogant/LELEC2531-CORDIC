module FSM_control_unit(input logic clk, rst, start,
                        input logic [1:0] coord_syst,
                        output logic enable_cfg, enable_reg, select_init,
                        output logic [4:0] iter_idx);

// !! TODO : iter_idx commence à 1 en mode hyperbolique
typedef enum logic [1:0] {IDLE, LOAD, COMPUTE, DONE} statetype;
statetype state, nextstate;

// TODO : où calculer iter_idx, comment l'incrémenter alors que c'est un output, comment gérer le fait
// de sauter certaines itérations pour hyperbolique ?
logic [4:0] iter_number = 0;
logic repeated = 0;             // Indicate if we need to repeat the next iteration (hyperbolic mode)

always_ff @(posedge clk, posedge reset)
    if (reset) begin
        state <= IDLE;
        iter_number <= 0;
        repeated <= 0;
    end
    else begin
        state <= nextstate;
        if (coord_syst == 2'b11) begin
            if (((iter_number == 4) || (iter_number == 13)) && (repeated == 0)) repeated <= 1;
            else if (((iter_number == 4) || (iter_number == 13)) && (repeated == 1)) begin
                repeated <= 0;
                iter_number <= iter_number + 1;
            end
            else iter_number <= iter_number + 1;
        end
        else iter_number <= iter_number + 1;
    end


// Nextstate logic
always_comb
begin
    case (state)
        IDLE: begin
            if (start)  nextstate = LOAD;
            else        nextstate = IDLE;
        end
        LOAD: nextstate = COMPUTE;
        COMPUTE: begin
            if (iter_number > 5'b11111)    nextstate = DONE;        // TODO : gérer iter_number
            else                        nextstate = COMPUTE;
        end
        DONE: nextstate = IDLE;
    endcase
end

// Output logic





endmodule