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

    
    //scout:
    let explore = Task(service: ScoutExploreService())
    let back2base = Task(service: ScoutBack2BaseService())
    
    let scoutScan = Task(service: ScoutScanService())
    let scoutAim = Task(service: ScoutAimService())
    let defense = Task(service: ScoutDefenseService())
    let scoutReload = Task(service: ScoutReloadService())
    
    let hide = Task(service: ScoutHideService())
    
    
    
    //turrel:
    let scan = Task(service: TurrelScanService())
    let aim = Task(service: TurrelAimService())
    let attack = Task(service: TurrelAttackService())
    let reload = Task(service: TurrelReloadService())
    
    
    
    init(){
        liveEnemiesRegister[scout.id] = scout
        liveAlliasRegister[turret.id] = turret
        
        configContext()
        
        configTurrelTasks()
        configScoutTasks()
        
        configEffectScout(scout: scout)
        configEffectTurrel(turrel: turret)
        run()
    }
    
    // MARK:- Context
    func configContext(){
        var i1 = InteractiveContext(subject: turret,
                                   with: { $0.mode.getKey(mode: .scanMode(.running(.identification)) )},
                                   into: { $0.mode.getKey(mode: .scanMode(.successful(.identification))  )},
                                   ifException: { $0.mode.getKey()},
                                   usedForce: {$0.selectUsedForce(type: .fire) },
                                   object: scout,
                                   when: nil)
        
        i1.addExceptions(object: scout, except: { $0.mode.getKey(mode: .defenseMode(.successful(.hide))) })
        i1.setWrapper(){scout in
            return {
                scout.health -= self.turret.damage
              //  print("Scout ID: \(scout.id), health: \(scout.health)")
                return scout.selectForceEffect(type: .fired)
            }
        }
        
        addContext(context: i1)
        
        
        
        var i2 = InteractiveContext(subject: scout,
                                   with: { $0.mode.getKey(mode: .defenseMode(.running(.scan)) )},
                                   into: { $0.mode.getKey(mode: .defenseMode(.successful(.scan))  )},
                                   ifException: { $0.mode.getKey()},
                                   usedForce: {$0.selectUsedForce(type: .fire) },
                                   object: turret,
                                   when: nil)
        
        i2.setWrapper(){turret in
            return {
                turret.health -= self.scout.damage
              //  print("Scout ID: \(scout.id), health: \(scout.health)")
                return turret.selectForceEffect(type: .fired)
            }
        }
        
        addContext(context: i2)
    }
    
    
    // MARK:- Tasks
    func configTurrelTasks(){
        scan
            .asyncAfterIf(on: aim, condition: { $0.mode == .scanMode(.successful(.identification)) }, then: .doAction, else_: .doContinue)
            .gotoIf(condition: { $0.mode == .attackMode(.failed(.aim)) }, to: scan, with: .doAction)
            .asyncAfterIf(on: attack, condition: { $0.mode == .attackMode(.successful(.aim)) }, then: .doAction, else_: .doContinue)
            .asyncAfterIf(on: reload, condition: { $0.mode == .attackMode(.successful(.attack)) }, then: .doAction, else_: .doContinue)
            .gotoIf(prevConditionBeing: true, goto: attack, with: .doAction)
            .gotoIf(condition: { $0.mode == .attackMode(.failed(.attack)) }, to: aim, with: .doAction)
    }
    
    func configScoutTasks(){
        explore
            .asyncAfterIf(on: back2base, condition: { $0.mode == .exploreMode(.successful(.explore)) }, then: .doAction, else_: .doContinue)
            
            .asyncAfterIf(on: scoutScan, condition: { $0.mode == .defenseMode(.pending(.scan)) }, then: .doAction, else_: .doContinue)
            .asyncAfterIf(on: scoutAim, condition: { $0.mode == .defenseMode(.successful(.scan)) }, then: .doAction, else_: .doContinue)
            
            .gotoIf(condition: { $0.mode == .defenseMode(.failed(.aim)) }, to: back2base, with: .doAction)
            
            .asyncAfterIf(on: defense, condition: { $0.mode == .defenseMode(.successful(.aim)) }, then: .doAction, else_: .doContinue)
            .asyncAfterIf(on: scoutReload, condition: { $0.mode == .defenseMode(.successful(.attack)) }, then: .doAction, else_: .doContinue)
            .gotoIf(prevConditionBeing: true, goto: defense, with: .doAction)
            .gotoIf(condition: { $0.mode == .defenseMode(.failed(.attack)) }, to: scoutAim, with: .doAction)
    }
    
    
    
    
    func configEffectTurrel(turrel: TurrelEntity){

        turrel.configEntryPoint {resultEffectKey in
            var resultEffect = turrel.getForceEffect(by: resultEffectKey)
            
            // nessesary check
            if turrel.health <= 0 {
                liveAlliasRegister[turrel.id] = nil
                turrel.mode = .destroyed
                turrel.wi?.cancel()
                resultEffect = .destroyed
            }
            
            
            switch resultEffect {
               case .fired:
                    print("turrel ID: \(turrel.id) 💥 " )
               case .destroyed:
                    print("turrel ID: \(turrel.id)  🔥🔥🔥🔥🔥🔥🔥")
            }
        }
        

//
//            .asyncAfterIf(on: hide, condition: { $0.mode == .defenseMode(.successful(.hide)) }, then: .doAction, else_: .doContinue)
        
    }
    
    
    
    func configEffectScout(scout: ScoutEntity){

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
                    ScoutFireDamageEffect(task: self.scoutScan).run(entity: scout)
               case .freezed:
                    print("scout ID: \(scout.id) 🥶 " )
                    ScoutFreezeDamageEffect(task: self.hide).run(entity: scout)
               case .exploded:
                    print("scout ID: \(scout.id) 💥 " )
               case .destroyed:
                    print("scout ID: \(scout.id)  🔥🔥🔥🔥🔥🔥🔥")
            }
        }
        

//
//            .asyncAfterIf(on: hide, condition: { $0.mode == .defenseMode(.successful(.hide)) }, then: .doAction, else_: .doContinue)
        
    }
    
    
    func run(){
        explore.input = scout
        scan.input = turret
    }
}
