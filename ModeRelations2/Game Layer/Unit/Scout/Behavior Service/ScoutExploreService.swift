//
//  ScoutExploreService.swift
//  ModeRelations2
//
//  Created by Igor Ivanov on 23.11.2020.
//

import Foundation
import Combine


class ScoutExploreService: Servicable {
    typealias Input = Scout<ScoutMode>
    typealias Output = Scout<ScoutMode>
    let serviceID: ServiceID = UUID()
    let pub = PassthroughSubject<Output, Never>()
    

    var representingMode: ModeKey {
        return ScoutMode.exploreMode(.successful(.explore)).getKey()
    }
    
    func subscribe() -> AnyPublisher<Output, Never> {
        return pub.eraseToAnyPublisher()
    }
    
    func request(subject: Input?, directive: ServiceDirective) {
        guard let subject = subject else { return }
        switch directive {
        case .doAction:
            subject.mode = .exploreMode(.pending(.explore))
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
        print("\nexplore:        ACTION \(subject.id)")
        
        subject.wi = DispatchWorkItem {
            var count = 100000
            
            while count > 0 {
                count -= 1
                usleep(9000000)
                print("explore id: \(subject.id) - \(count)")
                
                if subject.wi!.isCancelled {
                    break
                }
            }
            
            if subject.wi!.isCancelled == false {
                self.pub.send(subject)
            }
        }
        
        DispatchQueue.global().async(execute: subject.wi!)
    }
    
}
