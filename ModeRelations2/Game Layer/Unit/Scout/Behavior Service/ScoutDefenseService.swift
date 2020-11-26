//
//  AttackService.swift
//  ModeRelations2
//
//  Created by Igor Ivanov on 21.11.2020.
//

import Foundation
import Combine



//MARK:- Attack
class ScoutDefenseService: Servicable {
    typealias Input = ScoutEntity
    typealias Output = ScoutEntity
    let serviceID: ServiceID = UUID()
    
    let pub = PassthroughSubject<Output, Never>()

    var representingMode: ModeKey {
        return ScoutMode.defenseMode(.pending(.attack)).getKey()
    }
    
    func subscribe() -> AnyPublisher<Output, Never> {
        return pub.eraseToAnyPublisher()
    }
    
    
    func request(subject: Input?, directive: ServiceDirective) {
        guard let subject = subject else { return }
        
        switch directive {
        case .doAction:
            dispatch(subject)
        case .doBreak:
            print("\(self): BREAK")
            self.pub.send(completion: .finished)
        case .doContinue:
            print("\(self): CONTINUE")
            self.pub.send(subject)
        }
    }

    
    private func dispatch(_ subject: Input) {
        
        switch subject.mode {
            case .defenseMode(.successful(.aim)):
                runAfterAim(subject)
            case .defenseMode(.successful(.reload)):
                runAfterReload(subject)
            break
        default:
            break
        }
    }
}


extension ScoutDefenseService {
    
    func runAfterAim(_ subject: Input) {
        DispatchQueue.global().async {
            print("\nturrel ID: \(subject.id) attack: ACTION_0 🏹")

            ISB_to_CSC(subject: subject, serviceID: self.serviceID) {contexts in
                subject.mode = .defenseMode(.running(.attack))
                self.attack(subject: subject, contexts: &contexts)
            }
            
            if subject.mode == .defenseMode(.successful(.aim)) {
                subject.mode = .defenseMode(.failed(.attack))
            }
            self.pub.send(subject)
        }
    }
    
    
    func runAfterReload(_ subject: Input) {
        DispatchQueue.global().async {
            print("\nturrel ID: \(subject.id) attack: ACTION_1 🏹")
            subject.mode = .defenseMode(.running(.attack))
        
            CSC_to_CSC(serviceID: self.serviceID) {contexts in
                self.attack(subject: subject, contexts: &contexts)
            }
            
            
            if subject.mode == .defenseMode(.running(.attack)) {
                subject.mode = .defenseMode(.failed(.attack))
            }
            
            self.pub.send(subject)
        }
    }
    
    
    
    private func attack(subject: Input, contexts: inout [Context]) {
        var needWeaponClipReload = false
        var alliasDestroyed = false
        var killed = false
        
        while(!needWeaponClipReload && !alliasDestroyed && !killed) {
            if let context = contexts.last {
                let enemy = context.object as! MobileAllyProtocol
                
                while(!needWeaponClipReload && enemy.health > 0 && !killed) {
                    

                    
                    
                    subject.curWeaponClip -= 1
                    let closureEffect = context.interactiveClosure
                    
                    if subject.health <= 0 {
                        killed = true
                        break
                    }
                    print("-")
                    
                    enemy.entryPointSend(closureEffect: closureEffect) // отправить контекст
                    needWeaponClipReload = subject.curWeaponClip == 0
                   
                    if enemy.health <= 0 {
                        print("\nscout ID: \(subject.id) destroyed object ID: \(enemy.id) ✌️ \(subject.health)")
                        contexts.popLast()
                    }
                    
                    usleep(100000)
                }
            }
            alliasDestroyed = contexts.count == 0
        }
        
        if killed {
            return
        }
        
        if alliasDestroyed || needWeaponClipReload {
            subject.mode = .defenseMode(.successful(.attack))
        }
    }
}


