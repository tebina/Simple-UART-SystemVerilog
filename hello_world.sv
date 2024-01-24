`timescale 1ns / 1ps

module hello_world #(
    DATA_WIDTH = 8,
    BAUD_RATE  = 9600,
    CLK_FREQ   = 12_000_000
) (
    input  logic clk,
    input  logic rstn,
    input  logic rx,
    output logic tx
);
  reg                  valid_tx;
  reg [DATA_WIDTH-1:0] data_tx;
  reg [DATA_WIDTH-1:0] data_rx;

  uart_rx #(DATA_WIDTH, BAUD_RATE, CLK_FREQ) uart_rx_instance (
      .clk  (clk),
      .rstn (rstn),
      .sig  (rx),
      .ready(ready_rx),
      .data (data_rx),
      .valid(valid_rx)
  );
  uart_tx #(DATA_WIDTH, BAUD_RATE, CLK_FREQ) uart_tx_instance (
      .clk  (clk),
      .rstn (rstn),
      .sig  (tx),
      .ready(ready_tx),
      .data (data_tx),
      .valid(valid_tx)
  );


  typedef enum {
    SEND_HELLO,
    ECHO
  } state_type;
  state_type state;
  integer str_len = 11;
  integer str_index = 0;
  reg [8*16:1] hello = "Hello, World!   ";


  always_ff @(posedge clk) begin : main_loop
    if (!rstn) begin
      state <= SEND_HELLO;
    end else begin
      case (state)
        SEND_HELLO: begin
          if (valid_tx == 0 & ready_tx == 1 & str_index < str_len) begin
            valid_tx <= 1;
            data_tx  <= hello[str_index];
            str_index++;
          end else begin
            if (str_index == str_len) begin
              state <= ECHO;
            end else begin
              valid_tx <= 0;
            end
          end
        end
        ECHO: begin
          if (valid_rx == 1) begin
            valid_tx <= 1;
            data_tx  <= data_rx;
          end else begin
            valid_tx <= 0;
          end
        end
      endcase
    end
  end


endmodule
