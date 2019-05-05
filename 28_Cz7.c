#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <stdbool.h>

#define LCD_RD   (0x010)
#define LCD_WR   (0x008)
#define LCD_RS   (0x004)
#define LCD_CS   (0x002)
#define LCD_REST (0x001)

#define REG(addr) *(volatile unsigned int*)(addr)
#define GPIO_DATA_1 (0x0000)
#define GPIO_TRI_1  (0x0004)
#define GPIO_DATA_2 (0x0008)
#define GPIO_TRI_2  (0x000c)
#define GPIO_START  (0x0010)
#define GPIO_CYC    (0x0014)
#define GPIO_RATE   (0x0018)

#define FBUF(addr) *(volatile unsigned short*)(addr)

unsigned long address;    /* GPIOレジスタへの仮想アドレス(ユーザ空間) */
unsigned long fbuf;      /* フレームバッファへの仮想アドレス(ユーザ空間) */
unsigned long fbuf_phys;      /* フレームバッファへの物理アドレス */

#define MAX_BMP         10                      // bmp file num
#define FILENAME_LEN    20                      // max file name length

#define uint8_t unsigned char
#define uint16_t unsigned short
#define uint32_t unsigned int

const int __Gnbmp_height = 240;                 // bmp hight
const int __Gnbmp_width  = 320;                 // bmp width

unsigned char __Gnbmp_image_offset  = 0;        // offset

void Lcd_Write_Com(unsigned char VH)
{
  REG(address + GPIO_DATA_2)  =  VH;
  REG(address + GPIO_DATA_1)  =  0x11;
  REG(address + GPIO_DATA_1)  =  0x19;
}

void Lcd_Write_Data(unsigned char VH)
{
  REG(address + GPIO_DATA_2)  =  VH;
  REG(address + GPIO_DATA_1)  =  0x15;
  REG(address + GPIO_DATA_1)  =  0x1d;
}

void Address_set(unsigned int x1,unsigned int y1,unsigned int x2,unsigned int y2)
{
  Lcd_Write_Com(0x2a);
  Lcd_Write_Data(x1>>8);
  Lcd_Write_Data(x1);
  Lcd_Write_Data(x2>>8);
  Lcd_Write_Data(x2);
  Lcd_Write_Com(0x2b);
  Lcd_Write_Data(y1>>8);
  Lcd_Write_Data(y1);
  Lcd_Write_Data(y2>>8);
  Lcd_Write_Data(y2);
  Lcd_Write_Com(0x2c);
}

/*********************************************/
// These read data from the SD card file and convert them to big endian
// (the data is stored in little endian format!)

// LITTLE ENDIAN!
uint16_t read16(FILE *fp)
{
  uint16_t d;
  uint8_t b;
  b = getc(fp);
  d = getc(fp);
  d <<= 8;
  d |= b;
  return d;
}

// LITTLE ENDIAN!
uint32_t read32(FILE *fp)
{
    uint32_t d;
    uint16_t b;

    b = read16(fp);
    d = read16(fp);
    d <<= 16;
    d |= b;
    return d;
}

/*********************************************/
// This procedure reads a bitmap and draws it to the screen
// its sped up by reading many pixels worth of data at a time
// instead of just one pixel at a time. increading the buffer takes
// more RAM but makes the drawing a little faster. 20 pixels' worth
// is probably a good place

void bmpdraw(FILE *fp, int x, int y)
{
  Address_set(0,0,320,240);

  fseek(fp, __Gnbmp_image_offset, SEEK_SET);

  for (int i=__Gnbmp_height-1; i>=0 ; i--) {
    for(int j=0; j< __Gnbmp_width; j++) {

      unsigned int __color;
            
      __color =            (fgetc(fp)>>3);          // blue
      __color = __color | ((fgetc(fp)>>2)<<5);      // green
      __color = __color | ((fgetc(fp)>>3)<<11);     // red

      FBUF(fbuf+(j+i*__Gnbmp_width)*2) = __color;
    }
  }

  REG(address + GPIO_CYC) = 320*240/16/2;
  REG(address + GPIO_RATE) = 0;
  REG(address + GPIO_START) = fbuf_phys;

}

bool bmpReadHeader(FILE *fp) 
{
  // read header
  uint32_t tmp;
  uint8_t bmpDepth;
    
  if (read16(fp) != 0x4D42) {
    // magic bytes missing
    return false;
  }

  // read file size
  tmp = read32(fp);
  printf("size 0x%x\n",tmp);

  // read and ignore creator bytes
  read32(fp);

  __Gnbmp_image_offset = read32(fp);
  printf("offset %d\n", __Gnbmp_image_offset);

  // read DIB header
  tmp = read32(fp);
  printf("header size %d\n", tmp);
    
  int bmp_width = read32(fp);
  int bmp_height = read32(fp);
    
  if(bmp_width != __Gnbmp_width || bmp_height != __Gnbmp_height)  {    // if image is not 320x240, return false
    return false;
  }

  if (read16(fp) != 1)
    return false;

  bmpDepth = read16(fp);
  printf("bitdepth %d\n",bmpDepth);

  if (read32(fp) != 0) {
    // compression not supported!
    return false;
  }

  printf("compression %d\n",tmp);

  return true;
}

