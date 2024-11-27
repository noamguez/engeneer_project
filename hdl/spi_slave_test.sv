`resetall
`timescale 1ns/10ps
//modport SPISLAVE(output MISO_spi, input reset, MOSI_spi, SCA_spi, CS_spi);

module spi_slave_test#(parameter ADD_range=7)(addapter_intf.SPISLAVE intf) ;

//Whats the purpse of this module:
//to send miso that will be accurate to the actual slave project
// ### Please start your Verilog code here ### 
logic miso_reg;
assign intf.MISO_spi=miso_reg;
task send_pack(reg[23:0] pack); //one communication is 1B header 3B info
for (int i=3;i>0;i--) begin
	send_byte(pack[8*i-1 -:8]); 
	@(intf.CS_spi);
	end
endtask

task send_byte(reg[7:0] message);
	for(int i=7;i>=0; i--) begin
		@(posedge intf.SCA_spi);
		miso_reg=message[i];
	end
endtask
initial begin
	@(posedge intf.reset);
	@(negedge intf.reset);
	send_pack({12{2'b10}});
end
 
endmodule