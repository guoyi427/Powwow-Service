//
//  mysqlManager.swift
//  Powwow-ServicePackageDescription
//
//  Created by kokozu on 06/12/2017.
//
import PerfectMySQL
import PerfectLib

class mysqlManager {
    static let instance = mysqlManager()
    
    fileprivate let Host = "127.0.0.1"
    fileprivate let Account = "guoyi"
    fileprivate let Password = "gy1111"
    fileprivate let Port: UInt32 = 3306
    fileprivate let DBName = "powwow"
    
    fileprivate let _mysql: MySQL = MySQL()
    fileprivate var _isConnect = false
    
    init() {
//        guard connect() else {
//            debugPrint("mysql connect failure")
//            return
//        }
    }
    
    deinit {
        close()
    }
    
    func connect() -> Bool {
        _isConnect = _mysql.connect(host: Host, user: Account, password: Password, db: DBName, port: Port)
        return _isConnect
    }
    
    func close() {
        _mysql.close()
        _isConnect = false
    }
}

// MARK: - Private - Methods
extension mysqlManager {
    /// 根据手机号生成token 添加了时间戳在里面
    func tokenMaker(mobile: String) -> String {
        let currentDateStr = String(getNow())
        let tokenStr = mobile + currentDateStr
        var token = ""
        if let tokenMD5 = tokenStr.digest(.md5)?.encode(.hex) {
            token = String(validatingUTF8: tokenMD5) ?? ""
        }
        return token
    }
}

// MARK: - Public - Methods
extension mysqlManager {
    /// 查找用户手机号是否存在
    func queryUser(mobile: String) -> (success: Bool, userDic: [String: String]) {
        if !judgeConnect() {
            debugPrint("connect db failure again")
            return (false, [:])
        }
        let result = query(tableName: "user", find: "*", whereStr: "mobile=\(mobile)")
        if result.success {
            guard let sqlResult = result.mysqlResult else {
                debugPrint(result.errorMsg)
                return (false, [:])
            }
            
            var lastUserDic: [String: String] = [:]
            sqlResult.forEachRow(callback: { (element) in
                //  提取数据
                var userDic: [String: String] = [:]
                let keyList = ["id", "name", "mobile", "password", "token", "creatTime"]
                for index in 0...keyList.count-1 {
                    let key = keyList[index]
                    if let value = element[index] {
                        userDic[key] = value
                    }
                }
                lastUserDic = userDic
            })
            
            return (true, lastUserDic)
        } else {
            debugPrint("query \(mobile) failure \(result.errorMsg)")
            return (false, [:])
        }
    }
    
    /// 更新本地token 返回登录是否成功
    func updateToken(mobile: String, password: String) -> (success: Bool, token: String) {
        if !judgeConnect() {
            debugPrint("connect db failure again")
            return (false, "")
        }
        
        let result = query(tableName: "user", find: "count(id)", whereStr: "mobile='\(mobile)' and password='\(password)'")
        if result.success {
            guard let sqlResult = result.mysqlResult else {
                debugPrint("update token failure")
                return (false, "")
            }
            var isExist = false
            sqlResult.forEachRow(callback: { (element) in
                if element.count > 0 {
                    isExist = true
                }
            })
            
            //  手机号 密码 验证完毕 更新本地的token
            if isExist {
                let token = tokenMaker(mobile: mobile)
                if token.count > 0 {
                    let tokenResult = update(tableName: "user", para: ["token": token], whereDic: ["mobile": mobile])
                    if tokenResult.success {
                        return (true, token)
                    }
                }
            }
        }
        return (false, "")
    }
    
