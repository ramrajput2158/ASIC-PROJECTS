// Code your design here
module elevator_controller (
    input logic clk,
    input logic rst, // Active-low reset
    input logic [3:0] floor_req,
    input logic door_time_done,

    output logic [1:0] current_floor,
    output logic motor_up,
    output logic motor_down,
    output logic door_open,
    output logic [2:0] state
);
    typedef enum logic [2:0] {
        IDLE = 3'd0,
        MOVE_UP = 3'd1,
        MOVE_DOWN = 3'd2,
        DOOR_OPEN = 3'd3,
        DOOR_CLOSE = 3'd4
    } state_t;

    state_t current_state, next_state;

    logic [3:0] pending_req;
    logic [3:0] pending_next;

    logic [1:0] next_floor;
    logic request_above;
    logic request_below;

    assign state = current_state;

    // Calculate the next floor
    always_comb begin
        next_floor = current_floor;

        if (current_state == MOVE_UP &&
            current_floor < 2'd3)
            next_floor = current_floor + 2'd1;

        else if (current_state == MOVE_DOWN &&
                 current_floor > 2'd0)
            next_floor = current_floor - 2'd1;
    end

    // Save new requests and clear the served floor
    always_comb begin
        pending_next = pending_req | floor_req;

        if (current_state == DOOR_OPEN)
            pending_next[current_floor] = 1'b0;
    end

    // Detect pending requests above and below
    always_comb begin
        request_above = 1'b0;
        request_below = 1'b0;

        for (int idx = 0; idx < 4; idx++) begin
            if (pending_next[idx] &&
                (idx > current_floor))
                request_above = 1'b1;

            if (pending_next[idx] &&
                (idx < current_floor))
                request_below = 1'b1;
        end
    end

    // FSM next-state logic
    always_comb begin
        next_state = current_state;

        case (current_state)

            IDLE: begin
                if (pending_next[current_floor])
                    next_state = DOOR_OPEN;
                else if (request_above)
                    next_state = MOVE_UP;
                else if (request_below)
                    next_state = MOVE_DOWN;
            end

            MOVE_UP: begin
                if (pending_next[current_floor])
                    next_state = DOOR_OPEN;
                else if (current_floor < 2'd3) begin
                    if (pending_next[next_floor])
                        next_state = DOOR_OPEN;
                    else if (request_above)
                        next_state = MOVE_UP;
                    else if (request_below)
                        next_state = MOVE_DOWN;
                    else
                        next_state = IDLE;
                end
                else if (request_below)
                    next_state = MOVE_DOWN;
                else
                    next_state = IDLE;
            end

            MOVE_DOWN: begin
                if (pending_next[current_floor])
                    next_state = DOOR_OPEN;
                else if (current_floor > 2'd0) begin
                    if (pending_next[next_floor])
                        next_state = DOOR_OPEN;
                    else if (request_below)
                        next_state = MOVE_DOWN;
                    else if (request_above)
                        next_state = MOVE_UP;
                    else
                        next_state = IDLE;
                end
                else if (request_above)
                    next_state = MOVE_UP;
                else
                    next_state = IDLE;
            end

            DOOR_OPEN: begin
                if (door_time_done)
                    next_state = DOOR_CLOSE;
            end

            DOOR_CLOSE: begin
                if (pending_next[current_floor])
                    next_state = DOOR_OPEN;
                else if (request_above)
                    next_state = MOVE_UP;
                else if (request_below)
                    next_state = MOVE_DOWN;
                else
                    next_state = IDLE;
            end

            default: next_state = IDLE;

        endcase
    end

    // Sequential logic
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            current_state <= IDLE;
            current_floor <= 2'd0;
            pending_req <= 4'b0000;
        end
        else begin
            current_state <= next_state;
            pending_req <= pending_next;

            if (current_state == MOVE_UP &&
                current_floor < 2'd3)
                current_floor <= current_floor + 2'd1;

            else if (current_state == MOVE_DOWN &&
                     current_floor > 2'd0)
                current_floor <= current_floor - 2'd1;
        end
    end

    // Output logic
    always_comb begin
        motor_up = (current_state == MOVE_UP);
        motor_down = (current_state == MOVE_DOWN);
        door_open = (current_state == DOOR_OPEN);
    end

endmodule
