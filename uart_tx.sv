module uart_tx #(
    parameter
    /*
     You can specify the following three parameters.
     1. DATA_WIDTH : width of data that is transmited by this module
     2. BAUD_RATE  : baud rate of output uart signal
     3. CLK_FREQ   : freqency of input clock signal




    */
    DATA_WIDTH = 8,
    BAUD_RATE = 9600,
    CLK_FREQ = 12_000_000,

    localparam LB_DATA_WIDTH    = $clog2(DATA_WIDTH),
               PULSE_WIDTH      = CLK_FREQ / BAUD_RATE,
               LB_PULSE_WIDTH   = $clog2(PULSE_WIDTH),
               HALF_PULSE_WIDTH = PULSE_WIDTH / 2
) (
    output logic                  sig,
    output logic                  ready,
    input  logic [DATA_WIDTH-1:0] data,
    input  logic                  valid,
    input  logic                  clk,
    input  logic                  rstn
);

  typedef enum logic [1:0] {
    STT_DATA,
    STT_STOP,
    STT_WAIT
  } statetype;

  statetype                     state;

  logic     [   DATA_WIDTH-1:0] data_r;
  logic                         sig_r;
  logic                         ready_r;
  logic     [LB_DATA_WIDTH-1:0] data_cnt;
  logic     [ LB_PULSE_WIDTH:0] clk_cnt;

  always_ff @(posedge clk) begin
    if (!rstn) begin
      state    <= STT_WAIT;
      sig_r    <= 1;
      data_r   <= 0;
      ready_r  <= 1;
      data_cnt <= 0;
      clk_cnt  <= 0;
    end else begin

      //-----------------------------------------------------------------------------
      // 3-state FSM



      case (state)

        //-----------------------------------------------------------------------------
        // state      : STT_DATA
        // behavior   : serialize and transmit data
        // next state : when all data have transmited -> STT_STOP



        STT_DATA: begin
          if (0 < clk_cnt) begin
            clk_cnt <= clk_cnt - 1;
          end else begin
            sig_r   <= data_r[data_cnt];
            clk_cnt <= PULSE_WIDTH;

            if (data_cnt == DATA_WIDTH - 1) begin
              state <= STT_STOP;
            end else begin
              data_cnt <= data_cnt + 1;
            end
          end
        end

        //-----------------------------------------------------------------------------
        // state      : STT_STOP
        // behavior   : assert stop bit
        // next state : STT_WAIT



        STT_STOP: begin
          if (0 < clk_cnt) begin
            clk_cnt <= clk_cnt - 1;
          end else begin
            state   <= STT_WAIT;
            sig_r   <= 1;
            clk_cnt <= PULSE_WIDTH + HALF_PULSE_WIDTH;
          end
        end

        //-----------------------------------------------------------------------------
        // state      : STT_WAIT
        // behavior   : watch valid signal, and assert start bit when valid signal assert
        // next state : when valid signal assert -> STT_STAT



        STT_WAIT: begin
          if (0 < clk_cnt) begin
            clk_cnt <= clk_cnt - 1;
          end else if (!ready_r) begin
            ready_r <= 1;
          end else if (valid) begin
            state    <= STT_DATA;
            sig_r    <= 0;
            data_r   <= data;
            ready_r  <= 0;
            data_cnt <= 0;
            clk_cnt  <= PULSE_WIDTH;
          end
        end

        default: begin
          state <= STT_WAIT;
        end
      endcase
    end
  end

  assign sig   = sig_r;
  assign ready = ready_r;

endmodule
