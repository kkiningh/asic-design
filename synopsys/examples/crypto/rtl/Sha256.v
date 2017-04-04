`timescale 1ns / 1ps

module Sha256Round #(
    parameter STATE_SIZE   = 256
) (
    input clock, reset_n,

    input   wire [STATE_SIZE-1:0] hash_state_in,
    output  reg  [STATE_SIZE-1:0] hash_state_out
);
    /* Total number of compression iterations */
    localparam COMPRESS_ITERATIONS = 64;

    /* Constants defined by the SHA-2 standard */
	localparam Ks = {
		32'h428a2f98, 32'h71374491, 32'hb5c0fbcf, 32'he9b5dba5,
		32'h3956c25b, 32'h59f111f1, 32'h923f82a4, 32'hab1c5ed5,
		32'hd807aa98, 32'h12835b01, 32'h243185be, 32'h550c7dc3,
		32'h72be5d74, 32'h80deb1fe, 32'h9bdc06a7, 32'hc19bf174,
		32'he49b69c1, 32'hefbe4786, 32'h0fc19dc6, 32'h240ca1cc,
		32'h2de92c6f, 32'h4a7484aa, 32'h5cb0a9dc, 32'h76f988da,
		32'h983e5152, 32'ha831c66d, 32'hb00327c8, 32'hbf597fc7,
		32'hc6e00bf3, 32'hd5a79147, 32'h06ca6351, 32'h14292967,
		32'h27b70a85, 32'h2e1b2138, 32'h4d2c6dfc, 32'h53380d13,
		32'h650a7354, 32'h766a0abb, 32'h81c2c92e, 32'h92722c85,
		32'ha2bfe8a1, 32'ha81a664b, 32'hc24b8b70, 32'hc76c51a3,
		32'hd192e819, 32'hd6990624, 32'hf40e3585, 32'h106aa070,
		32'h19a4c116, 32'h1e376c08, 32'h2748774c, 32'h34b0bcb5,
		32'h391c0cb3, 32'h4ed8aa4a, 32'h5b9cca4f, 32'h682e6ff3,
		32'h748f82ee, 32'h78a5636f, 32'h84c87814, 32'h8cc70208,
		32'h90befffa, 32'ha4506ceb, 32'hbef9a3f7, 32'hc67178f2
    };

    /* Input message */
    localparam Ws = {
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000
    };

    genvar i;
    generate for (i = 0; i < COMPRESS_ITERATIONS; i = i + 1) begin : CompressLoop
        wire [STATE_SIZE-1:0] compress_state_in;
        wire [STATE_SIZE-1:0] compress_state_out;

        /* If it's the first iteration of the loop, we use the round input.
         * Otherwise, use the previous iteration's ouput
         */
        if (i == 0) begin
            assign compress_state_in = hash_state_in;
        end else begin
            assign compress_state_in = CompressLoop[i-1].compress_state_out;
        end

        Sha256Compress compress (
            .k_in(Ks[32*i +: 32]),
            .w_in(Ws[32*i +: 32]),
            .compress_state_in (compress_state_in),
            .compress_state_out(compress_state_out)
        );
    end endgenerate

    /* Latch the output of the last iteration */
    always @(posedge clock) begin
        if (reset_n) begin
            hash_state_out <=
                CompressLoop[COMPRESS_ITERATIONS-1].compress_state_out;
        end else begin
            hash_state_out <= {STATE_SIZE{1'b0}};
        end
    end
endmodule

module Sha256Compress #(
    parameter STATE_SIZE = 256
) (
    input   [STATE_SIZE/8-1:0] k_in,
    input   [STATE_SIZE/8-1:0] w_in,
    input   [STATE_SIZE  -1:0] compress_state_in,
    output  [STATE_SIZE  -1:0] compress_state_out
);
    wire [STATE_SIZE/8-1:0] a, b, c, d, e, f, g, h;
    wire [STATE_SIZE/8-1:0] s1, ch, t1, s0, mj, t2;

    assign {h, g, f, e, d, c, b, a} = compress_state_in;

    assign s1 = (e >> 6 | e << 26) ^ (e >> 11 | e << 21) ^ (e >> 25 | e << 7);
    assign ch = (e & f) ^ (~e & g);
    assign t1 = h + s1 + ch + k_in + w_in;
    assign s0 = (a >> 2 | a << 30) ^ (a >> 13 | a << 19) ^ (a >> 22 | a << 10);
    assign mj = (a & b) ^ (a & c) ^ (b & c);
    assign t2 = s0 + mj;

    assign compress_state_out = {g, f, e, d + t1, c, b, a, t1 + t2};
endmodule
