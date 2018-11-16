module test;
   reg         S_AXI_ACLK;
   reg         S_AXI_ARESETN;

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

   initial begin
      #0  S_AXI_ARESETN <= 1'b0;
      #50 S_AXI_ARESETN <= 1'b1;

      @(negedge S_AXI_ACLK);
      S_AXI_AWADDR <= 32'h4020_0000;
      S_AXI_AWVALID <= 1'b1;
      S_AXI_WDATA <= 32'h0000_001d;
      S_AXI_WSTRB <= 4'hf;
      S_AXI_WVALID <= 1'b1;

      @(negedge S_AXI_ACLK);
      S_AXI_AWVALID <= 1'b0;
      S_AXI_WSTRB <= 4'h0;
      S_AXI_WVALID <= 1'b0;

      #500000 ;

      @(negedge S_AXI_ACLK);
      S_AXI_AWADDR <= 32'h4020_0010;
      S_AXI_AWVALID <= 1'b1;
      S_AXI_WDATA <= 32'h1fff_0000;
      S_AXI_WSTRB <= 4'hf;
      S_AXI_WVALID <= 1'b1;

      @(negedge S_AXI_ACLK);
      S_AXI_AWVALID <= 1'b0;
      S_AXI_WSTRB <= 4'h0;
      S_AXI_WVALID <= 1'b0;

      #17000000 ;

      @(negedge S_AXI_ACLK);
      S_AXI_AWADDR <= 32'h4020_0010;
      S_AXI_AWVALID <= 1'b1;
      S_AXI_WDATA <= 32'h1fff_0000;
      S_AXI_WSTRB <= 4'hf;
      S_AXI_WVALID <= 1'b1;

      @(negedge S_AXI_ACLK);
      S_AXI_AWVALID <= 1'b0;
      S_AXI_WSTRB <= 4'h0;
      S_AXI_WVALID <= 1'b0;

      #500000 ;

      $finish();
   end

   always begin
      S_AXI_ACLK <= 1'b0; #5;
      S_AXI_ACLK <= 1'b1; #5;
   end

   lcd_control lcd_control
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
      .lcd_ctl(),
      .lcd_data()
      );
endmodule
