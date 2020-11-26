//
//  InteractTest.swift
//  ModeRelations2
//
//  Created by Igor Ivanov on 23.11.2020.
//

import Foundation


class InteractService {
    
    let turret = TurrelEntity(id: 0, kindID: .turrel, mode: .scanMode(.running(.identification) ))
    let scout = ScoutEntity(id: 1, kindID: .scout, mode: .exploreMode(.successful(.explore )))
    let scout2 = ScoutEntity(id: 2, kindID: .scout, mode: .exploreMode(.successful(.explore )))

    
    //scout:
    let explore = Task(service: ScoutExploreService())
    let back2base = Task(service: ScoutBack2BaseService())
    let hide = Task(service: ScoutHideService())
    
    
    //turrel:
    let scan = Task(service: TurrelScanService())
    let aim = Task(service: TurrelAimService())
    let attack = Task(service: TurrelAttackService())
    let reload = Task(service: TurrelReloadService())
    
    
    
    init(){
        liveEnemiesRegister[scout.id] = scout
        liveEnemiesRegister[scout2.id] = scout2
        configContext()
        configTurrel()
        configScout(scout: scout)
        configScout(scout: scout2)
        run()
    }
    
    
    func configContext(){
        var i1 = InteractiveContext(subject: turret,
                                   with: { $0.mode.getKey(mode: .scanMode(.running(.identification)) )},
                                   into: { $0.mode.getKey(mode: .scanMode(.successful(.identification))  )},
                                   ifException: { $0.mode.getKey()},
                                   usedForce: {$0.selectUsedForce(type: .fire) },
                                   object: scout,
                                   when: nil)
        
        i1.addExceptions(object: scout, except: { $0.mode.getKey(mode: .exploreMode(.successful(.hide))) })
        i1.setWrapper(){scout in
            return {
                scout.health -= self.turret.damage
              //  print("Scout ID: \(scout.id), health: \(scout.health)")
                return scout.selectForceEffect(type: .fired)
            }
        }
        
        addContext(context: i1)
    }
    
    
    func configTurrel(){
        scan
            .asyncAfterIf(on: aim, condition: { $0.mode == .scanMode(.successful(.identification)) }, then: .doAction, else_: .doContinue)
            .gotoIf(condition: { $0.mode == .attackMode(.failed(.aim)) }, to: scan, with: .doAction)
            .asyncAfterIf(on: attack, condition: { $0.mode == .attackMode(.successful(.aim)) }, then: .doAction, else_: .doContinue)
            .asyncAfterIf(on: reload, condition: { $0.mode == .attackMode(.successful(.attack)) }, then: .doAction, else_: .doContinue)
            .gotoIf(prevConditionBeing: true, goto: attack, with: .doAction)
            .gotoIf(condition: { $0.mode == .attackMode(.failed(.attack)) }, to: aim, with: .doAction)
    }
    
    
    
    
    
    func configScout(scout: ScoutEntity){

        scout.configEntryPoint {resultEffectKey in
            var resultEffect = scout.getForceEffect(by: resultEffectKey)
            
            // nessesary check
            if scout.health <= 0 {
                liveEnemiesRegister[scout.id] = nil
                scout.mode = .destroyed
                scout.wi?.cancel()
                resultEffect = .destroyed
            }
            
            
            switch resultEffect {
               case .fired:
                // TODO: можно путем применение сценария эспертных оценок выбрать режим, например если атакующий имеет меньше здоровья или он слишком медленный
                // Можно вместо hide добавить блок принятия решения (Task), который анализирует возможности (сколько союзниых юнитов рядом, какова сила противника и тп)
                // например: Decision(Scan Enemies, Scan Allies, Scan Health)
                    ScoutFireDamageEffect(task: self.hide).run(entity: scout)
               case .freezed:
                    print("scout ID: \(scout.id) 🥶 " )
                    ScoutFreezeDamageEffect(task: self.hide).run(entity: scout)
               case .exploded:
                    print("scout ID: \(scout.id) 💥 " )
               case .destroyed:
                    print("scout ID: \(scout.id)  🔥🔥🔥🔥🔥🔥🔥")
            }
        }
        
        
        explore
            .asyncAfterIf(on: back2base, condition: { $0.mode == .exploreMode(.successful(.explore)) }, then: .doAction, else_: .doContinue)
            .asyncAfterIf(on: hide, condition: { $0.mode == .defendMode(.successful(.defend)) }, then: .doAction, else_: .doContinue)
        
    }
    
    
    func run(){
        explore.input = scout
        explore.input = scout2
        scan.input = turret
    }
}
