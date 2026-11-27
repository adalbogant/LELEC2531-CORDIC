
//=======================================================
//  MyARM
//=======================================================

module MyDE0_Nano(

//////////// CLOCK //////////
input logic 		          		CLOCK_50,

//////////// LED //////////
output logic		     [7:0]		LED,

//////////// KEY //////////
input logic 		     [1:0]		KEY,

//////////// SW //////////
input logic 		     [3:0]		SW,

//////////// SDRAM //////////
output logic		    [12:0]		DRAM_ADDR,
output logic		     [1:0]		DRAM_BA,
output logic		          		DRAM_CAS_N,
output logic		          		DRAM_CKE,
output logic		          		DRAM_CLK,
output logic		          		DRAM_CS_N,
inout logic 		    [15:0]		DRAM_DQ,
output logic		     [1:0]		DRAM_DQM,
output logic		          		DRAM_RAS_N,
output logic		          		DRAM_WE_N,

//////////// EPCS //////////
output logic		          		EPCS_ASDO,
input logic 		          		EPCS_DATA0,
output logic		          		EPCS_DCLK,
output logic		          		EPCS_NCSO,

//////////// Accelerometer and EEPROM //////////
output logic		          		G_SENSOR_CS_N,
input logic 		          		G_SENSOR_INT,
output logic		          		I2C_SCLK,
inout logic 		          		I2C_SDAT,

//////////// ADC //////////
output logic		          		ADC_CS_N,
output logic		          		ADC_SADDR,
output logic		          		ADC_SCLK,
input logic 		          		ADC_SDAT,

//////////// 2x13 GPIO Header //////////
inout logic 		    [12:0]		GPIO_2,
input logic 		     [2:0]		GPIO_2_IN,

//////////// GPIO_0, GPIO_0 connect to GPIO Default //////////
inout logic 		    [33:0]		GPIO_0_PI,
input logic 		     [1:0]		GPIO_0_PI_IN,

//////////// GPIO_1, GPIO_1 connect to GPIO Default //////////
inout logic 		    [33:0]		GPIO_1,
input logic 		     [1:0]		GPIO_1_IN
);			 

