//
//  ScoutBack2BaseService.swift
//  ModeRelations2
//
//  Created by Igor Ivanov on 23.11.2020.
//

import Foundation
import Combine


class ScoutBack2BaseService: Servicable {
    typealias Input = Scout<ScoutMode>
    typealias Output = Scout<ScoutMode>
    let serviceID: ServiceID = UUID()
    let pub = PassthroughSubject<Output, Never>()
    
    var representingMode: ModeKey {
        return ScoutMode.exploreMode(.successful(.back2Base)).getKey()
    }
    
    func subscribe() -> AnyPublisher<Output, Never> {
        return pub.eraseToAnyPublisher()
    }
    
    func request(subject: Input?, directive: ServiceDirective) {
        guard let subject = subject else { return }
        switch directive {
        case .doAction:
            subject.mode = .exploreMode(.pending(.back2Base))
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
    }
}
