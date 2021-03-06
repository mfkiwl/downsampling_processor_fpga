module uart_control(dram_data, dram_addr, write_done,
							in_Clock, rx_serial, ram_mode,
							retrieve_image, tx_serial, retrieve_done
							);

input in_Clock, rx_serial, ram_mode, retrieve_image;
output write_done, tx_serial, retrieve_done;
input wire[15:0] dram_addr;
inout wire[7:0] dram_data;

wire rx_tick_wire, tx_tick_wire, ram_write_enable, retrieve_enable;
wire[7:0] uart_to_writer_data, writer_to_ram_data;
wire[15:0] writer_to_ram_addr, retrive_to_ram_addr;
reg[15:0] mux_out;
wire Txclk_en, Rxclk_en;

parameter RX_MODE = 2'b00;
parameter IDLE = 2'b01;
parameter TX_MODE = 2'b10;

reg [1:0] STATE = 2'b00;

Data_Writer writer(.Rx_tick(rx_tick_wire), .Din(uart_to_writer_data),
								.Dout(writer_to_ram_data), .Addr(writer_to_ram_addr),
								.fin(write_done),
								.clk(clk), .Wen(ram_write_enable));

uart_rx reciever(.clk(clk), .i_Rx_Serial(rx_serial), .o_Rx_DV(rx_tick_wire),
						.o_Rx_Byte(uart_to_writer_data));
							
dram data_ram(.data(writer_to_ram_data),
					.address(mux_out), .q(dram_data),
					.clock(clk), .wren(ram_write_enable));
					
Data_retrieve retriever(.Start(retrieve_image), .Tx_tick(tx_tick_wire),
							.Wen(retrieve_enable), .Addr(retrive_to_ram_addr), .fin(retrieve_done));
							
uart_tx transmitter(.i_Clock(clk), .i_Tx_DV(retrieve_enable),
							.i_Tx_Byte(dram_data), .o_Tx_Serial(tx_serial), .o_Tx_Done(tx_tick_wire));
					
pll mypll(.inclk0(in_Clock), .c0(clk));

always @(posedge clk)
begin	
	case (STATE)
		RX_MODE:
		begin
			mux_out <= writer_to_ram_addr;
			if (write_done == 1'b1)
			begin
				STATE <= IDLE;
			end
		end
		IDLE:
		begin
			mux_out <= dram_addr;
			if (retrieve_image == 1'b0)
			begin
				STATE <= TX_MODE;
			end
		end
		TX_MODE:
		begin
			mux_out <= retrive_to_ram_addr;
		end
	endcase
			
end
							
endmodule
