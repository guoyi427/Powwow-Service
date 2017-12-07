//
//  mysqlManager.swift
//  Powwow-ServicePackageDescription
//
//  Created by kokozu on 06/12/2017.
//
import PerfectMySQL

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
        guard connect() else {
            debugPrint("mysql connect failure")
            return
        }
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

// MARK: - Public - Methods
extension mysqlManager {
    /// 查找用户手机号是否存在
    func queryUser(mobile: String) -> (success: Bool, userDic: [String: String]) {
        if !_isConnect {
            guard connect() else {
                debugPrint("connect db failure again")
                return (false, [:])
            }
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
}

// MARK: - Base - Methods
extension mysqlManager {
    func mysqlStatement(sql: String) -> (success: Bool, mysqlResult: MySQL.Results?, errorMsg: String) {
        guard _mysql.selectDatabase(named: DBName) else {
            return (false, nil, "select database failure")
        }
        
        guard _mysql.query(statement: sql) else {
            return (false, nil, "sql query failure \(sql)")
        }
        
        guard let result = _mysql.storeResults() else {
            return (false, nil, "query failure empty result")
            
        }
        
        return (true, result, "\(sql) success")
    }
    
    func insert(tableName: String, para: [String: String]) -> (success: Bool, mysqlResult: MySQL.Results?, errorMsg: String) {
        var left = "insert into \(tableName) ("
        var right = "values("
        
        var frist = true
        para.forEach { (dic) in
            if frist {
                left.append(dic.key)
                right.append(dic.value)
                frist = false
            } else {
                left.append(", \(dic.key)")
                right.append(", \(dic.value)")
            }
        }
        left.append(") ")
        right.append(")")
        let sqlStr = left + right
        
        return mysqlStatement(sql: sqlStr)
    }
    
    func query(tableName: String, find: String, whereStr: String) -> (success: Bool, mysqlResult: MySQL.Results?, errorMsg: String) {
        let _find = find.count > 0 ? find : "*"
        let sqlStr = "select \(_find) from \(tableName) where \(whereStr)"
        return mysqlStatement(sql: sqlStr)
    }
}
