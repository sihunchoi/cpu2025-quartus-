// Testbench Manager
//
// Lets you:
// - print out to the simulation console
// - halt simulation, with an exit code
//
// Via an APB interface.
//
// It also has a read-only register with the values of some Verilog defines,
// e.g. FPGA, SIM, which allows software to ascertain which platform it is
// running on and act accordingly.
// (e.g. print to sim console in sim, print to UART on FPGA)

module tbman_apbs #(
	parameter STUB_UART = 0,
	parameter STUB_SPI = 0,
	parameter STUB_PWM = 0
) (
	input wire clk,
	input wire rst_n,

	// APB Port
	input wire apbs_sel,
	input wire apbs_enable,
	input wire apbs_write,
	input wire [15:0] apbs_addr,
	input wire [31:0] apbs_wdata,
	output wire [31:0] apbs_rdata,
	output wire apbs_ready,
	output wire apbs_slverr,

	// FIXME a proper system-level IRQ controller
	output wire [15:0] irq_force
);

wire [7:0]  print_o;
wire        print_wen;
wire [31:0] putint_o;
wire        putint_wen;
wire [31:0] exit_o;
wire        exit_wen;
wire        defines_sim;
wire        defines_fpga;

// wire [31:0] apbs_prdata_pre;
// 
// always @(posedge clk)
// begin
//   apbs_prdata <= apbs_prdata_pre;
// end

tbman_regs inst_tbman_regs
(
	.clk            (clk),
	.rst_n          (rst_n),
	.apbs_sel      (apbs_sel),
	.apbs_enable   (apbs_enable),
	.apbs_write    (apbs_write),
	.apbs_addr     (apbs_addr),
	.apbs_wdata    (apbs_wdata),
	.apbs_rdata    (apbs_rdata),
	.apbs_ready    (apbs_ready),
	.apbs_slverr   (apbs_slverr),
	.print_o        (print_o),
	.print_wen      (print_wen),
	.putint_o       (putint_o),
	.putint_wen     (putint_wen),
	.exit_o         (exit_o),
	.exit_wen       (exit_wen),
	.defines_sim_i  (defines_sim),
	.defines_fpga_i (defines_fpga),
	.stub_uart_i    (|STUB_UART),
	.stub_spi_i     (|STUB_SPI),
	.stub_pwm_i     (|STUB_PWM),
`ifdef SIM
	.irq_force_o    (irq_force)
`else
	.irq_force_o    (/* unused */)
`endif
);

`ifndef SIM
assign irq_force = 16'h0;
`endif

// Testbench only: sim print and sim exit

`ifdef SIM
reg [0:1023] print_str = 1024'h0;
integer print_ptr = 0;

integer cycle_count;

always @ (posedge clk or negedge rst_n)
	if (!rst_n)
		cycle_count <= 0;
	else
		cycle_count <= cycle_count + 1;

always @ (posedge clk) begin
	if (print_wen) begin
		if (print_o == "\n") begin
			$display("TBMAN: %s", print_str);
			print_str = 1024'h0;
			print_ptr = 0;
		end else begin
			print_str[print_ptr * 8 +: 8] = print_o;
			print_ptr = print_ptr + 1;
		end
	end
	if (putint_wen) begin
		$display("TBMAN: %h", putint_o);
	end
	if (exit_wen) begin
		$display("TBMAN: CPU requested termination, exit code %d", exit_o);
		$display("Design ran for %d cycles", cycle_count);
		$finish;
	end
end
`endif

`ifdef SIM
assign defines_sim = 1'b1;
`else
assign defines_sim = 1'b0;
`endif

`ifdef FPGA
assign defines_fpga = 1'b1;
`else
assign defines_fpga = 1'b0;
`endif

endmodule
