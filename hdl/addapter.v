
//assumption:
//1. we assume that the SDA_i2c is stable at falling edge of scl and changes on rising edge
//

//status of the project:
//for now no burst mode in input

//possible problems to notice:
//can send ack and capture it as data in same sca posedge
//maybe should devide syncronius and ansyncronus if only the first is negedge sca all the other is posedge sca
//Procedural assignment statement cannot drive a net : SDA_i2c.

//To Do
//


`resetall
`timescale 1ns/10ps
module addapter#(parameter ADD_range=7,
				 parameter num_of_bytes_asked=3)
               (inout  wire                SDA_i2c,
                input  wire                SCL_i2c,
                input  wire                reset, //we defined reset as positive for functioning
                input  wire[ADD_range-1:0] CS_address,
                output wire MOSI_spi,
                input  wire  MISO_spi,
                output wire SCA_spi,
                output wire CS_spi);

//self parameter defenition


//regs of step 0: starting the communication
reg starting_communication; //this reg indicates when the communication starts: 0 is not and 1 starts capturing the address

//regs of step 1: capturing the addresss and the r/w  bit 
reg finished_address_capture; // this reg indicates when the first stage of the communication ends: 0 still capturing 1 finished the capture
reg[3:0] address_counter;// counts the number of bits gotten in the captor. 7 address + 1 W/R
reg [ADD_range:0] address_captor; //should get the address from the sda, note that address_captor[0] is W/R
wire trueAdd; //  output of the AND between address_captor[6:0] and CS_address to check if add captured is true
wire WriteorRead=address_captor[0]; //the last bit captured in this part is the write (0) or read (1) bit 

//regs for step ACK: when and what ack should be sent
reg send_ACK_step1; // this reg is 1 when the addapter needs to send an ACK to SDA_i2c
reg send_ACK_write; // this reg is 1 when the addapter needs to send an ACK to SDA_i2c
reg get_ACK_read; // this reg is 1 when the addapter expects to get an ACK to SDA_i2c
reg ACK_val;  // the value of the ack for sending
reg SDA_read; //this is the reg that is used to get data from the MISO_spi in a case of read transaction or the ack 

//regs for step 2: reading or writing data using SPI
reg[2:0] write_data_counter;// counts how much data did we write already in miso
reg[2:0] read_data_counter;// counts how much data did we write already in miso
reg finished_data_w_r;//this signify when to write/read a byte and when to ack
wire en_write;//this is the signal which transmite the data to mosi
wire en_read;

//regs for closing communication
reg maybe_closing;
reg flag;
reg[2:0] num_of_bytes;

//assigning wires
assign trueAdd= &(address_captor[ADD_range:1] ==  CS_address); //and gate that checks if the address captured is equal to the address goten from the user
assign SDA_i2c=SDA_read;//this assigns the data read to the SDA_i2c

assign en_read= trueAdd& WriteorRead & !finished_data_w_r & finished_address_capture  & &(num_of_bytes<num_of_bytes_asked);
//this is the enable for reading MISO->SDA. we need true address, being in read mode, finishing add capture, being in data section and not sending ack.
assign en_write= !finished_data_w_r & finished_address_capture & !send_ACK_step1 & trueAdd & !WriteorRead & &(num_of_bytes<num_of_bytes_asked);
//this is the enable for writing SDA->MOSI. analogical to en_read


assign SCA_spi=CS_spi ? SCL_i2c : 0;//enable for spi clock
assign CS_spi= (num_of_bytes_asked>num_of_bytes) ? (en_write & !send_ACK_write) || (en_read & !get_ACK_read):0;//enable for spi cs
assign MOSI_spi= en_write ?  SDA_i2c:1'bz; //enable for spi mosi

/////////////////////////////////////////////////////////////////////
///////////proccess for step 0: starting communication///////////////
/////////////////////////////////////////////////////////////////////

always @(negedge SDA_i2c, posedge reset) begin: capture_of_sda_i2c_starting
//the special signal of start communication of i2c is falling edge of the data line
// while the clock is possitive stable 
  if (reset==1) begin
    starting_communication = 1'b0;
  end
  else if ( SCL_i2c==1 && starting_communication == 0) begin //step 1. waiting to start interaction
    starting_communication = 1'b1;
    address_counter<=4'b1000; //this assigning of addresss_counter process is ok becouse its always in negedge so no dubble assigning
  end 
  // how to finish communication
  /*else if ( SCL_i2c==1 && starting_communication == 1 && finished_data_w_r == 1 && finished_address_capture==1  && send_ACK ==0) begin
    starting_communication <= 0;
    finished_data_w_r<= 0;
    finished_address_capture<= 0;
  end*/
