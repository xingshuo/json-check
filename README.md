JsonCheck
=========
    检查json内容是否符合预期的一种解决方案

设计思路与流程
-----
![flowchart](https://github.com/xingshuo/json-check/blob/master/flowchart.png)

[TD文件格式说明](https://github.com/xingshuo/json-check/blob/master/TDdoc.md)
-----

支持平台
-----
    Windows 64bit

依赖库(对应deps目录下文件)
-----
http://luabinaries.sourceforge.net/download.html    lua53.dll,lua.exe为下载的对应压缩包中文件<br>
https://github.com/mpx/lua-cjson    cjson.dll为修改Makefile后利用mingw编译的windows 64位动态库<br>
https://github.com/LuaDist/lpeg     lpeg.dll为修改Makefile后利用mingw编译的windows 64位动态库<br>

安装
-----
   git clone https://github.com/xingshuo/json-check.git

运行测试用例
-----
    deps\lua.exe examples\main.lua      #Win CMD
    deps/lua.exe examples/main.lua      #gitbash