    /// 生成新用户
    func addUser(mobile: String, password: String) -> (success: Bool, user: [String: String]) {
        if !judgeConnect() {
            debugPrint("connect db failure")
            return (false, [:])
        }
        
        var creatTime = ""
        do {
            let creatTimeDouble = getNow()
            creatTime = try formatDate(creatTimeDouble, format: "%F %R")
        } catch {
            debugPrint("\(error)")
        }
        
        //  maxId
        let maxIdResult = queryMaxId()
        guard maxIdResult.success else {
            debugPrint("query max id failure")
            return (false, [:])
        }
        
        let userInfo = ["mobile": mobile,
                        "password": password,
                        "name": "defult",
                        "token": tokenMaker(mobile: mobile),
                        "creatTime": creatTime,
                        "id": maxIdResult.maxId]
        
        if insert(tableName: "user", para: userInfo).success {
            return (true, userInfo)
        }
        
        return (false, [:])
    }
    
    /// 获取所有用户的最大id
    func queryMaxId() -> (success: Bool, maxId: String) {
        let result = query(tableName: "user", find: "max(id)")
        if result.success {
            guard let mysqlResult = result.mysqlResult else {
                return (false, "")
            }
            
            var maxId: String = ""
            mysqlResult.forEachRow(callback: { (element) in
                if let str = element.first as? String {
                    maxId = String(Int(str)! + 1)
                }
            })
            
            if maxId.count > 1 {
                return (true, maxId)
            }
        }
        return (false, "")
    }
}

// MARK: - Base - Methods
extension mysqlManager {
    
    /// 判断是否已经连接服务器
    func judgeConnect() -> Bool {
        if !_isConnect {
            return connect()
        }
        return true
    }
    
    
    func mysqlStatement(sql: String, needResult: Bool) -> (success: Bool, mysqlResult: MySQL.Results?, errorMsg: String) {
        guard _mysql.selectDatabase(named: DBName) else {
            let msg = "select database failure \(sql)"
            debugPrint(msg)
            return (false, nil, msg)
        }
        
        guard _mysql.query(statement: sql) else {
            let msg = "sql query failure \(sql)"
            debugPrint(msg)
            return (false, nil, msg)
        }
        
        //  走到这里 无返回值的sql就已经完成，无需查询返回值
        if needResult == false {
            return (true, nil, "")
        }
        
        guard let result = _mysql.storeResults() else {
            let msg = "query failure empty result \(sql)"
            debugPrint(msg)
            return (false, nil, msg)
        }
        
        return (true, result, "\(sql) success")
    }
    
    func insert(tableName: String, para: [String: String]) -> (success: Bool, mysqlResult: MySQL.Results?, errorMsg: String) {
        var left = "insert into \(tableName) ("
        var right = "values("
        
        var first = true
        para.forEach { (dic) in
            if first {
                left.append(dic.key)
                right.append("'\(dic.value)'")
                first = false
            } else {
                left.append(", \(dic.key)")
                right.append(", '\(dic.value)'")
            }
        }
        left.append(") ")
        right.append(")")
        let sqlStr = left + right
        
        return mysqlStatement(sql: sqlStr, needResult: false)
    }
    
    func query(tableName: String, find: String, whereStr: String? = nil) -> (success: Bool, mysqlResult: MySQL.Results?, errorMsg: String) {
        let _find = find.count > 0 ? find : "*"
        
        var sqlStr = "select \(_find) from \(tableName)"
        
        if let whereStr_n = whereStr {
            sqlStr = "select \(_find) from \(tableName) where \(whereStr_n)"
        }
        
        return mysqlStatement(sql: sqlStr, needResult: true)
    }
    
    func update(tableName: String, para: [String: String], whereDic: [String: String]) -> (success: Bool, mysqlResult: MySQL.Results?, errorMsg: String) {
        var left: String = "update \(tableName) set "
        var right: String = ""
        
        var first = true
        para.forEach { (element) in
            if first {
                first = false
                left.append("\(element.key) = '\(element.value)'")
            } else {
                left.append(", \(element.key) = '\(element.value)'")
            }
        }
        
        first = true
        whereDic.forEach { (element) in
            if first {
                first = false
                right.append("where \(element.key) = '\(element.value)'")
            } else {
                right.append(", \(element.key) = '\(element.value)'")
            }
        }
        let sqlStr = left + right
        return mysqlStatement(sql: sqlStr, needResult: false)
    }
}
