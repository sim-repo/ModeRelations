//
//  Enums.swift
//  ReduxTemplate1
//
//  Created by Igor Ivanov on 08.11.2020.
//

import Foundation





class TestRule {
    
    init() {
        test()
    }
    
    func test() {
        let turret = TurrelEntity(id: 0, kindID: .turrel, mode: .scanMode(.running(.identification)) )
        let scout = ScoutEntity(id: 1, kindID: .scout, mode: .exploreMode(.successful(.explore )) )

        
        var i1 = InteractiveContext(subject: turret,
                                   with: { $0.mode.getKey(mode: .scanMode(.running(.identification)) )},
                                   into: { $0.mode.getKey(mode: .attackMode(.pending(.attack))  )},
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

        
        let scout2 = ScoutEntity(id: 3333, kindID: .scout, mode: .exploreMode(.successful(.explore )))
      
        let result = getContext(by: turret.kindID, with: turret.mode.getKey(), by: scout2.kindID, with: scout2.mode.getKey())
        
        switch result {
            case .nextMode(let rule):
                print("next mode: \(rule)")
                guard let nextMode = rule.getSubjectNextMode() else {return}
                turret.mode.switchMode(by: nextMode)
                print(turret.mode)
                
                let res = rule.getClosure(object: scout2)
                print(res?())
                print(scout2.health)
                
            case .exception(let rule):
                print("except: \(rule)")
                let mode = rule.getSubjectExceptionalNextMode()
                
            case .failed:
                print("failed")
        }
    }
    
    
}



