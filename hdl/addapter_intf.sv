`resetall
`timescale 1ns/10ps

interface addapter_intf#(parameter ADD_range=7)(input logic reset);

//I/O of the modules
wire                SDA_i2c;
wire                SCL_i2c;
wire[ADD_range-1:0] CS_address;
wire MOSI_spi;
wire MISO_spi;
wire SCA_spi;
wire CS_spi;

modport DEVICE (inout SDA_i2c,input SCL_i2c, reset, CS_address, MISO_spi, output MOSI_spi, SCA_spi, CS_spi);
modport I2CMASTER(inout SDA_i2c,input reset, output  SCL_i2c, CS_address);
modport SPISLAVE(output MISO_spi, input reset, MOSI_spi, SCA_spi, CS_spi);
endinterface