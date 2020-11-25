//
//  ReloadService.swift
//  ModeRelations2
//
//  Created by Igor Ivanov on 21.11.2020.
//

import Foundation
import Combine


//MARK:- Reload
class TurrelReloadService: Servicable {
    typealias Input = Turrel<TurrelMode>
    typealias Output = Turrel<TurrelMode>
    let serviceID: ServiceID = UUID()
    
    let pub = PassthroughSubject<Output, Never>()
     
    var representingMode: ModeKey {
        return TurrelMode.attackMode(.pending(.reload)).getKey()
    }
    
    func subscribe() -> AnyPublisher<Output, Never> {
        return pub.eraseToAnyPublisher()
    }
    
    
    func request(subject: Input?, directive: ServiceDirective) {
        guard let subject = subject else { return }
        
        switch directive {
            case .doAction:
                subject.mode = .attackMode(.pending(.reload))
                publishWithAction(subject: subject)
            case .doBreak:
                print("\(self): BREAK")
                self.pub.send(completion: .finished)
            case .doContinue:
            //    print("\(self): CONTINUE")
                self.pub.send(subject)
        }
    }


    func publishWithAction(subject: Input) {
        print("\nRELOAD:        ACTION")
        subject.mode = .attackMode(.running(.reload))
        
        //changes state
       // DispatchQueue.global().asyncAfter(deadline: .now()+0.5) {
            subject.curWeaponClip = subject.maxWeaponClip
            subject.mode = .attackMode(.successful(.reload))
            self.pub.send(subject)
        //}
    }
}
