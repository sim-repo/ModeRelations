//
//  CustomTask.swift
//  ReduxTemplate1
//
//  Created by Igor Ivanov on 04.11.2020.
//

import Foundation
import Combine

//MARK: - Protocols

protocol TaskProtocol {
    associatedtype Input: Interactable
    associatedtype Output: Interactable
    associatedtype Service: Servicable
    
    var input: Input? { get set }
    var cancellable: Set<AnyCancellable> { get set }
    var service: Service { get set }
    
    func tiggerService(with: ServiceDirective, object: Input)
    func setInput(output: Input)
    func setConditionResult(isConditionSuccessful: Bool)
    func setDirectives(then: ServiceDirective, else_: ServiceDirective)
    func setPipeline(pipeline: AnyCancellable)
}



//MARK: - Implements
class Task<T: Servicable>: TaskProtocol {
    
    typealias Input = T.Input
    typealias Output = T.Output
    typealias Service = T
    
    var input: T.Input? {
        didSet {
           // guard let input = input else { return }
            let directive: ServiceDirective = isConditionSuccessful ? then : else_
            service.request(subject: input, directive: directive)
        }
    }
    
    var output: T.Output?
    var service: T
    var cancellable = Set<AnyCancellable>()
    
    
    //condition flow:
    var condition: ((Output)->Bool)?
    var then: ServiceDirective = .doAction
    var else_: ServiceDirective = .doAction
    var isConditionSuccessful = true
    var isMustGoto = false
    
    
    init(service: T) {
        self.service = service
    }
    
    private func reset(){
        isConditionSuccessful = true
        isMustGoto = false
    }
    
    //operators:
    func asyncAfter<S:TaskProtocol>(on: S) -> S  where S.Input == Output {
        let pipeline = service
            .subscribe()
            .delay(for: 0.01, scheduler: RunLoop.main)
            .filter{_ in self.isMustGoto == false}
            .sink(receiveValue: {output in
                    self.output = output
                    self.reset()
                    if let condition = self.condition {
                        self.isConditionSuccessful = condition(output)
                    }
                    on.setConditionResult(isConditionSuccessful: self.isConditionSuccessful)
                    on.setInput(output: output)
            })
        on.setPipeline(pipeline: pipeline)
        return on
    }
    
    
    func asyncAfterIf<S:TaskProtocol>(on task: S,
                                   condition: @escaping (Output)->Bool,
                                   then: ServiceDirective,
                                   else_: ServiceDirective
                                   ) -> S where S.Input == Output {
        self.condition = condition
        task.setDirectives(then: then, else_: else_)
        return asyncAfter(on: task)
    }
    
    
    func gotoIf<S:TaskProtocol>(prevConditionBeing: Bool, goto task: S, with direction: ServiceDirective) -> Self where S.Input == Output{
        let pipeline = service
            .subscribe()
            .filter{_ in
                self.isMustGoto = self.isConditionSuccessful == prevConditionBeing
                return self.isMustGoto}
            .sink(receiveValue: {output in
                task.tiggerService(with: direction, object: output)
            })
        task.setPipeline(pipeline: pipeline)
        return self
    }
    
    
    func gotoIf<S:TaskProtocol>(condition: @escaping (Output)->Bool, to task: S, with direction: ServiceDirective) -> Self where S.Input == Output{
        let pipeline = service
            .subscribe()
            .filter{output in
                self.isMustGoto = condition(output)
                return self.isMustGoto}
            .sink(receiveValue: {output in
                task.tiggerService(with: direction, object: output)
            })
        task.setPipeline(pipeline: pipeline)
        return self
    }
    
    
    func cancelStates(except condition:  @escaping (Output)->Void) -> Self {
        return self
    }
}
 

extension Task {
    
    func tiggerService(with: ServiceDirective, object: Input) {
        service.request(subject: object, directive: with)
    }
    
    func setDirectives(then: ServiceDirective, else_: ServiceDirective) {
        self.then = then
        self.else_ = else_
    }
    
    func setInput(output: Input) {
        input = output
    }
    
    func setConditionResult(isConditionSuccessful: Bool) {
        self.isConditionSuccessful = isConditionSuccessful
    }
    
    func setPipeline(pipeline: AnyCancellable) {
        cancellable.insert(pipeline)
    }
}