void setup(void) {
  int fd0,lcd;

  if ((fd0  = open("/sys/class/udmabuf/udmabuf0/phys_addr", O_RDONLY)) != -1) {
    char attr[1024];
    read(fd0, attr, 1024);
    sscanf(attr, "%lx", &fbuf_phys);
    close(fd0);
  }


  /* メモリアクセス用のデバイスファイルを開く */
  if ((fd0 = open("/dev/udmabuf0", O_RDWR)) < 0) {
    perror("open");
    return;
  }
  if ((lcd = open("/dev/uio0", O_RDWR | O_SYNC)) < 0) {
    perror("open");
    return;
  }
  /* ARM(CPU)から見た物理アドレス → 仮想アドレスへのマッピング */
  fbuf = (unsigned long)mmap(NULL, 0x00040000, PROT_READ | PROT_WRITE, MAP_SHARED, fd0, 0);
  if (fbuf == (unsigned long)MAP_FAILED) {
    perror("mmap");
    close(fd0);
    return;
  }
  address = (unsigned long)mmap(NULL, 0x1000, PROT_READ | PROT_WRITE, MAP_SHARED, lcd, 0);
  if (address == (unsigned long)MAP_FAILED) {
    perror("mmap");
    close(lcd);
    return;
  }


  REG(address + GPIO_TRI_1) = 0x0;
  REG(address + GPIO_TRI_2) = 0x0;

  REG(address + GPIO_DATA_1) = 0x1f;

  REG(address + GPIO_DATA_1) |=  LCD_REST;
  usleep(5000);
  REG(address + GPIO_DATA_1) &= ~LCD_REST;
  usleep(15000);
  REG(address + GPIO_DATA_1) |=  LCD_REST;
  usleep(15000);

  REG(address + GPIO_DATA_1) |=  LCD_CS;
  usleep(15000);
  REG(address + GPIO_DATA_1) |=  LCD_WR;
  usleep(10);
  REG(address + GPIO_DATA_1) &= ~LCD_CS;
  usleep(10);

  Lcd_Write_Com(0xCB);
  Lcd_Write_Data(0x39);
  Lcd_Write_Data(0x2C);
  Lcd_Write_Data(0x00);
  Lcd_Write_Data(0x34);
  Lcd_Write_Data(0x02);

  Lcd_Write_Com(0xCF);
  Lcd_Write_Data(0x00);
  Lcd_Write_Data(0XC1);
  Lcd_Write_Data(0X30);

  Lcd_Write_Com(0xE8);
  Lcd_Write_Data(0x85);
  Lcd_Write_Data(0x00);
  Lcd_Write_Data(0x78);

  Lcd_Write_Com(0xEA);
  Lcd_Write_Data(0x00);
  Lcd_Write_Data(0x00);

  Lcd_Write_Com(0xED);
  Lcd_Write_Data(0x64);
  Lcd_Write_Data(0x03);
  Lcd_Write_Data(0X12);
  Lcd_Write_Data(0X81);

  Lcd_Write_Com(0xF7);
  Lcd_Write_Data(0x20);

  Lcd_Write_Com(0xC0);    //Power control
  Lcd_Write_Data(0x23);   //VRH[5:0]

  Lcd_Write_Com(0xC1);    //Power control
  Lcd_Write_Data(0x10);   //SAP[2:0];BT[3:0]

  Lcd_Write_Com(0xC5);    //VCM control
  Lcd_Write_Data(0x3e);   //Contrast
  Lcd_Write_Data(0x28);

  Lcd_Write_Com(0xC7);    //VCM control2
  Lcd_Write_Data(0x86);   //--

  Lcd_Write_Com(0x36);    // Memory Access Control
  Lcd_Write_Data(0x28);

  Lcd_Write_Com(0x3A);
  Lcd_Write_Data(0x55);

  Lcd_Write_Com(0xB1);
  Lcd_Write_Data(0x00);
  Lcd_Write_Data(0x18);

  Lcd_Write_Com(0xB6);    // Display Function Control
  Lcd_Write_Data(0x08);
  Lcd_Write_Data(0x82);
  Lcd_Write_Data(0x27);

  Lcd_Write_Com(0x11);    //Exit Sleep
  usleep(120000);

  Lcd_Write_Com(0x29);    //Display on
  Lcd_Write_Com(0x2c);

  printf("initialization done.\n"); 
}

int __Gnfile_num = 4;                           // num of file

char __Gsbmp_files[4][FILENAME_LEN] =           // add file name here
{
"/mnt/flower.bmp",
"/mnt/tiger.bmp",
"/mnt/tree.bmp",
"/mnt/RedRose.bmp"
};

void loop(void) {
  FILE *bmpFile;
  for(unsigned char i=0; i<__Gnfile_num; i++) {
    bmpFile = fopen(__Gsbmp_files[i], "r");
    if (bmpFile == NULL) {
      printf("didnt find image\n");
      return;
    }
   
    if(! bmpReadHeader(bmpFile)) {
      printf("bad bmp\n");
      return;
    }

    bmpdraw(bmpFile, 0, 0);
    fclose(bmpFile);
    usleep(1000*1000);
  }
    
}

int main()
{
  setup();

  while(1)
    {
      loop();
    }
}
