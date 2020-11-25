//
//  FreezeDamageEffect.swift
//  ModeRelations2
//
//  Created by Igor Ivanov on 23.11.2020.
//

import Foundation
import Combine


class ScoutFreezeDamageEffect <T:TaskProtocol> where T.Input == ScoutEntity {
    
    var task: T
    
    init(task: T) {
        self.task = task
    }
    
    func run(entity: ScoutEntity){
        
        //TODO:
        // run effect
        // check entity.mode priority
        
        let serviceModeKey = task.service.representingMode
        if serviceModeKey < entity.mode.getKey() { // check priority
            task.input = entity
        }
    }
}
