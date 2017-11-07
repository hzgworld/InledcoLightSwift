//
//  DeviceDataCoreManager.swift
//  InledcoLightSwift
//
//  Created by huang zhengguo on 2017/10/10.
//  Copyright © 2017年 huang zhengguo. All rights reserved.
//

import UIKit
import CoreData

class DeviceDataCoreManager {
    static let deviceTableName: String! = "BleDevice"
    static let deviceTableUuidName: String! = "uuid"
    static let deviceTableNameName: String! = "name"
    static var context: NSManagedObjectContext?
    
    // 类方法func前面添加class
    /// 获取数据管理上下文
    ///
    /// - returns: 数据管理上下文
    class func getDataCoreContext() -> NSManagedObjectContext {
        // 1.获取实体路径
        guard let modelURL = Bundle.main.url(forResource: "DeviceModel", withExtension: "momd") else {
            fatalError("failed to find data model")
        }
        
        // 2.根据实体路径创建管理对象模型
        guard let bleDeviceModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("failed to create model from file: \(modelURL)")
        }
        
        // 3.创建持久存储协作对象
        let psc = NSPersistentStoreCoordinator(managedObjectModel: bleDeviceModel)
        
        // 4.指定数据库文件
        let dirURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
        let fileURL = URL(string: "DeviceData.sql", relativeTo: dirURL)
        do{
            try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: fileURL, options: nil)
        }catch{
            fatalError("Error configuring persistent store:\(error)")
        }
        
        // 5.创建模型管理上下文
        if context == nil {
            context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            context?.persistentStoreCoordinator = psc
        }

        return context!
    }
    
    /// 获取指定条件的数据
    /// - parameter tableName: 表名
    /// - parameter colName: 列名称
    /// - parameter colVal: 列值
    ///
    /// - returns: 获取到的符合条件的数据
    class func getDataWithFromTableWithCol(tableName: String, colName: String?, colVal: String?) -> [Any] {
        let dataCoreContext = getDataCoreContext()
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: tableName)
        
        if colName != nil && colVal != nil {
            // 这里colname不能使用%格式化，会自动给列名添加""，那么筛选就不好使了
            fetch.predicate = NSPredicate(format: "\(colName!) == %@", colVal!)
        }
        
        do {
            let results = try dataCoreContext.fetch(fetch)
            
            return results;
        }catch{
            print("查询出错!\(error)")
        }
        
        return []
    }
    
    class func setDataWithFromTableWithCol(tableName: String, colConditionName: String, colConditionVal: String, colName: String, newColVal: String) -> Void {
        let dataCoreContext = getDataCoreContext()
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: tableName)
        fetch.predicate = NSPredicate(format: "\(colConditionName) == %@", colConditionVal)
        
        do {
            let results = try dataCoreContext.fetch(fetch)
            if results.count > 0 {
                if tableName == self.deviceTableName {
                    let value = results[0] as! BleDevice
                    if colName == self.deviceTableNameName {
                        value.name = newColVal
                    }
                }
            }
            
            try dataCoreContext.save()
        }catch{
            print("查询出错!\(error)")
        }
    }
    
    class func deleteData(tableName: String, uuidStr: String) -> Void {
        let dataCoreContext = getDataCoreContext()
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: tableName)
        fetch.predicate = NSPredicate(format: "uuid == %@", uuidStr)
        
        do {
            let results = try dataCoreContext.fetch(fetch)
            if results.count > 0 {
                if tableName == self.deviceTableName {
                    let value = results[0]
                    dataCoreContext.delete(value as! NSManagedObject)
                }
            }
            
            try dataCoreContext.save()
        }catch{
            print("查询出错!\(error)")
        }
    }
}
