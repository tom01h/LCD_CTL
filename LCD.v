module lcd_control
  (
   input wire         AXI_ACLK,
   input wire         AXI_ARESETN,

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

   ////////////////////////////////////////////////////////////////////////////
   // AXI Master Interface
   output wire [31:0] M_AXI_AWADDR,
   output wire [7:0]  M_AXI_AWLEN,
   output wire [2:0]  M_AXI_AWSIZE,
   output wire [1:0]  M_AXI_AWBURST,
   output wire [3:0]  M_AXI_AWCACHE,
   output wire        M_AXI_AWVALID,
   input wire         M_AXI_AWREADY,
   output wire [31:0] M_AXI_WDATA,
   output wire [3:0]  M_AXI_WSTRB,
   output wire        M_AXI_WLAST,
   output wire        M_AXI_WVALID,
   input wire         M_AXI_WREADY,
   input wire [1:0]   M_AXI_BRESP,
   input wire         M_AXI_BVALID,
   output wire        M_AXI_BREADY,

   output wire [31:0] M_AXI_ARADDR,
   output wire [7:0]  M_AXI_ARLEN,
   output wire [2:0]  M_AXI_ARSIZE,
   output wire [1:0]  M_AXI_ARBURST,
   output wire [3:0]  M_AXI_ARCACHE,
   output wire        M_AXI_ARVALID,
   input wire         M_AXI_ARREADY,
   input wire [31:0]  M_AXI_RDATA,
   input wire [1:0]   M_AXI_RRESP,
   input wire         M_AXI_RLAST,
   input wire         M_AXI_RVALID,
   output wire        M_AXI_RREADY,

  ////////////////////////////////////////////////////////////////////////////
  // LCD Interface
   output wire [4:0]  lcd_ctl,
   output wire [7:0]  lcd_data
   );

   wire               frame_req;
   wire [31:0]        frame_address;
   wire               fifo_req;
   wire               fifo_valid;
   wire [31:0]        fifo_data;

   lcd_reg lcd_reg
     (
      .S_AXI_ACLK(AXI_ACLK),
      .S_AXI_ARESETN(AXI_ARESETN),

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
      .frame_address(frame_address),

      .fifo_req(fifo_req),
      .fifo_valid(fifo_valid),
      .fifo_data(fifo_data)
      );

   assign M_AXI_AWVALID = 1'b0;
   assign M_AXI_WVALID = 1'b0;
   assign M_AXI_BREADY = 1'b1;
   assign M_AXI_AWADDR[31:0] = 0;
   assign M_AXI_AWLEN[7:0] = 0;
   assign M_AXI_AWSIZE[2:0] = 0;
   assign M_AXI_AWBURST[1:0] = 0;
   assign M_AXI_AWCACHE[3:0] = 0;
   assign M_AXI_WDATA[31:0] = 0;
   assign M_AXI_WSTRB[3:0] = 0;
   assign M_AXI_WLAST = 0;

   lcd_dma_buf lcd_dma_buf
     (
      .M_AXI_ACLK(AXI_ACLK),
      .M_AXI_ARESETN(AXI_ARESETN),
      .M_AXI_ARADDR(M_AXI_ARADDR),
      .M_AXI_ARLEN(M_AXI_ARLEN),
      .M_AXI_ARSIZE(M_AXI_ARSIZE),
      .M_AXI_ARBURST(M_AXI_ARBURST),
      .M_AXI_ARCACHE(M_AXI_ARCACHE),
      .M_AXI_ARVALID(M_AXI_ARVALID),
      .M_AXI_ARREADY(M_AXI_ARREADY),
      .M_AXI_RDATA(M_AXI_RDATA),
      .M_AXI_RRESP(M_AXI_RRESP),
      .M_AXI_RLAST(M_AXI_RLAST),
      .M_AXI_RVALID(M_AXI_RVALID),
      .M_AXI_RREADY(M_AXI_RREADY),

      .frame_req(frame_req),
      .frame_address(frame_address),

      .fifo_req(fifo_req),
      .fifo_data(fifo_data),
      .fifo_valid(fifo_valid)
      );

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
   output reg [31:0] frame_address,

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
           4'd4 : begin
              frame_address[31:0] <= wb_dat_i[31:0];
              frame_req <= 1'b1;
           end
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
            lcd_data <= fifo_data[8*({~pix[1],pix[0]})+:8];
         end
      end
   end