end
/////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////
///proccess for step 1 of the communication: capturing the address///
/////////////////////////////////////////////////////////////////////
always @(posedge SCL_i2c, posedge reset) begin: capture_of_sda_i2c_addr
  if (reset==1) begin
    finished_address_capture = 1'b0;
    address_captor=8'h0;
    address_counter=4'b1000;
	send_ACK_step1=1'b0;
  end
  else if (starting_communication == 1'b1 && finished_address_capture==0) begin //step 2. caption of address and WriteorRead, sending Ack
    address_captor[address_counter] = SDA_i2c;
    if(address_counter==0) begin
      finished_address_capture = 1'b1;
	  send_ACK_step1=1'b1;
    end
    else address_counter=address_counter-1;
  end
  else if(send_ACK_step1 ==1) begin
    send_ACK_step1=0;
  end
  else if (finished_address_capture == 1 && send_ACK_step1 ==0 && trueAdd==0) begin//checking if trueadd is false and if ack sent already
    finished_address_capture = 1'b0;//back to address capture mode
    address_counter=4'b1000; //address not true trying to capture it again
  end//end of else if
end// end always captor
//////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////
///////process that manages the value of ACK//////////////////////////
//////////////////////////////////////////////////////////////////////
always @(posedge SCL_i2c, posedge reset ) begin: sending_ACD_in_sda_i2c
  if (reset==1) ACK_val=0;
  else if (send_ACK_step1==1 && trueAdd==1) ACK_val=1; 
  else if (send_ACK_write==1) ACK_val=1;
  else ACK_val=0;
end// end always send_ACK
//////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////
/////process that manages when to write and the value of SDA_i2c//////
//////////////////////////////////////////////////////////////////////
always @(posedge SCL_i2c, posedge reset ) begin: writing_to_sda_i2c
  if (reset==1) begin
   SDA_read=1'bz;     //when reset expecting to get info so inout HighZ by the side of the addapter
   read_data_counter= 3'b0;
 end
  else if(send_ACK_step1 || send_ACK_write)    SDA_read=ACK_val;  //first priority is sending ACK
  else if(en_read && !get_ACK_read) begin
    SDA_read=MISO_spi; //in case of reading starting to get info               
    if (read_data_counter==7) begin
      finished_data_w_r = 1'b1;
      read_data_counter=3'b0;
	  get_ACK_read=1;
	  num_of_bytes=num_of_bytes+1;
    end
    else begin
    read_data_counter= read_data_counter+1;
    end
  end
  else begin
	SDA_read=1'bz;     //in any other case expecting to get info so inout HighZ by the side of the addapter
	get_ACK_read=0;
  end
end
/////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////
///////////proccess for step 2: writing data to MOSI_spi//////////////
//////////////////////////////////////////////////////////////////////
always @(posedge SCL_i2c, posedge reset) begin: writing_to_mosi
  if (reset==1) begin 
    finished_data_w_r=0;
    write_data_counter=3'b0;
	num_of_bytes=3'b0;
  end
  else if (en_write) begin //
    if(write_data_counter==7) begin
      finished_data_w_r = 1'b1;
      write_data_counter =3'b0;
	  send_ACK_write=1;
	  num_of_bytes=num_of_bytes+1;
    end	
    else begin
      write_data_counter = write_data_counter+1;
    end
  end
  else if(num_of_bytes==num_of_bytes_asked) begin
	  starting_communication = 0;
	  finished_data_w_r= 0;
	  finished_address_capture= 0;
	  send_ACK_write=0;
	  //flag=1;
  end
  else begin 
	 send_ACK_write=0;
	 finished_data_w_r = 1'b0;
	end
end


//trying to captor the stop communication signal
//how?
//why is this if goes in even though SDA is rising
/*always @(posedge SCL_i2c, negedge SCL_i2c) begin 
	if (SCL_i2c==1 && SDA_i2c==0) begin//first step for closing sign
		maybe_closing=1'b1;
	end
	else
		maybe_closing=0;
end
always @(posedge SDA_i2c) begin 
	if(maybe_closing==1) begin
		starting_communication = 0;
		finished_data_w_r= 0;
		finished_address_capture= 0;
		flag=1;
	end
end
*/
endmodule