module BlueToothController #(
	parameter		// config enable
					CONFIG_EN							=	1,		// do not enable config
					// config
					CLK_FRE								=	50,		// 50MHz
					BAUD_RATE							=	9600,	// 9600Hz (4800, 19200, 38400, 57600, 115200, 38400...)
					STOP_BIT							=	0,		// 0 : 1-bit stop-bit, 1 : 2-bit stop-bit
					CHECK_BIT							=	0,		// 0 : no check-bit, 1 : odd, 2 : even
					// default	9600	0	0
					// granularity
					REQUEST_FIFO_DATA_WIDTH				=	8,		// the bit width of data we stored in the FIFO
					REQUEST_FIFO_DATA_DEPTH_INDEX		=	5,		// the index_width of data unit(reg [DATA_WIDTH - 1:0])
					RESPONSE_FIFO_DATA_WIDTH			=	8,		// the bit width of data we stored in the FIFO
					RESPONSE_FIFO_DATA_DEPTH_INDEX		=	5		// the index_width of data unit(reg [DATA_WIDTH - 1:0])
) (
	input												clk,
	input												rst_n,

	// BlueTooth_Config
	input												BlueTooth_State,
	output												BlueTooth_Key,
	output												BlueTooth_Rxd,
	input												BlueTooth_Txd,

	// request FIFO signals
	input		[REQUEST_FIFO_DATA_WIDTH - 1:0]			BlueTooth_request_FIFO_data_i,
	input												BlueTooth_request_FIFO_data_i_vld,
	output												BlueTooth_request_FIFO_data_i_rdy,
	// for debug
	output												BlueTooth_request_FIFO_full,
	output												BlueTooth_request_FIFO_empty,
	output		[REQUEST_FIFO_DATA_DEPTH_INDEX - 1:0]	BlueTooth_request_FIFO_surplus,

	// response FIFO signals
	input												BlueTooth_response_FIFO_r_en,
	output		[RESPONSE_FIFO_DATA_WIDTH - 1:0]		BlueTooth_response_FIFO_data_o,
	output												BlueTooth_response_FIFO_data_o_vld,
	// for debug
	output												BlueTooth_response_FIFO_full,
	output												BlueTooth_response_FIFO_empty,
	output		[RESPONSE_FIFO_DATA_DEPTH_INDEX - 1:0]	BlueTooth_response_FIFO_surplus
);

	wire BlueTooth_init_flag, BlueToothInitializer_init_flag, BlueToothInitializer_Key;
	generate
		begin
		if (CONFIG_EN)
			begin
			// BlueToothInitializer
			BlueToothInitializer #(
			) m_BlueToothInitializer (
				.clk								(clk							),
				.rst_n								(rst_n							),

				.BlueToothInitializer_init_flag		(BlueToothInitializer_init_flag	),
				.BlueToothInitializer_Key			(BlueToothInitializer_Key		)
			);
			end
		end
	endgenerate
	assign BlueTooth_init_flag = CONFIG_EN ? BlueToothInitializer_init_flag : 1'b1;
	assign BlueTooth_Key = CONFIG_EN ? BlueToothInitializer_Key : 1'b0;

	localparam			RX_IDLE		=	2'b00,
						RX_WRDATA	=	2'b01,
						RX_END		=	2'b10,
						TX_IDLE		=	2'b00,
						TX_RDDATA	=	2'b01,
						TX_TRANSMIT	=	2'b10,
						TX_WAIT		=	2'b11;

	// request FIFO signals
	reg BlueTooth_request_FIFO_r_en;
	wire BlueTooth_request_FIFO_data_o_vld;
	wire [RESPONSE_FIFO_DATA_WIDTH - 1:0] BlueTooth_request_FIFO_data_o;

	// response FIFO signals
	wire BlueTooth_response_FIFO_data_i_rdy;
	reg BlueTooth_response_FIFO_data_i_vld;
	reg [RESPONSE_FIFO_DATA_WIDTH - 1:0] BlueTooth_response_FIFO_data_i;

	// uart_controller8bit signals
	wire BlueTooth_tx_rdy, BlueTooth_rx_rdy;
	reg BlueTooth_tx_vld, BlueTooth_rx_ack;
	wire [7:0] BlueTooth_rx_data;
	reg [7:0] BlueTooth_tx_data;

	// receive response(RX)
	reg [1:0] BlueTooth_rx_state;
	always@ (posedge clk)
		begin
		if (!rst_n)
			begin
			// state
			BlueTooth_rx_state <= RX_IDLE;
			// response FIFO signals
			BlueTooth_response_FIFO_data_i_vld <= 1'b0;
			BlueTooth_response_FIFO_data_i <= {RESPONSE_FIFO_DATA_WIDTH{1'b0}};
			// uart_controller8bit signals
			BlueTooth_rx_ack <= 1'b0;
			end
		else
			begin
			case (BlueTooth_rx_state)
				RX_IDLE:
					begin
					if (BlueTooth_rx_rdy)							// receive data
						begin
						// state
						BlueTooth_rx_state <= RX_WRDATA;
						// response FIFO signals
						BlueTooth_response_FIFO_data_i_vld <= 1'b1;
						BlueTooth_response_FIFO_data_i <= BlueTooth_rx_data;
						// uart_controller8bit signals
						BlueTooth_rx_ack <= 1'b0;
						end
					else
						begin
						// state
						BlueTooth_rx_state <= RX_IDLE;
						// response FIFO signals
						BlueTooth_response_FIFO_data_i_vld <= 1'b0;
						BlueTooth_response_FIFO_data_i <= {RESPONSE_FIFO_DATA_WIDTH{1'b0}};
						// uart_controller8bit signals
						BlueTooth_rx_ack <= 1'b0;
						end
					end
				RX_WRDATA:
					begin
					// response FIFO signals
					BlueTooth_response_FIFO_data_i_vld <= 1'b0;
					BlueTooth_response_FIFO_data_i <= {RESPONSE_FIFO_DATA_WIDTH{1'b0}};
					if (BlueTooth_response_FIFO_data_i_rdy)			// data is accepted by FIFO
						begin
						// state
						BlueTooth_rx_state <= RX_END;
						// uart_controller8bit signals
						BlueTooth_rx_ack <= 1'b1;
						end
					else
						begin
						// uart_controller8bit signals
						BlueTooth_rx_ack <= 1'b0;
						end
					end
				RX_END:
					begin
					// state
					BlueTooth_rx_state <= RX_IDLE;
					// response FIFO signals
					BlueTooth_response_FIFO_data_i_vld <= 1'b0;
					BlueTooth_response_FIFO_data_i <= {RESPONSE_FIFO_DATA_WIDTH{1'b0}};
					// uart_controller8bit signals
					BlueTooth_rx_ack <= 1'b0;
					end
				default:
					begin
					// state
					BlueTooth_rx_state <= RX_IDLE;
					// response FIFO signals
					BlueTooth_response_FIFO_data_i_vld <= 1'b0;
					BlueTooth_response_FIFO_data_i <= {RESPONSE_FIFO_DATA_WIDTH{1'b0}};
					// uart_controller8bit signals
					BlueTooth_rx_ack <= 1'b0;
					end
			endcase
			end
		end

	// send request(TX)
	reg [1:0] BlueTooth_tx_state;
	always@ (posedge clk)
		begin
		if (!rst_n)
			begin
			// state
			BlueTooth_tx_state <= TX_IDLE;
			// request FIFO signals
			BlueTooth_request_FIFO_r_en <= 1'b0;
			// uart_controller8bit signals
			BlueTooth_tx_vld <= 1'b0;
			BlueTooth_tx_data <= 8'b0;
			end
		else
			begin
			case (BlueTooth_tx_state)
				TX_IDLE:
					begin
					if (!BlueTooth_request_FIFO_empty)			// request FIFO is not empty
						begin
						// state
						BlueTooth_tx_state <= TX_RDDATA;
						// request FIFO signals
						BlueTooth_request_FIFO_r_en <= 1'b1;
						// uart_controller8bit signals
						BlueTooth_tx_vld <= 1'b0;
						BlueTooth_tx_data <= 8'b0;
						end
					else
						begin
						// state
						BlueTooth_tx_state <= TX_IDLE;
						// request FIFO signals
						BlueTooth_request_FIFO_r_en <= 1'b0;
						// uart_controller8bit signals
						BlueTooth_tx_vld <= 1'b0;
						BlueTooth_tx_data <= 8'b0;
						end
					end
				TX_RDDATA:											// at the same posedge clk, FIFO is reading data
					begin
					// state
					BlueTooth_tx_state <= TX_TRANSMIT;
					// request FIFO signals
					BlueTooth_request_FIFO_r_en <= 1'b0;
					// uart_controller8bit signals
					BlueTooth_tx_vld <= 1'b0;
					BlueTooth_tx_data <= 8'b0;
					end
				TX_TRANSMIT:
					begin
					// request FIFO signals
					BlueTooth_request_FIFO_r_en <= 1'b0;
					if (BlueTooth_request_FIFO_data_o_vld)			// data is valid
						begin
						// state
						BlueTooth_tx_state <= TX_WAIT;
						// uart_controller8bit signals
						BlueTooth_tx_vld <= 1'b1;
						BlueTooth_tx_data <= BlueTooth_request_FIFO_data_o;
						end
					else
						begin
						// state
						BlueTooth_tx_state <= TX_IDLE;
						// uart_controller8bit signals
						BlueTooth_tx_vld <= 1'b0;
						BlueTooth_tx_data <= 8'b0;
						end
					end
				TX_WAIT:
					begin
					if (BlueTooth_tx_rdy)							// transmission complete
						begin
						// state
						BlueTooth_tx_state <= TX_IDLE;
						// request FIFO signals
						BlueTooth_request_FIFO_r_en <= 1'b0;
						// uart_controller8bit signals
						BlueTooth_tx_vld <= 1'b0;
						BlueTooth_tx_data <= 8'b0;
						end
					else											// wait for transmission complete
						begin
						// uart_controller8bit signals
						BlueTooth_tx_vld <= 1'b0;
						BlueTooth_tx_data <= 8'b0;
						end
					end
				default:
					begin
					// state
					BlueTooth_tx_state <= TX_IDLE;
					// request FIFO signals
					BlueTooth_request_FIFO_r_en <= 1'b0;
					// uart_controller8bit signals
					BlueTooth_tx_vld <= 1'b0;
					BlueTooth_tx_data <= 8'b0;
					end
			endcase
			end
		end

	// request FIFO
	FIFO #(
		.DATA_WIDTH(REQUEST_FIFO_DATA_WIDTH),						// the bit width of data we stored in the FIFO
		.DATA_DEPTH_INDEX(REQUEST_FIFO_DATA_DEPTH_INDEX)			// the index_width of data unit(reg [DATA_WIDTH - 1:0])
	) m_request_FIFO (
		.clk			(clk									),
		.rst_n			(rst_n									),

		.data_i			(BlueTooth_request_FIFO_data_i			),
		.data_i_vld		(BlueTooth_request_FIFO_data_i_vld		),
		.data_i_rdy		(BlueTooth_request_FIFO_data_i_rdy		),

		.r_en			(BlueTooth_request_FIFO_r_en			),
		.data_o			(BlueTooth_request_FIFO_data_o			),
		.data_o_vld		(BlueTooth_request_FIFO_data_o_vld		),

		// for debug
		.FIFO_full		(BlueTooth_request_FIFO_full			),
		.FIFO_empty		(BlueTooth_request_FIFO_empty			),
		.FIFO_surplus	(BlueTooth_request_FIFO_surplus			)
	);

	// response FIFO
	FIFO #(
		.DATA_WIDTH(RESPONSE_FIFO_DATA_WIDTH),						// the bit width of data we stored in the FIFO
		.DATA_DEPTH_INDEX(RESPONSE_FIFO_DATA_DEPTH_INDEX)			// the index_width of data unit(reg [DATA_WIDTH - 1:0])
	) m_response_FIFO (
		.clk			(clk						),
		.rst_n			(rst_n						),

		.data_i			(BlueTooth_response_FIFO_data_i			),
		.data_i_vld		(BlueTooth_response_FIFO_data_i_vld		),
		.data_i_rdy		(BlueTooth_response_FIFO_data_i_rdy		),

		.r_en			(BlueTooth_response_FIFO_r_en			),
		.data_o			(BlueTooth_response_FIFO_data_o			),
		.data_o_vld		(BlueTooth_response_FIFO_data_o_vld		),

		// for debug
		.FIFO_full		(BlueTooth_response_FIFO_full			),
		.FIFO_empty		(BlueTooth_response_FIFO_empty			),
		.FIFO_surplus	(BlueTooth_response_FIFO_surplus		)
	);


	// uart_controller8bit
	uart_controller8bit #(
		.CLK_FRE(CLK_FRE),					// 50MHz
		.BAUD_RATE(BAUD_RATE)				// 9600Hz
	) m_uart_controller8bit (
		.clk			(clk			),
		.rst_n			(rst_n			),
		.uart_rx		(BlueTooth_Txd	),
		.uart_tx		(BlueTooth_Rxd	),

		// inner data
		.tx_data		(BlueTooth_tx_data	),		// data
		.tx_vld			(BlueTooth_tx_vld	),		// start the transmit process
		.tx_rdy			(BlueTooth_tx_rdy	),		// transmit process complete
		.rx_data		(BlueTooth_rx_data	),		// data
		.rx_ack			(BlueTooth_rx_ack	),		// data is received by receiver buffer					(RX_WAIT)
		.rx_rdy			(BlueTooth_rx_rdy	)		// send signal to receiver buffer that data is ready
	);

endmodule