//=======================================================
//  MyARM
//=======================================================

	logic 		 	clk, reset;
   logic [31:0] 	WriteDataM, DataAdrM;
	logic 		 	MemWriteM;
	logic [31:0] 	PCF, InstrF, ReadDataM, ReadData_dmem, ReadData_spi;
	
	logic  			cs_dmem, cs_led, cs_spi, cs_cordic;
	logic [7:0] 	led_reg;
	logic [31:0]	spi_data;

	// CORDIC Inputs (written on clock edge based on WriteDataM, sequentially)
	logic 			cordic_start, cordic_mode;
	logic [1:0]		cordic_coord_syst;
	logic signed [31:0]	cordic_x_init, cordic_y_init, cordic_z_init; 

	// CORDIC Outputs
	logic 			cordic_done, cordic_done_status;	// cordic_done lasts only one cycle ; cordic_done_status is true until reset / restart
	logic signed [31:0]	cordic_x_out, cordic_y_out, cordic_z_out;
	
	assign clk   = CLOCK_50;
	assign reset = GPIO_0_PI[1];
  
	// Instantiate processor and memories
	arm arm(clk, reset, PCF, InstrF, MemWriteM, DataAdrM, WriteDataM, ReadDataM);
	imem imem(PCF, InstrF);
	dmem dmem(clk, cs_dmem, MemWriteM, DataAdrM, WriteDataM, ReadData_dmem);
	cordic cordic(
					clk, reset, cordic_start, 
				 	cordic_x_init, cordic_y_init, cordic_z_init, 
					cordic_mode, 
					cordic_coord_syst, 
					cordic_x_out, cordic_y_out, cordic_z_out,
					cordic_done
	);
	
	// Chip Select logic
	
	// Address MAP : 0x0000 - 0x03FF : RAM (255 words of 32 bits)
   	//               0x0400 - 0x043F : SPI - 16 reg. of 32 bits
  	//               0x0500 :        : LED Reg
   	// 				 0x0600          : CORDIC accelerator
	
	/* MAPPING CORDIC
	‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
	 0x0600 : Configuration & Control : bit 25:24 = coord_system ; bit 16 = mode ; bit 0 = start (when reading) and done (when writing)
	 0x0604 : x_init
	 0x0608 : y_init
	 0x060C : z_init
	 0x0610 : x_out
	 0x0614 : y_out
	 0x0618 : z_out
	________________________________________________________ */


	assign cs_dmem   = ~DataAdrM[11] & ~DataAdrM[10];											// 0x-0-- to 0x-3--
	assign cs_spi    = ~DataAdrM[11] &  DataAdrM[10] & ~DataAdrM[9] & ~DataAdrM[8];	// 0x-4--
	assign cs_led    = ~DataAdrM[11] &  DataAdrM[10] & ~DataAdrM[9] &  DataAdrM[8];	// 0x-5--
	assign cs_cordic = ~DataAdrM[11] &  DataAdrM[10] &  DataAdrM[9] & ~DataAdrM[8]; // 0x-6--
	
	// Read Data (from external source (DMEM, SPI, CORDIC) to ARM processor)
	always_comb
		if (cs_dmem) ReadDataM = ReadData_dmem;
		else if (cs_spi) ReadDataM = spi_data;
		else if (cs_led) ReadDataM = {24'h000000, led_reg};
		else if (cs_cordic) begin
			case (DataAdrM[7:0])
				8'h00: ReadDataM = {
					6'b0, cordic_coord_syst,	// Bit [31:24] : 000000{coord_syst[1:0]}
					7'b0, cordic_mode,			// Bit [23:16] : 0000000{mode[0]}
					8'b0,						// Bit [15:8] : 0000000
					7'b0, cordic_done_status	// Bit [7:0] : 0000000{cordic_done_status}
				};
				8'h10: ReadDataM = cordic_x_out;
				8'h14: ReadDataM = cordic_y_out;
				8'h18: ReadDataM = cordic_z_out;
				default: ReadDataM = 32'b0;
			endcase
		end
		else ReadDataM = 32'b0;
	
	// LED logic	
	assign LED = led_reg;	
	always_ff @(posedge clk)
    	if (MemWriteM & cs_led) led_reg <= WriteDataM[7:0];
	
	// CORDIC Write (from ARM Processor / SPI to CORDIC arguments)
	always_ff @(posedge clk) begin
		if (reset) begin
			cordic_start <= 0;
			cordic_mode <= 0;
			cordic_coord_syst <= 0;
			cordic_x_init <= 0;
			cordic_y_init <= 0;
			cordic_z_init <= 0;
			// cordic_done <= 0; TODO : remove ?
			cordic_done_status <= 0;
		end
		else if (MemWriteM & cs_cordic) begin
			case (DataAdrM[7:0])
				8'h00: begin
					   cordic_start <= WriteDataM[0];
					   cordic_mode <= WriteDataM[16];
					   cordic_coord_syst <= WriteDataM[25:24];
					   if (WriteDataM[0])
					   		cordic_done_status <= 1'b0;		// When the computation start, we reset the done status
				end
				8'h04: cordic_x_init <= WriteDataM;
				8'h08: cordic_y_init <= WriteDataM;
				8'h0C: cordic_z_init <= WriteDataM;
			endcase
		end
		else if (cordic_done)
			cordic_done_status <= 1'b1;
		else
			cordic_start <= 1'b0;	// Do not retrigger the start
	end

	// Testbench
	assign GPIO_1[33]    = MemWriteM;
	assign GPIO_1[15:0]  = WriteDataM[15:0];
	assign GPIO_1[31:16] = ReadDataM[15:0];
	assign GPIO_2[12:0]  = DataAdrM[12:0];

//=======================================================
//  SPI
//=======================================================

	logic 			spi_clk, spi_cs, spi_mosi, spi_miso;

	spi_slave spi_slave_instance(
		.SPI_CLK    (spi_clk),
		.SPI_CS     (spi_cs),
		.SPI_MOSI   (spi_mosi),
		.SPI_MISO   (spi_miso),
		.Data_WE    (MemWriteM & cs_spi),
		.Data_Addr  (DataAdrM),
		.Data_Write (WriteDataM),
		.Data_Read  (spi_data),
		.Clk        (clk)
	);
	
	assign spi_clk  		= GPIO_0_PI[11];	// SCLK = pin 16 = GPIO_11
	assign spi_cs   		= GPIO_0_PI[9];	// CE0  = pin 14 = GPIO_9
	assign spi_mosi     	= GPIO_0_PI[15];	// MOSI = pin 20 = GPIO_15
	
	assign GPIO_0_PI[13] = spi_cs ? 1'bz : spi_miso;  // MISO = pin 18 = GPIO_13
	
endmodule

//=======================================================
//  Memory
//=======================================================	

module dmem(input logic clk, we, cs,
				input logic [31:0] a, wd,
            output logic [31:0] rd);
				
  logic [31:0] RAM[255:0];
    
assign rd = RAM[a[31:2]]; // word aligned

always_ff @(posedge clk)
    if (cs & we) RAM[a[31:2]] <= wd;
endmodule

module imem(input  logic [31:0] a,
            output logic [31:0] rd);
				
  logic [31:0] RAM[255:0];
  
initial $readmemh("MyProgram_Pipelined.hex",RAM);
assign rd = RAM[a[31:2]]; // word aligned

endmodule


