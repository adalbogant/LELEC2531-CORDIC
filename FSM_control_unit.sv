module FSM_control_unit(input logic clk, rst, start,
                        input logic [1:0] coord_syst,
                        output logic enable_cfg, enable_reg, select_init,
                        output logic [4:0] iter_idx
                        output logic done);

// !! iter_idx commence à 1 en hyperbolique
typedef enum logic [1:0] {IDLE, LOAD, COMPUTE, DONE} statetype;
statetype state, nextstate;

logic [4:0] iter_number;
logic is_last_iter;
logic repeated;             // Indicate if we need to repeat the next iteration (hyperbolic mode)

assign is_last_iter = (iter_number == 5'd31);

always_ff @(posedge clk, posedge rst)
    if (rst) begin
        state <= IDLE;
        iter_number <= 5'b0;
        repeated <= 1'b0;
    end
    else begin
        state <= nextstate;

        case (state)
            IDLE: begin
                iter_number <= 5'b0;
                repeated <= 1'b0;
            end
            LOAD: begin
                iter_number <= (coord_syst == 2'b11) ? 5'd1 : 5'd0;
                repeated <= 1'b0;
            end
            COMPUTE: begin
                if (coord_syst == 2'b11) begin
                // Hyperbolic mode => repeat iteration 4 and 13
                    if (((iter_number == 4) || (iter_number == 13)) && (repeated == 0)) repeated <= 1'b1;
                    else if (((iter_number == 4) || (iter_number == 13)) && (repeated == 1)) begin
                        repeated <= 0;
                        if (!is_last_iter) iter_number <= iter_number + 1;
                    end
                    else iter_number <= iter_number + 1;
                end else begin
                    if  (!is_last_iter) iter_number <= iter_number + 1;
                end
            end
            DONE: repeated <= 1'b0;
        endcase
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
            if (is_last_iter)    nextstate = DONE;       // TODO : est-ce que le check est au début ou à la fin de l'itération
            else                 nextstate = COMPUTE;
        end
        DONE: nextstate = IDLE;
    endcase
end

// Output logic
always_comb
begin
    done = 1'b0;
    iter_idx = iter_number;
    enable_cfg = 1'b0;
    enable_reg = 1'b0;
    select_init = 1'b0;
    case (state)
        IDLE: begin
            enable_cfg = 1'b1;
            select_init = 1'b1;
        end
        LOAD: begin
            enable_reg = 1'b1;
            select_init = 1'b1;
        end
        COMPUTE: begin
            enable_reg = 1'b1;
        end
        DONE: begin
            done = 1'b1;
        end
        default: ;
    endcase
end





endmodule