endmodule

module lcd_dma_buf
  (
   input wire        M_AXI_ACLK,
   input wire        M_AXI_ARESETN,

   output reg [31:0] M_AXI_ARADDR,
   output reg [7:0]  M_AXI_ARLEN,
   output reg [2:0]  M_AXI_ARSIZE,
   output reg [1:0]  M_AXI_ARBURST,
   output reg [3:0]  M_AXI_ARCACHE,
   output reg        M_AXI_ARVALID,
   input wire        M_AXI_ARREADY,
   input wire [31:0] M_AXI_RDATA,
   input wire [1:0]  M_AXI_RRESP,
   input wire        M_AXI_RLAST,
   input wire        M_AXI_RVALID,
   output reg        M_AXI_RREADY,

   input wire [31:0] frame_address,
   input wire        frame_req,

   input wire        fifo_req,
   output wire       fifo_valid,
   output reg [31:0] fifo_data
   );

   parameter len = 20;    // 4 Bytes * 20 Burst = 2Bytes * 40 pixel
   parameter cyc = 6*320; // 40 pixel * 6 * 320 = 240 * 320 pixel

   reg                state;
   wire               fifo_full;
   reg                fifo_wait;
   always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)begin
      if(~M_AXI_ARESETN)begin
         state <= 1'b0;
         fifo_wait <= 1'b0;
         M_AXI_ARADDR[31:0] <= 0;
         M_AXI_ARLEN[7:0] <= len-1;
         M_AXI_ARSIZE[2:0] <= 2; // 32bit
         M_AXI_ARBURST[1:0] <= 1; // incr
         M_AXI_ARCACHE[3:0] <= 3;
         M_AXI_ARVALID <= 1'b0;
         M_AXI_RREADY <= 1'b1;
      end else if(frame_req)begin
         state <= 1'b1;
         M_AXI_ARADDR[31:0] <= frame_address;
         M_AXI_ARVALID <= 1'b1;
      end else if (state)begin
         if(M_AXI_ARREADY)begin
            M_AXI_ARVALID <= 1'b0;
         end
         if(M_AXI_RLAST & M_AXI_RVALID)begin
            if(M_AXI_ARADDR[31:0] != (frame_address+len*4*(6*320-1)))begin
               M_AXI_ARADDR[31:0] <= M_AXI_ARADDR[31:0] + len*4;
               if(fifo_full)begin
                  fifo_wait <= 1'b1;
               end else begin
                  M_AXI_ARVALID <= 1'b1;
               end
            end else begin
               state <= 1'b0;
            end
         end
         if(fifo_wait & ~fifo_full)begin
            M_AXI_ARVALID <= 1'b1;
            fifo_wait <= 1'b0;
         end
      end
   end

   reg [31:0]         fifo [0:1023];
   reg [10:0]         wp;
   reg [9:0]          rp;
   assign fifo_full = (wp - rp)>(1024-len);
   assign fifo_valid = (wp>rp);

   always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)begin
      if(~M_AXI_ARESETN)begin
         wp <= 0;
         rp <= 0;
      end else begin
         if(M_AXI_RVALID)begin
            wp <= wp + 1;
         end
         if(fifo_req)begin
            if(wp>rp)begin
               rp <= rp + 1;
            end
            if(rp == 10'h3ff)begin
               wp[10] <= 1'b0;
            end
         end
      end
   end

   always @(posedge M_AXI_ACLK)begin
      if(M_AXI_RVALID)begin
         fifo[wp[9:0]] <= M_AXI_RDATA;
      end
   end

   always @(posedge M_AXI_ACLK)begin
      if(fifo_req&(wp>rp))begin
         fifo_data <= fifo[rp];
      end
   end

endmodule
