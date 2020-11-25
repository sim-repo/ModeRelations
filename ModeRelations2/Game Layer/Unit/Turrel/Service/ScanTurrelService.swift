//
//  TurrelService.swift
//  ModeRelations
//
//  Created by Igor Ivanov on 12.11.2020.
//

import Foundation
import Combine

//MARK:- Scan
class TurrelScanService: Servicable {
    typealias Input = Turrel<TurrelMode>
    typealias Output = Turrel<TurrelMode>
    let serviceID: ServiceID = UUID()
    
    let pub = PassthroughSubject<Output, Never>()

    var representingMode: ModeKey {
        return TurrelMode.scanMode(.pending(.scan)).getKey()
    }
    
    func subscribe() -> AnyPublisher<Output, Never> {
        return pub.eraseToAnyPublisher()
    }
    
    
    func request(subject: Input?, directive: ServiceDirective) {
        
        guard let subject = subject else { return }
        
        switch directive {
            case .doAction:
                subject.mode = .scanMode(.pending(.scan))
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
        print("\nSCAN:        ACTION")
        subject.mode = .scanMode(.running(.scan))
        
        var hasDetection = false
        
        while !hasDetection {
            
            if let objects = getAvailableByDistanceUnits(location: subject.position) {
                subject.mode = .scanMode(.successful(.scan))
                subject.mode = .scanMode(.pending(.identification))
                subject.mode = .scanMode(.running(.identification))
                
                if let contexts: AllInteractiveContextTuple = tryGetAllInteractivityContext(subject: subject, objects: objects) {
                    completeWithInteractivy(subject, contexts: contexts)
                    hasDetection = true
                    return
                }
                
                if let exceptionMode = tryGetIfExceptionMode(subject: subject, objects: objects) {
                    completeWithException(subject, exceptionNextMode: exceptionMode)
                    hasDetection = true
                    return
                }
            }
            
        } //while
    }
    
    
    func completeWithInteractivy(_ subject: Input, contexts: AllInteractiveContextTuple) {
        DispatchQueue.global().asyncAfter(deadline: .now()+1) {
 
            if let nextModeKey = contexts.0 {
                subject.mode.switchMode(by: nextModeKey) // определяется контекстом
            } else {
                subject.mode = .scanMode(.successful(.identification)) // определяется самим сервисом
            }
             
            pushISB(with: subject.mode.getKey(), context: contexts.1) // результат сохраняем в буфер
            self.pub.send(subject)
        }
    }
    
    
    func completeWithException(_ subject: Input, exceptionNextMode: ModeKey) {
        DispatchQueue.global().asyncAfter(deadline: .now()+1) {
            subject.mode.switchMode(by: exceptionNextMode)
            self.pub.send(subject)
        }
    }
    
    
    func completeWithFailed(_ subject: Input) {
        subject.mode = .scanMode(.failed(.scan))
        self.pub.send(subject)
    }
}
