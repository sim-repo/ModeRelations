//
//  ScoutHideService.swift
//  ModeRelations2
//
//  Created by Igor Ivanov on 23.11.2020.
//

import Foundation
import Combine


class ScoutHideService: Servicable {
    typealias Input = Scout<ScoutMode>
    typealias Output = Scout<ScoutMode>
    let serviceID: ServiceID = UUID()
    let pub = PassthroughSubject<Output, Never>()
    
    var representingMode: ModeKey {
        return ScoutMode.defenseMode(.successful(.hide)).getKey()
    }
    
    func subscribe() -> AnyPublisher<Output, Never> {
        return pub.eraseToAnyPublisher()
    }
    
    func request(subject: Input?, directive: ServiceDirective) {
        guard let subject = subject else { return }
        switch directive {
        case .doAction:
        //    subject.mode = .exploreMode(.pending(.hide))
            run(subject: subject)
        case .doBreak:
            print("\(self): BREAK")
            self.pub.send(completion: .finished)
        case .doContinue:
            print("\(self): CONTINUE")
            self.pub.send(subject)
        }
    }
    
    
    func run(subject: Input) {
        
        subject.wi?.cancel()
        subject.wi?.wait()
        
        guard subject.mode.getKey() == representingMode else { return } // проверить что субъект находится в согласованном состоянии
        
        print("\nhide ID: \(subject.id) explore: ACTION")
        subject.wi = DispatchWorkItem {
            var count = 100000
            while count > 0 {
                count -= 1
                usleep(500000)
                print("\nhide ID: \(subject.id) explore: ACTION: \(count)")
                
                if subject.health <= 0 {
                    break
                }
            }
        }
        DispatchQueue.global().async(execute: subject.wi!)
    }
}
