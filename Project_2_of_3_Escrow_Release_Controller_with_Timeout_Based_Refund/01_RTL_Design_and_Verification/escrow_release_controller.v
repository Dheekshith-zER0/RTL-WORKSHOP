`timescale 1ns/1ps

module escrow_release_controller #(
    parameter integer TIMEOUT_CYCLES = 16
)(
    input  wire clk,
    input  wire rst,
    input  wire start,

    input  wire buyer_approve,
    input  wire seller_approve,
    input  wire arbiter_approve,

    output wire release_to_seller,
    output wire refund_to_buyer,
    output wire busy,
    output wire done
);

    // FSM: Finite State Machine
    // A circuit that moves between defined operating states.

    localparam [1:0] IDLE     = 2'd0;
    localparam [1:0] HOLDING  = 2'd1;
    localparam [1:0] RELEASED = 2'd2;
    localparam [1:0] REFUNDED = 2'd3;

    reg [1:0] state_q;
    reg [2:0] approvals_q;

    // Counter width adapts to the selected timeout.
    localparam integer COUNTER_WIDTH =
        (TIMEOUT_CYCLES < 2) ? 1 : $clog2(TIMEOUT_CYCLES + 1);

    reg [COUNTER_WIDTH-1:0] timeout_count_q;

    // Sticky approvals: once received, an approval remains recorded.
    wire [2:0] approvals_next;

    assign approvals_next =
        approvals_q |
        {arbiter_approve, seller_approve, buyer_approve};

    // Majority logic: any two or more approvals.
    wire majority_next;

    assign majority_next =
        (approvals_next[0] & approvals_next[1]) |
        (approvals_next[0] & approvals_next[2]) |
        (approvals_next[1] & approvals_next[2]);

    // Outputs are decoded directly from the current state.
    assign release_to_seller = (state_q == RELEASED);
    assign refund_to_buyer   = (state_q == REFUNDED);
    assign busy              = (state_q == HOLDING);
    assign done              = (state_q == RELEASED) ||
                               (state_q == REFUNDED);

    // Sequential logic: updates on each rising clock edge.
    // Reset is synchronous and active-high.
    always @(posedge clk) begin

        if (rst) begin
            state_q         <= IDLE;
            approvals_q     <= 3'b000;
            timeout_count_q <= {COUNTER_WIDTH{1'b0}};
        end

        else begin

            case (state_q)

                IDLE: begin
                    approvals_q     <= 3'b000;
                    timeout_count_q <= {COUNTER_WIDTH{1'b0}};

                    if (start) begin
                        state_q         <= HOLDING;
                        approvals_q     <= 3'b000;
                        timeout_count_q <= {COUNTER_WIDTH{1'b0}};
                    end
                end

                HOLDING: begin

                    // Record approvals received on this clock edge.
                    approvals_q <= approvals_next;

                    // Two approvals take priority over timeout.
                    if (majority_next) begin
                        state_q <= RELEASED;
                    end

                    // The final allowed holding cycle has expired.
                    else if (timeout_count_q >= TIMEOUT_CYCLES - 1) begin
                        state_q <= REFUNDED;
                    end

                    else begin
                        timeout_count_q <= timeout_count_q + 1'b1;
                    end

                end

                RELEASED: begin
                    if (start) begin
                        state_q         <= HOLDING;
                        approvals_q     <= 3'b000;
                        timeout_count_q <= {COUNTER_WIDTH{1'b0}};
                    end
                end

                REFUNDED: begin
                    if (start) begin
                        state_q         <= HOLDING;
                        approvals_q     <= 3'b000;
                        timeout_count_q <= {COUNTER_WIDTH{1'b0}};
                    end
                end

                default: begin
                    state_q         <= IDLE;
                    approvals_q     <= 3'b000;
                    timeout_count_q <= {COUNTER_WIDTH{1'b0}};
                end

            endcase

        end

    end

endmodule
