//
//  ServiceTest.swift
//  ModeRelations2
//
//  Created by Igor Ivanov on 22.11.2020.
//

import Foundation



class ServiceTest {
    
    let turret = TurrelEntity(id: 0, kindID: .turrel, mode: .scanMode(.running(.identification) ))
    let scout = ScoutEntity(id: 1, kindID: .scout, mode: .exploreMode(.successful(.explore )))
    
    init() {
        liveEnemiesRegister[scout.id] = scout
        config()
        test()
    }
    
    
    func config() {
        var i1 = InteractiveContext(subject: turret,
                                   with: { $0.mode.getKey(mode: .scanMode(.running(.identification)) )},
                                   into: { $0.mode.getKey(mode: .scanMode(.successful(.identification))  )},
                                   ifException: { $0.mode.getKey()},
                                   usedForce: {$0.selectUsedForce(type: .fire) },
                                   object: scout,
                                   when: nil)
        
        i1.addExceptions(object: scout, except: { $0.mode.getKey(mode: .exploreMode(.successful(.hide))) })
        i1.setWrapper(){ scout in
            return {
                scout.health -= 4
                print("Scout ID: \(scout.id), health: \(scout.health)")
                return scout.selectForceEffect(type: .fired)
            }
        }
        
        addContext(context: i1)
    }
    
    
    func test() {
        let scan = Task(service: TurrelScanService())
        let aim = Task(service: TurrelAimService())
        let attack = Task(service: TurrelAttackService())
        let reload = Task(service: TurrelReloadService())

        scan
            .asyncAfterIf(on: aim, condition: { $0.mode == .scanMode(.successful(.identification)) }, then: .doAction, else_: .doContinue)
            .asyncAfterIf(on: attack, condition: { $0.mode == .attackMode(.successful(.aim)) }, then: .doAction, else_: .doContinue)
            .asyncAfterIf(on: reload, condition: { $0.mode == .attackMode(.successful(.attack)) }, then: .doAction, else_: .doContinue)
            .gotoIf(prevConditionBeing: true, goto: attack, with: .doAction)
            .gotoIf(condition: { $0.mode == .attackMode(.failed(.attack)) }, to: scan, with: .doAction)
        
        scan.input = turret
    }
}

