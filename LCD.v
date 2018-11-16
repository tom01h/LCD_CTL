module lcd_control
  (
   input wire         S_AXI_ACLK,
   input wire         S_AXI_ARESETN,

   ////////////////////////////////////////////////////////////////////////////
   // AXI Lite Slave Interface
   input wire [31:0]  S_AXI_AWADDR,
   input wire         S_AXI_AWVALID,
   output wire        S_AXI_AWREADY,
   input wire [31:0]  S_AXI_WDATA,
   input wire [3:0]   S_AXI_WSTRB,
   input wire         S_AXI_WVALID,
   output wire        S_AXI_WREADY,
   output wire [1:0]  S_AXI_BRESP,
   output wire        S_AXI_BVALID,
   input wire         S_AXI_BREADY,

   input wire [31:0]  S_AXI_ARADDR,
   input wire         S_AXI_ARVALID,
   output wire        S_AXI_ARREADY,
   output wire [31:0] S_AXI_RDATA,
   output wire [1:0]  S_AXI_RRESP,
   output wire        S_AXI_RVALID,
   input wire         S_AXI_RREADY,

   output wire [4:0]  lcd_ctl,
   output wire [7:0]  lcd_data
   );

   wire               frame_req;
   wire               fifo_req;
   reg                fifo_valid;
   reg [31:0]         fifo_data;

   lcd_reg lcd_reg
     (
      .S_AXI_ACLK(S_AXI_ACLK),
      .S_AXI_ARESETN(S_AXI_ARESETN),

      .S_AXI_AWADDR(S_AXI_AWADDR),
      .S_AXI_AWVALID(S_AXI_AWVALID),
      .S_AXI_AWREADY(S_AXI_AWREADY),
      .S_AXI_WDATA(S_AXI_WDATA),
      .S_AXI_WSTRB(S_AXI_WSTRB),
      .S_AXI_WVALID(S_AXI_WVALID),
      .S_AXI_WREADY(S_AXI_WREADY),
      .S_AXI_BRESP(S_AXI_BRESP),
      .S_AXI_BVALID(S_AXI_BVALID),
      .S_AXI_BREADY(S_AXI_BREADY),

      .S_AXI_ARADDR(S_AXI_ARADDR),
      .S_AXI_ARVALID(S_AXI_ARVALID),
      .S_AXI_ARREADY(S_AXI_ARREADY),
      .S_AXI_RDATA(S_AXI_RDATA),
      .S_AXI_RRESP(S_AXI_RRESP),
      .S_AXI_RVALID(S_AXI_RVALID),
      .S_AXI_RREADY(S_AXI_RREADY),

      .lcd_ctl(lcd_ctl),
      .lcd_data(lcd_data),

      .frame_req(frame_req),

      .fifo_req(fifo_req),
      .fifo_valid(fifo_valid),
      .fifo_data(fifo_data)
      );

   reg [1:0]          color;
   reg [13:0]         cnt;
   

   always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)begin
      if(~S_AXI_ARESETN) begin
         color <= 0;
         cnt <= 0;
         fifo_valid <= 1'b0;
      end else if(frame_req)begin
         color <= 0;
         cnt <= 0;
         fifo_valid <= 1'b1;
      end else if(fifo_valid & fifo_req)begin
         if(color==0)begin
            fifo_data <= {1'b0,cnt[13:0],1'b0,1'b0,cnt[13:0],1'b1};
         end else if(color==1)begin
            fifo_data <= {2{16'h001f}};
         end else if(color==2)begin
            fifo_data <= {2{16'h07e0}};
         end else if(color==3)begin
            fifo_data <= {2{16'hf100}};
         end
         if(cnt == 80*240/2-1)begin
            if(color == 2'b11)begin
               fifo_valid <= 1'b0;
            end
            color <= color + 1;
            cnt <= 0;
         end else begin
            cnt <= cnt + 1;
         end
      end
   end

endmodule

module lcd_reg
  (
   input wire        S_AXI_ACLK,
   input wire        S_AXI_ARESETN,

   ////////////////////////////////////////////////////////////////////////////
   // AXI Lite Slave Interface
   input wire [31:0] S_AXI_AWADDR,
   input wire        S_AXI_AWVALID,
   output wire       S_AXI_AWREADY,
   input wire [31:0] S_AXI_WDATA,
   input wire [3:0]  S_AXI_WSTRB,
   input wire        S_AXI_WVALID,
   output wire       S_AXI_WREADY,
   output wire [1:0] S_AXI_BRESP,
   output wire       S_AXI_BVALID,
   input wire        S_AXI_BREADY,

   input wire [31:0] S_AXI_ARADDR,
   input wire        S_AXI_ARVALID,
   output wire       S_AXI_ARREADY,
   output reg [31:0] S_AXI_RDATA,
   output wire [1:0] S_AXI_RRESP,
   output wire       S_AXI_RVALID,
   input wire        S_AXI_RREADY,

   output reg [4:0]  lcd_ctl,
   output reg [7:0]  lcd_data,

   output reg        frame_req,

   output wire       fifo_req,
   input wire        fifo_valid,
   input wire [31:0] fifo_data
   );

   reg [3:0]         axist;
   reg [5:2]         wb_adr_i;
   reg [31:0]        wb_dat_i;

   assign S_AXI_BRESP = 2'b00;
   assign S_AXI_RRESP = 2'b00;
   assign S_AXI_AWREADY = (axist == 4'b0000)|(axist == 4'b0010);
   assign S_AXI_WREADY  = (axist == 4'b0000)|(axist == 4'b0001);
   assign S_AXI_ARREADY = (axist == 4'b0000);
   assign S_AXI_BVALID  = (axist == 4'b0011);
   assign S_AXI_RVALID  = (axist == 4'b0100);

   always @(posedge S_AXI_ACLK)begin
      if(~S_AXI_ARESETN)begin
         axist<=4'b0000;

         wb_adr_i<=0;
         wb_dat_i<=0;
      end else if(axist==4'b000)begin
         if(S_AXI_AWVALID & S_AXI_WVALID)begin
            axist<=4'b0011;
            wb_adr_i[5:2]<=S_AXI_AWADDR[5:2];
            wb_dat_i<=S_AXI_WDATA;
         end else if(S_AXI_AWVALID)begin
            axist<=4'b0001;
            wb_adr_i[5:2]<=S_AXI_AWADDR[5:2];
         end else if(S_AXI_WVALID)begin
            axist<=4'b0010;
            wb_dat_i<=S_AXI_WDATA;
         end else if(S_AXI_ARVALID)begin
            axist<=4'b0100;
         end
      end else if(axist==4'b0001)begin
         if(S_AXI_WVALID)begin
            axist<=4'b0011;
            wb_dat_i<=S_AXI_WDATA;
         end
      end else if(axist==4'b0010)begin
         if(S_AXI_AWVALID)begin
            axist<=4'b0011;
            wb_adr_i[5:2]<=S_AXI_AWADDR[5:2];
         end
      end else if(axist==4'b0011)begin
         if(S_AXI_BREADY)
           axist<=4'b0000;
      end else if(axist==4'b0100)begin
         if(S_AXI_RREADY)
           axist<=4'b0000;
      end
   end

   wire        read  = S_AXI_ARVALID & S_AXI_ARREADY;
   wire        write = (axist==4'b0011) & S_AXI_BREADY;

   always @(posedge S_AXI_ACLK)begin
      if(~S_AXI_ARESETN)begin
         S_AXI_RDATA <= 32'h0;
      end else if(read)begin
         case(S_AXI_ARADDR[5:2])
           4'd0 : S_AXI_RDATA <= lcd_ctl[4:0];
           //4'd1 : S_AXI_RDATA <= lcd_ctl_tri[4:0];
           4'd2 : S_AXI_RDATA <= lcd_data[7:0];
           //4'd3 : S_AXI_RDATA <= lcd_data_tri[7:0];
           default: S_AXI_RDATA <= {32'h0};
         endcase
      end
   end

   reg [1:0] pix;
   reg [3:0] cnt;
   assign fifo_req = (pix==3) & (cnt==0);

   always @(posedge S_AXI_ACLK)begin
      frame_req <= 1'b0;
      if(~S_AXI_ARESETN)begin
         pix <= 3;
         cnt <= 0;
         lcd_ctl[4:0] <= 5'h1f;
         //lcd_ctl_tri[4:0] <= 0;
         lcd_data[7:0] <= 0;
         //lcd_data_tri[7:0] <= 0;
      end else if(write)begin
         case(wb_adr_i[5:2])
           4'd0 : lcd_ctl[4:0] <= wb_dat_i[4:0];
           //4'd1 : lcd_ctl_tri[4:0] <= wb_dat_i[4:0];
           4'd2 : lcd_data[7:0] <= wb_dat_i[7:0];
           //4'd3 : lcd_data_tri[7:0] <= wb_dat_i[7:0];
           4'd4 : frame_req <= 1'b1;
         endcase
      end else if(~lcd_ctl[0])begin
         pix <= 3;
         cnt <= 0;
      end else if(fifo_valid|~fifo_req)begin
         if(cnt == 9)begin
            pix <= pix - 1;
            cnt <= 0;
         end else begin
            cnt <= cnt + 1;
         end
         if(cnt==3)begin
            lcd_ctl[3] <= 1'b0;
         end else if(cnt==8)begin
            lcd_ctl[3] <= 1'b1;
         end
         if(cnt==1)begin
            lcd_data <= fifo_data[8*pix+:8];
         end
      end
   end

endmodule
