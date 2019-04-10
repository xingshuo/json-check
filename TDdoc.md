Td格式说明
=======

基础类型
----
    1.number类
      无符号整数: uint8 uint16 uint32 uint uint64
      有符号整数: int8 int16 int32 int int64
      浮点数: float double
    2.布尔类: boolean
    3.字符串类: string

自定义类型(Struct)
----
    结构体名称 {
        字段名称1   字段类型1
        字段名称2   字段类型2
        ...
    }

字段类型
----
    unit  单个Struct或基础类型
    list  相同的unit组成的列表  格式:[item_type]  注:只支持单层,多层结构需借助Struct嵌套
    map   key/value结构,key只能是string或number类型  格式:<key_type, value_type>  注:只支持单层,多层结构需借助Struct嵌套
    
示例
----
    Item {
        *ID    uint32  #字段名称前加* 表示必须填写的required字段,否则为optional
        *Num   uint32
    }
    对应的json格式:
    {
        "ID":100001,
        "Num":10
    }
    
    Task {
        *ID    uint32
        *IsFinished   boolean
        *Progress     uint16 #当前进度
    }
    对应的json格式:
    {
        "ID": 1001,
        "IsFinished": true,
        "Progress": 50
    }
    
    Profile {
        name         string
        sex          uint8
        level        uint16
        exp          uint16
        create_time  uint32
    }
    对应的json格式:
    {
        "name": "lakefu",
        "sex":  1,
        "level": 60,
        "exp": 10000,
        "create_time": 1554868133
    }
    
    下面看一个复杂一点的:
    AccountInfo {
        OpenID     string
        ZoneID     int
        items      [Item]  #list 字段
        IsPc       boolean
        *IsNewbie  boolean #required 字段
        profile    Profile #自定义类型
        tasks      <int, Task> #map 字段, 这里的key是int类型 但json的key只能是string,因此会调用lua的tonumber检查该string能否转化成int
    }
    对应的json格式:
    {
        "OpenID": "743A8A7741205CC43D585806F691736A",
        "ZoneID": 1,
        "items": [
            {
                "ID": 10001,
                "Num": 10
            },
            {
                "ID": 10002,
                "Num": 20
            }
        ],
        "IsPc": true,
        "IsNewbie": false,
        "profile": {
            "name": "lakefu",
            "sex": 1,
            "level": 60,
            "exp": 10000,
            "create_time": 1554868133
        },
        "tasks": {
            "1001": {
                "ID": 1001,
                "IsFinished": true,
                "Progress": 50
            },
            "1002": {
                "ID": 1002,
                "IsFinished": false,
                "Progress": 100
            }
        }
    }