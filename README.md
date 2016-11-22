# I2C_master

**IIC 主控制器**

    1）逻辑主要由systemverilog设计
    2）非轻量化设计（相比于网上其他的i2c master不到一千行代码），功能全部模块式细化，但是资源消耗不到，350LUT左右！
    3）标准接口化设计，内部用标准interface连接，轻松实现拓展，基于interface的功能模块放在func文件夹，里面都是简单
       的状态机，已经对IIC层进行了抽象包装
    4）通用化设计，设计用的我自定义的标准接口common interface 和 data interface ，可以做到很少的改动就能实现其他
       协议，比如SPI，这两个接口实现其实可以够新开一个repository的，以后我会更新:-)。
    
    
建议从 Func文件夹里面的模块开始从上往下熟悉设计思路。

altera_xilinx_always_block_sw.rb 为复位替换脚本 可忽略


Have fun !!!

--@--Young--@--
