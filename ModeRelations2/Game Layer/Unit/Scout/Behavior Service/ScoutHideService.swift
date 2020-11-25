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
        return ScoutMode.exploreMode(.successful(.hide)).getKey()
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
        print("\nhide:        ACTION  subjectID: \(subject.id)")
        subject.wi?.cancel()
        subject.wi?.wait()
        subject.mode = .exploreMode(.successful(.hide))
        subject.wi = DispatchWorkItem {
            var count = 100000
            while count > 0 {
                count -= 1
                usleep(500000)
                print("hide id: \(subject.id) - \(subject.mode)")
            }
        }
        
        DispatchQueue.global().async(execute: subject.wi!)
    }
}
