`timescale 1ns/1ps

interface PMA_i (input bit clock, ref logic reset_n);
    parameter OUTPUT_SKEW = 1;

    /* Non-global signals for the DUT */
    logic signed [31:0] a_in, b_in, c_in;
    logic               valid_in;
    logic signed [63:0] mac_out;
    logic               valid_out;

    /* Clocking block describes how signals are syncronized to the clock.
     * For example, the DUT inputs should only change slightly after the posedge
     * and DUT outputs should be sampled just before the clock edge.
     * Using a clocking block makes it easy to enforces this behavior.
     * See http://www.verilab.com/files/paper51_taming_tb_timing_FINAL_fixes.pdf
     */
    clocking drv_cb @(posedge clock);
        default input #1step output #OUTPUT_SKEW;
        output a_in, b_in, c_in, valid_in;
        input  mac_out, valid_out;
    endclocking

    default clocking mon_cb @(posedge clock);
        default input #1step;
        input a_in, b_in, c_in, valid_in, mac_out, valid_out;
    endclocking

    /* A modport allows us to expose multiple ways of interacting with the
     * interface in our testbench. For example, a driver may want to be able
     * to read and write multiple signals, where as a monitor may only want
     * to read all of them. In order to support multiple types of
     * functionality, we declare each "type" as a modport.
     */
    modport master  (clocking drv_cb, output reset_n);
    modport monitor (clocking mon_cb, output reset_n);
endinterface : PMA_i

typedef virtual PMA_i.master PMA_master_vi;
typedef virtual PMA_i.monitor PMA_monitor_vi;

typedef struct {
    bit signed [31:0] a, b, c;
} packet_t;

class Driver #(
    parameter STAGES = 3
);
    PMA_master_vi pma_vi;

    function new(PMA_master_vi pma_vi);
        this.pma_vi = pma_vi;
    endfunction

    task wait_clocks(input integer N = 1);
        if (N < 0) N = 0;
        repeat(N) @pma_vi.drv_cb;
    endtask

    task send(packet_t packet, bit valid);
        pma_vi.drv_cb.a_in     <= packet.a;
        pma_vi.drv_cb.b_in     <= packet.b;
        pma_vi.drv_cb.c_in     <= packet.c;
        pma_vi.drv_cb.valid_in <= valid;
    endtask

    task try_get_next(ref packet_t packet, ref bit valid);
        std::randomize(packet);
        std::randomize(valid);
    endtask

    task reset(bit reset = 1);
        pma_vi.reset_n <= ~reset;
    endtask

    task setup();
        send('{default:'0}, 0);
        reset(1);
        wait_clocks(1);
        reset(0);
    endtask

    task run();
        packet_t packet;
        bit      valid;
        repeat(30) begin
            wait_clocks(1);

            /* Get a new packet to send */
            try_get_next(packet, valid);

            /* Send the actual packet */
            send(packet, valid);
        end

        /* Stop sending new packets */
        send('{default:'0}, 0);

        /* Wait for the pipeline to drain */
        wait_clocks(STAGES + 1);
    endtask

    task teardown();
        wait_clocks(2); // Makes signals easier to read in DVE
    endtask

endclass

class Scoreboard;
    packet_t          packet_queue[$];
    bit signed [63:0] result_queue[$];
    int num_errors;

    function new();
        num_errors = 0;
    endfunction

    task write_packet(packet_t packet);
        packet_queue.push_back(packet);
        check();
    endtask

    task write_result(bit signed [63:0] result);
        result_queue.push_back(result);
        check();
    endtask

    task check();
        packet_t          packet;
        bit signed [63:0] result;


        if (packet_queue.size() && result_queue.size()) begin
            packet = packet_queue.pop_front();
            result = result_queue.pop_front();

            if (result == packet.a * packet.b + packet.c) begin
                $display("Passed %d * %d + %d = %d",
                    packet.a,
                    packet.b,
                    packet.c,
                    result
                );
            end else begin
                $display("Failed");
                num_errors++;
            end
        end
    endtask

    task finalize();
        if (packet_queue.size() != 0) begin
            $display("error - packet_queue is not empty! (%d outstanding)",
                packet_queue.size()
            );
        end
        if (result_queue.size() != 0) begin
            $display("error - result_queue is not empty! (%d outstanding)",
                result_queue.size()
            );
        end

        $display("==============");
        if (num_errors == 0) begin
            $display("FINAL: 0 Errors - All tests passed");
        end else begin
            $display("FINAL: %d Errors - Testing failed!", num_errors);
        end
    endtask
endclass

class Monitor #(
    parameter STAGES = 3
);
    PMA_monitor_vi pma_vi;
    Scoreboard sb;

    function new(PMA_monitor_vi pma_vi, Scoreboard sb);
        this.pma_vi = pma_vi;
        this.sb     = sb;
    endfunction

    task run();
        forever begin
            @(pma_vi.mon_cb) begin
                if (pma_vi.mon_cb.valid_in) begin
                    sb.write_packet('{
                        a: pma_vi.mon_cb.a_in,
                        b: pma_vi.mon_cb.b_in,
                        c: pma_vi.mon_cb.c_in
                    });
                end

                if (pma_vi.mon_cb.valid_out) begin
                    sb.write_result(
                        pma_vi.mon_cb.mac_out
                    );
                end
            end
        end
    endtask
endclass

task run_test(Driver driver, Monitor monitor, Scoreboard sb);
    /* Setup the test */
    driver.setup();

    /* Spawn a single process for our test loop */
    fork begin
        /* Run each component in parallel */
        fork
            driver.run();
            monitor.run();
        join_any

        /* Kill the fork once any of the components die */
        disable fork;
    end join

    /* Finish up */
    driver.teardown();
    sb.finalize();
    $finish();
endtask

module tb;
    /* Setup clock */
    reg clock = 0, reset_n;
    always begin
        #5 clock = 1;
        #5 clock = 0;
    end

    /* Device under test */
    localparam STAGES = 3;
    PMA_i pma (.clock, .reset_n);

    PipelinedMultiplyAccumulate #(
        .STAGES(STAGES)
    ) dut (
        .clock    (pma.clock),
        .reset_n  (pma.reset_n),
        .a_in     (pma.a_in),
        .b_in     (pma.b_in),
        .c_in     (pma.c_in),
        .valid_in (pma.valid_in),
        .mac_out  (pma.mac_out),
        .valid_out(pma.valid_out)
    );

    Driver #(
        .STAGES(STAGES)
    ) driver = new(pma.master);

    Scoreboard sb = new();

    Monitor #(
        .STAGES(STAGES)
    ) monitor = new(pma.monitor, sb);

    /* Run the tests */
    initial run_test(driver, monitor, sb);

    initial begin
        $vcdplusfile("dump.vpd");
        $vcdpluson();
    end
endmodule
