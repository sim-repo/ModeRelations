//
//  ScoutScanService.swift
//  ModeRelations2
//
//  Created by Igor Ivanov on 27.11.2020.
//

import Foundation
import Combine

//MARK:- Scan
class ScoutScanService: Servicable {
    typealias Input = ScoutEntity
    typealias Output = ScoutEntity
    let serviceID: ServiceID = UUID()
    
    let pub = PassthroughSubject<Output, Never>()

    var representingMode: ModeKey {
        return ScoutMode.defenseMode(.pending(.scan)).getKey()
    }
    
    func subscribe() -> AnyPublisher<Output, Never> {
        return pub.eraseToAnyPublisher()
    }
    
    
    func request(subject: Input?, directive: ServiceDirective) {
        
        guard let subject = subject else { return }
        
        switch directive {
            case .doAction:
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
        
        print("\nscout ID: \(subject.id) scan: ACTION 🕵️‍♂️")
        subject.wi = DispatchWorkItem {
            var hasDetection = false
            subject.mode = .defenseMode(.running(.scan))
            while !hasDetection {
                
                if let objects = getReachableAllias(enemyLocation: subject.position) {
                    subject.mode = .defenseMode(.running(.scan))
                    
                    if let contexts: AllInteractiveContextTuple = tryGetAllInteractivityContext(subject: subject, objects: objects) {
                        self.completeWithInteractivy(subject, contexts: contexts)
                        hasDetection = true
                        return
                    }
                    
                    if let exceptionMode = tryGetIfExceptionMode(subject: subject, objects: objects) {
                        self.completeWithException(subject, exceptionNextMode: exceptionMode)
                        hasDetection = true
                        return
                    }
                }
                if subject.health <= 0 {
                    break
                }
            } //while
        } // DispatchWorkItem
        
        DispatchQueue.global(qos: .userInitiated).async(execute: subject.wi!)
        //DispatchQueue.global().async(execute: subject.wi!)
    }
    
    
    func completeWithInteractivy(_ subject: Input, contexts: AllInteractiveContextTuple) {
       // DispatchQueue.global().asyncAfter(deadline: .now()) {
 
            if let nextModeKey = contexts.0 {
                subject.mode.switchMode(by: nextModeKey) // определяется контекстом
            } else {
                subject.mode = .defenseMode(.successful(.scan)) // определяется самим сервисом
            }
             
            pushISB(with: subject.mode.getKey(), context: contexts.1) // результат сохраняем в буфер
            self.pub.send(subject)
      //  }
    }
    
    
    func completeWithException(_ subject: Input, exceptionNextMode: ModeKey) {
        DispatchQueue.global().asyncAfter(deadline: .now()+1) {
            subject.mode.switchMode(by: exceptionNextMode)
            self.pub.send(subject)
        }
    }
    
    
    func completeWithFailed(_ subject: Input) {
        subject.mode = .defenseMode(.failed(.scan))
        self.pub.send(subject)
    }
}
