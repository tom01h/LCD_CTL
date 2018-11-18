module test;
   reg         AXI_ACLK;
   reg         AXI_ARESETN;

   // AXI Lite Slave Interface
   reg [31:0]  S_AXI_AWADDR;
   reg         S_AXI_AWVALID;
   wire        S_AXI_AWREADY;
   reg [31:0]  S_AXI_WDATA;
   reg [3:0]   S_AXI_WSTRB;
   reg         S_AXI_WVALID;
   wire        S_AXI_WREADY;
   wire [1:0]  S_AXI_BRESP;
   wire        S_AXI_BVALID;
   wire        S_AXI_BREADY = 1;

   wire [31:0] S_AXI_ARADDR = 0;
   wire        S_AXI_ARVALID = 0;
   wire        S_AXI_ARREADY;
   wire [31:0] S_AXI_RDATA;
   wire [1:0]  S_AXI_RRESP;
   wire        S_AXI_RVALID;
   wire        S_AXI_RREADY = 1;

   // AXI Master Interface
   wire [31:0] M_AXI_ARADDR;
   wire [7:0]  M_AXI_ARLEN;
   wire [2:0]  M_AXI_ARSIZE;
   wire [1:0]  M_AXI_ARBURST;
   wire [3:0]  M_AXI_ARCACHE;
   wire        M_AXI_ARVALID;
   wire        M_AXI_RREADY;

   wire        M_AXI_ARREADY = 1'b1;
   wire [1:0]  M_AXI_RRESP = 2'b00;
   reg [31:0]  M_AXI_RDATA;
   reg         M_AXI_RLAST;
   reg         M_AXI_RVALID;

   initial begin
      #0  AXI_ARESETN <= 1'b0;
      #50 AXI_ARESETN <= 1'b1;

      @(negedge AXI_ACLK);
      S_AXI_AWADDR <= 32'h4020_0000;
      S_AXI_AWVALID <= 1'b1;
      S_AXI_WDATA <= 32'h0000_001d;
      S_AXI_WSTRB <= 4'hf;
      S_AXI_WVALID <= 1'b1;

      @(negedge AXI_ACLK);
      S_AXI_AWVALID <= 1'b0;
      S_AXI_WSTRB <= 4'h0;
      S_AXI_WVALID <= 1'b0;

      #500000 ;

      @(negedge AXI_ACLK);
      S_AXI_AWADDR <= 32'h4020_0010;
      S_AXI_AWVALID <= 1'b1;
      //S_AXI_WDATA <= 32'h1fff_0000;
      S_AXI_WDATA <= 32'h0000_0000;
      S_AXI_WSTRB <= 4'hf;
      S_AXI_WVALID <= 1'b1;

      @(negedge AXI_ACLK);
      S_AXI_AWVALID <= 1'b0;
      S_AXI_WSTRB <= 4'h0;
      S_AXI_WVALID <= 1'b0;

      #17000000 ;

      @(negedge AXI_ACLK);
      S_AXI_AWADDR <= 32'h4020_0010;
      S_AXI_AWVALID <= 1'b1;
      //S_AXI_WDATA <= 32'h1fff_0000;
      S_AXI_WDATA <= 32'h0000_0000;
      S_AXI_WSTRB <= 4'hf;
      S_AXI_WVALID <= 1'b1;

      @(negedge AXI_ACLK);
      S_AXI_AWVALID <= 1'b0;
      S_AXI_WSTRB <= 4'h0;
      S_AXI_WVALID <= 1'b0;

      #500000 ;

      $finish();
   end

   always begin
      AXI_ACLK <= 1'b0; #5;
      AXI_ACLK <= 1'b1; #5;
   end

   reg state;
   reg [4:0] len;
   wire [13:0] cnt = (M_AXI_ARADDR/4+len)%(240*80/2);
   wire [1:0]  color = ((M_AXI_ARADDR/4)/(240*80/2))%4;

   always @(posedge AXI_ACLK or negedge AXI_ARESETN)begin
      if(~AXI_ARESETN)begin
         state <= 0;
         len <= 0;
         M_AXI_RLAST <= 1'b0;
         M_AXI_RVALID <= 1'b0;
      end else if(M_AXI_ARVALID|state)begin
         M_AXI_RVALID <= 1'b1;
         state <= 1'b1;
         len <= len + 1;
         if(color==0)begin
            M_AXI_RDATA <= {1'b0,cnt[13:0],1'b0,1'b0,cnt[13:0],1'b1};
         end else if(color==1)begin
            M_AXI_RDATA <= {2{16'h001f}};
         end else if(color==2)begin
            M_AXI_RDATA <= {2{16'h07e0}};
         end else if(color==3)begin
            M_AXI_RDATA <= {2{16'hf100}};
         end
         if(len==19)begin
            state <= 0;
            M_AXI_RLAST <= 1'b1;
         end
      end else begin
         len <= 0;
         M_AXI_RLAST <= 1'b0;
         M_AXI_RVALID <= 1'b0;
      end
   end

   lcd_control lcd_control
     (
      .AXI_ACLK(AXI_ACLK),
      .AXI_ARESETN(AXI_ARESETN),

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

      .lcd_ctl(),
      .lcd_data()
      );
endmodule
