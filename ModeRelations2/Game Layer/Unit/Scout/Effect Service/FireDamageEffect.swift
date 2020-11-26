//
//  FireDamageService.swift
//  ModeRelations2
//
//  Created by Igor Ivanov on 23.11.2020.
//

import Foundation


import Foundation

class ScoutFireDamageEffect <T:TaskProtocol> where T.Input == ScoutEntity {
    var task: T
    
    init(task: T) {
        self.task = task
    }
    
    func run(entity: ScoutEntity){
        //TODO:
        print("scout ID: \(entity.id)  🔥")
        tryRunTask(entity)
    }
    
    private func tryRunTask(_ entity: ScoutEntity) {
        let serviceModeKey = self.task.service.representingMode
        DispatchQueue.global().sync {
            if serviceModeKey < entity.mode.getKey() {
                entity.mode.switchMode(by: serviceModeKey)
                DispatchQueue.global().async {
                    self.task.input = entity
                }
            }
        }
    }
}
