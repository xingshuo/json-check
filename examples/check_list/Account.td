

AccountInfo {
    OpenID     string
    ZoneID     int
    items      [Item]  #list 字段
    IsPc       boolean
    *IsNewbie  boolean #required 字段
    profile    Profile #自定义类型
    tasks      <int, Task> #map 字段
}