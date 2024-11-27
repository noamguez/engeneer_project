`resetall
`timescale 1ns/10ps

//modport I2CMASTER(inout SDA_i2c,input reset, output  SCL_i2c, CS_address);
module i2c_master_test #(parameter ADD_range=7)(addapter_intf.I2CMASTER intf);

//inner signals of the stimulus
reg SDA_generator;
wire SDA_receiver;
reg  SCL_i2c;
reg[6:0] CS_address;

logic start_clk;//signals for signing to start generating the clk
logic stop_clk;
logic write_read;//this bit represent if were tring to write 0 or read 1
logic[7:0] byte_sent;//this is the byte the master trys to send_byte
logic[31:0] pack;//one pack of communication
logic[23:0] word_get;
//assigning the signals to and from the interface of the tb
assign intf.SCL_i2c=SCL_i2c;
assign intf.CS_address=CS_address;

//assigning the duality of the inout SDA signal
assign intf.SDA_i2c=SDA_generator;
assign SDA_receiver=intf.SDA_i2c;

//basic i2c communication///////////
task begin_communication();//this is the classic way to sign the slave in i2c that were starting communication
	#10;
	SDA_generator=0;//signing to the slave starting the communication
	#10;
	start_clk=1;
endtask

task end_communication();
	@(negedge SCL_i2c);
	@(posedge SCL_i2c);
	SDA_generator=0;
	stop_clk=1;
	@(!start_clk);
	#10;
	SDA_generator=1;
	#10;
	stop_clk=0;
endtask;
/////////////////////////////////

 
//tasks for write////////////////
 
task send_byte(reg[7:0] message);
	for(int i=7;i>=0; i--) begin
		@(posedge SCL_i2c);
		SDA_generator=message[i];
	end
endtask

task get_ack(output logic ack);
	@(posedge SCL_i2c);
	SDA_generator=1'bz;
	#10;
	wait( SDA_receiver == 1'b0 || SDA_receiver == 1'b1);
	ack=SDA_receiver; 

endtask


task transmit(reg[7:0] message);
	logic ack;
	send_byte(message);
	get_ack(ack);
	while(ack==0) begin
		send_byte(message);
		get_ack(ack);
	end
endtask

task send_pack(reg[31:0] pack); //one communication is 1B header 3B info
for (int i=4;i>=1;i--) transmit(pack[8*i-1 -:8]); 
endtask

//////////////////////////////

//tasks for read//////////////

task get_byte(output logic[7:0] byte_get);
	SDA_generator=1'bz;
	//@(posedge SCL_i2c);
	for (int i=7;i>0;i--) begin
		
		byte_get[i]= SDA_receiver;
		@(posedge SCL_i2c);
	end
	byte_get[0]= SDA_receiver;
	
endtask

task send_ack(input logic[7:0] byte_get);
	logic ack_send;
	if ((&(byte_get))== 1'bx) ack_send=0;
	else ack_send=1;
	//@(posedge SCL_i2c);
	
	SDA_generator=ack_send;
	@(posedge SCL_i2c);
	SDA_generator=1'bz;
endtask

task read_word(output logic[23:0] word);
	@(posedge SCL_i2c);
	for(int i=3;i>0;i--) begin
		get_byte(word[i*8-1-:8]);
		//@(posedge SCL_i2c);
		send_ack(word[i*8-1-:8]);
		
		@(posedge SCL_i2c);
	end
	SDA_generator=1'bz;
endtask
//////////////////////////////


//initials of simulation//////

initial forever begin: reset
	@(posedge intf.reset);
	SDA_generator = 1;
    SCL_i2c = 1;
    CS_address = 7'b1000101;//random for testing
	stop_clk=0;
	start_clk=0;
end	
	
initial forever begin: clock_generator //process for generating and stopping the clock
	@(posedge start_clk);
	while (!stop_clk) begin
		SCL_i2c=~SCL_i2c;
		#50;
	end
	SCL_i2c=1;
	start_clk=0;
end

initial begin: master
	@(posedge intf.reset);
	@(negedge intf.reset);
    #20;
    begin_communication();
	write_read=1;
	byte_sent={CS_address , write_read};//the last bit is w/r 0/1 
	//pack={{byte_sent,24'H3ABCDE}};
	//send_pack(pack);
	transmit(byte_sent);
	@(posedge SCL_i2c);
	read_word(word_get);
	@(posedge SCL_i2c);@(posedge SCL_i2c);@(posedge SCL_i2c);@(posedge SCL_i2c);
	end_communication();
end 
///////////////////////////////

endmodule