# FPGA から Arduino 用の LCD シールドを制御する

[Arduino 用の LCD シールド](https://www.amazon.co.jp/gp/product/B06Y5ZXXL8/ref=oh_aui_detailpage_o01_s00?ie=UTF8&psc=1) が CORA にちょうど良い大きさなので活用します。  
しかし、GPIO を使うととっても遅いので、フレームバッファから読みだしたデータを LCD に転送する IP を作りました。

こんな感じ

![LCD_CTL](LCD_CTL.svg)

BusControl は frame_req を受けると 1フレーム分のデータを AXI マスタから読みだす。  
1回のリクエストは 32bit×20バースト。  
ただし、fifo_full 期間中は休む。

Fifo は AXI マスタからの読み出しデータを積む。  
1バースト分の空きがなくなると、fifo_full をあげる。  
fifo にデータがある間は fifo_valid をあげる。  
fifo_req で次の 1データを読み出す。

Reg は fifo_valid があがると 40サイクルかけて 8bit のデータを 4回(=32bit)出力する。  
データを出力し終わると fifo_req をあげる。

Reg には GPIO 機能もあるので、細かい制御には GPIO を使う。

### ブロックデザインを作る

1. Vivado で tiny_dnn アクセラレータのファイル （```LCD.v``` ）を開く
2. ブロックデザインの中に ```lcd_control``` を RTLモジュールとして追加する
3. ほかの部品を ```design_1.pdf``` を参考に追加して結線する
4. PL のクロックは 100MHz
5. アドレスマップは下記参照

| master      | slave module | Start Address | End Address |
| ----------- | ------------ | ------------- | ----------- |
| PS7         | lcd_control  | 4020_0000     | 4020_0FFF   |
| lcd_control | DDR          | 0000_0000     | 1FFF_FFFF   |

ACP 周りで Critical Warning 出るけど、良く分からないので放置しています。

```
[BD 41-1629] </processing_system7_0/S_AXI_ACP/ACP_M_AXI_GP0> is excluded from all addressable master spaces.
```

また、ACP を使うときには AxCACHE を 1111 or 1110 にする必要があるようなので ```Constant IP``` を使って 1111 を入れています。  
詳しい話は [ここ](https://qiita.com/ikwzm/items/b2ee2e2ade0806a9ec07) が参考になります。  
あと、PL の設定で ```Tie off AxUSER``` にチェックを入れています。

### Petalinux を作る

Vivado でビットストリーム込みの hdf ファイルをエクスポート、```peta/project_1.sdk```にコピーして、

```
$ source /opt/pkg/petalinux/settings.sh
$ cd peta
$ petalinux-create --type project --template zynq --name lcd
$ cd lcd/
$ petalinux-config --get-hw-description=../project_1.sdk
```

menuconfig の画面で ```Image Packaging Configuration ->  Root filesystem type -> SD card``` を選択する。

DMA 転送に使うバッファ用に [udmabuf](https://github.com/ikwzm/udmabuf/blob/master/Readme.ja.md) を作る。

```
$ petalinux-create -t modules --name udmabuf --enable
$ petalinux-build -c rootfs
```

ダウンロードしたファイルで ```project-spec/meta-user/recipes-modules/udmabuf/files/``` を置き換えて、

```
$ petalinux-build -c udmabuf
```

udmabuf の設定をして、lcd_control のレジスタ空間を uio にする。  
デバイスツリーに ```dma-coherent``` 付きで udmabuf を追加する。  
具体的には ```system-user.dtsi``` で ```project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi``` を上書きして、

```
$ petalinux-build
```

続けて、

```
$ petalinux-package --boot --force --fsbl images/linux/zynq_fsbl.elf --fpga images/linux/system.bit --u-boot
```

生成物は ```images/linux/BOOT.bin, image.ub, rootfs.ext4``` です。

rootfs.ext4 を書き込む。

```
$ sudo dd if=images/linux/rootfs.ext4 of=/dev/sdb2 bs=16M
$ sudo sync
$ sudo resize2fs /dev/sdb2
$ sudo sync
```

### プログラムをコンパイルする

ホストPCでクロスコンパイルして

```
$ ${SDK path}/gnu/aarch32/nt/gcc-arm-linux-gnueabi/bin/arm-linux-gnueabihf-gcc.exe -O3  ex5_3.c -o ex5_3
```

### 実行する

Petalinux ファイル ```images/linux/BOOT.bin, image.ub``` と実行ファイルと画像データを SD カードにコピーして Zynq をブートします。  
ブート後、Zynq の Linux 上で

```
root@tiny-dnn:~# mount /dev/mmcblk0p1 /mnt/
root@tiny-dnn:~# /mnt/ex5_3
```

