//
//  Entity.swift
//  ModeRelations
//
//  Created by Igor Ivanov on 12.11.2020.
//

import Foundation
import Combine


typealias EntityID = Int
typealias KindID = EntityType




enum EntityType: Int {
    case turrel, scout
}


// рутовый протокол для всех сущностей
protocol UnitProtocol: class {
    var id: EntityID { get set }
    var kindID: KindID { get set }
}


// протокол для сущностей, которые могут работать в разных режимах
protocol StatefulUnitProtocol: UnitProtocol {
    func getModeKey() -> ModeKey
    func entryPointSend(closureEffect: @escaping InteractiveClosureType)
}

// протокол для сущностей, которые (с которыми) могут взаимодействовать другие сущности
protocol Interactable: StatefulUnitProtocol {
    associatedtype ModeType

    var mode: ModeType { get set }
    
    var statePublisher: PassthroughSubject<ModeKey,Never>{ get set }
    func onChangeState() -> AnyPublisher<ModeKey,Never>
}


extension Interactable {
    func onChangeState() -> AnyPublisher<ModeKey,Never> {
        return statePublisher.eraseToAnyPublisher()
    }
    
    func send(modeKey: ModeKey) {
        statePublisher.send(modeKey)
    }
}



// нужен, чтобы убрать boiler-plate из каждой сущности
class Entity<ModeType: ModeProtocol, SubjectUsedForce: UsedForceProtocol, ObjectResultingEffect: ForceEffectProtocol>: Interactable {

    typealias InteractiveClosure = InteractiveClosureType
    
    var id: EntityID
    var kindID: KindID

    var mode: ModeType {
        didSet {
            statePublisher.send(mode.getKey())
        }
    }
    var statePublisher = PassthroughSubject<ModeKey, Never>()

    // Force Implementation >>
    var entryPoint = PassthroughSubject<InteractiveClosure, Never>()
    var cancellable = Set<AnyCancellable>()
    // Force Implementation <<
    
    
    var wi: DispatchWorkItem?
    
    init(id: EntityID, kindID: KindID, mode: ModeType) {
        self.id = id
        self.kindID = kindID
        self.mode = mode
    }
    
    func getModeKey() -> ModeKey {
        return mode.getKey()
    }
}


// Force Implementation:
extension Entity {
    
    func entryPointSend(closureEffect: @escaping InteractiveClosure) {
        entryPoint.send(closureEffect)
    }
    

    func selectUsedForce(type: SubjectUsedForce) -> ForceKey {
        type.ordinal() as! Int
    }
    
    
    func selectForceEffect(type: ObjectResultingEffect) -> ResultingEffectKey {
        type.ordinal() as! Int
    }
    
    
    func configEntryPoint(forceEffectHandler: @escaping (ResultingEffectKey) -> Void) {
        entryPoint.eraseToAnyPublisher()
            .sink(receiveValue: {closureEffect in
                let forceEffectKey = closureEffect()
                forceEffectHandler(forceEffectKey)
            })
            .store(in: &cancellable)
    }
    
    func getForceEffect(by key: ResultingEffectKey) -> ObjectResultingEffect {
        return ObjectResultingEffect.allCases[key as! ObjectResultingEffect.AllCases.Index]
    }
}


