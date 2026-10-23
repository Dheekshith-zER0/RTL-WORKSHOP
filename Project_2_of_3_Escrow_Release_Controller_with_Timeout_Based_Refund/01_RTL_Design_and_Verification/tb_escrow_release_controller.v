`timescale 1ns/1ps

module tb_escrow_release_controller;

    parameter integer TIMEOUT_CYCLES = 4;

    reg clk;
    reg rst;
    reg start;

    reg buyer_approve;
    reg seller_approve;
    reg arbiter_approve;

    wire release_to_seller;
    wire refund_to_buyer;
    wire busy;
    wire done;

    integer i;

    // Device Under Test (DUT): the controller being tested.
    escrow_release_controller #(
        .TIMEOUT_CYCLES(TIMEOUT_CYCLES)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .buyer_approve(buyer_approve),
        .seller_approve(seller_approve),
        .arbiter_approve(arbiter_approve),
        .release_to_seller(release_to_seller),
        .refund_to_buyer(refund_to_buyer),
        .busy(busy),
        .done(done)
    );

    // Generate a clock with a 10 ns period.
    always #5 clk = ~clk;

    // Apply a start pulse.
    task start_transaction;
        begin
            @(negedge clk);
            start = 1'b1;

            @(posedge clk);
            #1;
            start = 1'b0;
        end
    endtask

    // Apply one approval pulse.
    task approve_buyer;
        begin
            @(negedge clk);
            buyer_approve = 1'b1;

            @(posedge clk);
            #1;
            buyer_approve = 1'b0;
        end
    endtask

    task approve_seller;
        begin
            @(negedge clk);
            seller_approve = 1'b1;

            @(posedge clk);
            #1;
            seller_approve = 1'b0;
        end
    endtask

    task approve_arbiter;
        begin
            @(negedge clk);
            arbiter_approve = 1'b1;

            @(posedge clk);
            #1;
            arbiter_approve = 1'b0;
        end
    endtask

    // Check that the controller released the escrow.
    task check_release;
        begin
            if (release_to_seller !== 1'b1 ||
                refund_to_buyer !== 1'b0 ||
                busy !== 1'b0 ||
                done !== 1'b1) begin

                $display("FAIL: Release output check");
                $fatal(1);
            end

            $display("PASS: Release authorized");
        end
    endtask

    // Check that the controller refunded the escrow.
    task check_refund;
        begin
            if (refund_to_buyer !== 1'b1 ||
                release_to_seller !== 1'b0 ||
                busy !== 1'b0 ||
                done !== 1'b1) begin

                $display("FAIL: Refund output check");
                $fatal(1);
            end

            $display("PASS: Refund authorized");
        end
    endtask

    initial begin

        clk = 1'b0;
        rst = 1'b1;
        start = 1'b0;

        buyer_approve = 1'b0;
        seller_approve = 1'b0;
        arbiter_approve = 1'b0;

        // TEST 1: Reset.
        repeat (2) @(posedge clk);
        #1;

        if (busy !== 1'b0 || done !== 1'b0) begin
            $display("FAIL: Reset");
            $fatal(1);
        end

        @(negedge clk);
        rst = 1'b0;

        $display("PASS: Reset");

        // TEST 2: Two approvals release the escrow.
        start_transaction;

        if (busy !== 1'b1) begin
            $display("FAIL: Transaction start");
            $fatal(1);
        end

        approve_buyer;
        approve_arbiter;

        check_release;

        // TEST 3: Restart after release, then timeout.
        start_transaction;

        if (busy !== 1'b1 ||
            release_to_seller !== 1'b0 ||
            refund_to_buyer !== 1'b0) begin

            $display("FAIL: Restart after release");
            $fatal(1);
        end

        repeat (TIMEOUT_CYCLES) begin
            @(posedge clk);
            #1;
        end

        check_refund;

        // TEST 4: Second approval on the timeout boundary
        // must win over the timeout.
        start_transaction;

        approve_buyer;

        repeat (TIMEOUT_CYCLES - 2) begin
            @(posedge clk);
            #1;
        end

        approve_seller;

        check_release;

        // TEST 5: Reset cancels an active transaction.
        start_transaction;

        @(negedge clk);
        rst = 1'b1;

        @(posedge clk);
        #1;

        if (busy !== 1'b0 ||
            done !== 1'b0 ||
            release_to_seller !== 1'b0 ||
            refund_to_buyer !== 1'b0) begin

            $display("FAIL: Reset during transaction");
            $fatal(1);
        end

        @(negedge clk);
        rst = 1'b0;

        $display("PASS: Reset cancels active transaction");

        $display("--------------------------------");
        $display("ALL TESTS PASSED");
        $display("--------------------------------");

        $finish;
    end

endmodule
