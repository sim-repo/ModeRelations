//
//  AttackTurrelService.swift
//  ModeRelations
//
//  Created by Igor Ivanov on 12.11.2020.
//

import Foundation
import Combine

//MARK:- Aim
class ScoutAimService: Servicable {
    typealias Input = ScoutEntity
    typealias Output = ScoutEntity
    let serviceID: ServiceID = UUID()
    
    let pub = PassthroughSubject<Output, Never>()
    
    var representingMode: ModeKey {
        return ScoutMode.defenseMode(.pending(.aim)).getKey()
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
            case .defenseMode(.successful(.scan)):
                runAfterIdentification(subject)
            case .defenseMode(.successful(.attack)), .defenseMode(.failed(.attack)):
                runAfterAttack(subject)
            break
        default:
            break
        }
    }
}



extension ScoutAimService {
    
    func runAfterIdentification(_ subject: Input) {
        print("\nscout ID: \(subject.id) aim: ACTION_0 🎯")
        ISB_to_ISB_seq(subject: subject, serviceID: serviceID) {contexts in
            subject.mode = .defenseMode(.running(.aim))
            
            // логика выборки приоритетного элемента:
            contexts.sort{$0.object.kindID.rawValue > $1.object.kindID.rawValue} // сортировка, выполняется 1-н раз, тк сервис после идентификации
           
            if let selectedContext =  contexts.first {
   
                subject.mode = .defenseMode(.successful(.aim))
                
                //отдаем контекст в межсервисный буфер
                return selectedContext
            }
            return nil
        }
        self.pub.send(subject)
    }
    
    
    fileprivate func extractedFunc(_ subject: ScoutAimService.Input) {
        CSC_to_ISB_seq(subject: subject, serviceID: serviceID) {context in // извлекаем поэлементно контекст уже из отсортированного списка
            subject.mode = .defenseMode(.successful(.aim))
            //TODO: обработка здесь
            
        }
    }
    
    func runAfterAttack(_ subject: Input) {
        print("\nscout ID: \(subject.id) aim: ACTION_1 🎯")
        subject.mode = .defenseMode(.pending(.aim))
        extractedFunc(subject)
        
        if subject.mode == .defenseMode(.pending(.aim)) {
            subject.mode = .defenseMode(.failed(.aim))
        }
        
        self.pub.send(subject)
    }
}




