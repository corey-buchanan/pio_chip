module test_wrapper(input clk, output reg [1:0] counter);
    initial begin
        counter = 0;
    end

    always @(posedge clk) begin
        counter <= counter + 1;
    end
endmodule
