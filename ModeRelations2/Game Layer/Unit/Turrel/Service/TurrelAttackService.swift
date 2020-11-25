//
//  AttackService.swift
//  ModeRelations2
//
//  Created by Igor Ivanov on 21.11.2020.
//

import Foundation
import Combine



//MARK:- Attack
class TurrelAttackService: Servicable {
    typealias Input = Turrel<TurrelMode>
    typealias Output = Turrel<TurrelMode>
    let serviceID: ServiceID = UUID()
    
    let pub = PassthroughSubject<Output, Never>()

    var representingMode: ModeKey {
        return TurrelMode.attackMode(.pending(.attack)).getKey()
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
            case .attackMode(.successful(.aim)):
                runAfterAim(subject)
            case .attackMode(.successful(.reload)):
                runAfterReload(subject)
            break
        default:
            break
        }
    }
}


extension TurrelAttackService {
    
    func runAfterAim(_ subject: Input) {
        print("\nATTACK:        ACTION  _0")

        ISB_to_CSC(subject: subject, serviceID: serviceID) {contexts in
            subject.mode = .attackMode(.running(.attack))
            self.attack(subject: subject, contexts: &contexts)
        }
        
        if subject.mode == .attackMode(.successful(.aim)) {
            subject.mode = .attackMode(.failed(.attack))
        }
        self.pub.send(subject)
    }
    
    
    func runAfterReload(_ subject: Input) {
        print("\nATTACK:        ACTION  _1")
        subject.mode = .attackMode(.running(.attack))
    
        CSC_to_CSC(serviceID: serviceID) {contexts in
            self.attack(subject: subject, contexts: &contexts)
        }
        
        
        if subject.mode == .attackMode(.running(.attack)) {
            subject.mode = .attackMode(.failed(.attack))
        }
        
        self.pub.send(subject)
    }
    
    
    
    private func attack(subject: Input, contexts: inout [Context]) {
        var needWeaponClipReload = false
        var allDestroyed = false
        
        while(!needWeaponClipReload && !allDestroyed) {
            if let attacked = contexts.popLast() {
            
                while(!needWeaponClipReload) {
                    subject.curWeaponClip -= 1
                    
                    let closureEffect = attacked.interactiveClosure
                    attacked.object.entryPointSend(closureEffect: closureEffect) // отправить контекст
                    
                    // TODO получить обратную связь
        
                    needWeaponClipReload = subject.curWeaponClip == 0
                }
            }
           // allDestroyed = contexts.count == 0
        }
        
        if allDestroyed || needWeaponClipReload {
            subject.mode = .attackMode(.successful(.attack))
        }
    }
}


