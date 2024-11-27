`resetall
`timescale 1ns/10ps

module addapter_TB;
parameter ADD_range=7;
parameter num_of_bytes=3;
logic reset;

initial begin: TOP_RST
	reset = 1'b0;
	#100;//creating rising edge
	reset = 1'b1; // Assert reset
	#100;//creating falling edge
	reset = 1'b0;
end
addapter_intf #(.ADD_range(ADD_range)) intf (.reset(reset));	
i2c_master_test #(.ADD_range(ADD_range)) master(.intf(intf));
spi_slave_test spi_slave(.intf(intf));
addapter #(.ADD_range(ADD_range), .num_of_bytes_asked(num_of_bytes))
			DUT (.SDA_i2c(intf.SDA_i2c), .SCL_i2c(intf.SCL_i2c),
                 .reset(reset), .CS_address(intf.CS_address), 
				 .MOSI_spi(intf.MOSI_spi), .MISO_spi(intf.MISO_spi),
				 .SCA_spi(intf.SCA_spi), .CS_spi(intf.CS_spi));

endmodule