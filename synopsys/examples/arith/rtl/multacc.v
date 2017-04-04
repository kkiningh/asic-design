module PipelinedMultiplyAccumulate #(
    parameter STAGES      = 2,
    parameter INPUT_SIZE  = 32,
    parameter OUTPUT_SIZE = INPUT_SIZE * 2
) (
    input clock,
    input reset_n,

    input signed  [INPUT_SIZE-1:0] a_in,
    input signed  [INPUT_SIZE-1:0] b_in,
    input signed  [INPUT_SIZE-1:0] c_in,
    input                          valid_in,

    output signed [OUTPUT_SIZE-1:0] mac_out,
    output                          valid_out
);
    /* Actual Sum */
    wire signed [OUTPUT_SIZE-1:0] mac = a_in * b_in + c_in;

    /* Pipeline Stages */
    genvar i;
    generate for (i = 0; i < STAGES; i = i + 1) begin : PipelineStage
        reg signed [OUTPUT_SIZE-1:0] state;
        reg                          valid;

        if (i == 0) begin : First
            /* Need to special case first iteration of the loop */
            always @(posedge clock) begin
                if (reset_n) begin
                    state <= mac;
                    valid <= valid_in;
                end else begin
                    state <= {OUTPUT_SIZE{1'b0}};
                    valid <= 1'b0;
                end
            end
        end else begin : Rest
            /* Common case */
            always @(posedge clock) begin
                if (reset_n) begin
                    state <= PipelineStage[i-1].state;
                    valid <= PipelineStage[i-1].valid;
                end else begin
                    state <= {OUTPUT_SIZE{1'b0}};
                    valid <= 1'b0;
                end
            end
        end
    end endgenerate

    /* Final stage is output */
    assign mac_out   = PipelineStage[STAGES-1].state;
    assign valid_out = PipelineStage[STAGES-1].valid;
endmodule
