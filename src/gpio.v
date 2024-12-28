module gpio(
    input clk,
    input rst,
    input [31:0] out_data,
    input [31:0] sync_bypass, // TODO: Implement
    input [31:0] dir, // 0 = input, 1 = output
    input [31:0] pde, pue,
    output reg [31:0] in_data,
    inout [31:0] gpio
);

    // If pde and pue are set for a pin, neither will be applied
    // to prevent excess current draw. It might be a good idea to
    // raise an error signal if this occurs, but I'm not sure it's
    // needed.

    // Verilog won't let me define both pull-ups and pull-downs
    // on the same signals, but i've got replacement
    // logic for simulation, but it'll have to be fixed
    // prior to synthesis and the pull-ups/pull-downs added
    // to the physical layout.

    // pullup gpio_pullup (gpio);
    // pulldown gpio_pulldown (gpio);

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin
            assign gpio[i] = dir[i] ? out_data[i] :
                pde[i] & ~pue[i] ? 1'b0 :
                ~pde[i] & pue[i] ? 1'b1 : 1'bz;
        end
    endgenerate

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            in_data <= 32'b0;
        end else begin
            in_data <= (~dir & gpio);
        end
    end
    
endmodule
