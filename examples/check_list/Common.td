
Profile {
    name         string
    sex          uint8
    level        uint16
    exp          uint16
    create_time  uint32
}

Item {
    *ID    uint32
    *Num   uint32
}

Task {
    *ID    uint32
    *IsFinished   boolean
    *Progress     uint16 #当前进度
}

