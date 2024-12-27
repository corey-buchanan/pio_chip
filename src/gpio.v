module gpio(
    input [31:0] out_data,
    input [31:0] sync_bypass, // TODO: Implement
    input [31:0] dir, // 0 = input, 1 = output
    output reg [31:0] in_data,
    inout [31:0] gpio,

    assign gpio = dir ? out_data : 32'bz;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            in_data <= 32'b0;
        end else begin
            in_data <= (~dir & gpio)
        end
    end
);
    
endmodule