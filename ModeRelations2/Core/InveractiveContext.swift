//
//  InveractiveContext.swift
//  ModeRelations2
//
//  Created by Igor Ivanov on 19.11.2020.
//

import Foundation
import Combine


typealias ContextID = Int
typealias ForceKey = Int
typealias ForceValue = Int
typealias ResultingEffectKey = Int
typealias InteractiveClosureType = ()->ResultingEffectKey
typealias InteractiveClosureWrapper<Object> = (Object)-> InteractiveClosureType


typealias InteractiveContextTuple = (ModeKey?, ForceKey, InteractiveClosureType)
typealias AllInteractiveContextTuple = (ModeKey?, [Context])


protocol SubjectUsedForceProtocol: CaseIterable, Equatable {}

protocol ObjectResultingEffectProtocol: CaseIterable, Equatable {}


var interactiveContexts: [ContextID:InteractiveContextProtocol] = [:]


enum ContextResult {
    case nextMode(InteractiveContextProtocol)
    case exception(InteractiveContextProtocol)
    case failed
}


protocol InteractiveContextProtocol {
    var contextID: ContextID { get set }
    func getSubjectNextMode() -> ModeKey?
    func getSubjectExceptionalNextMode() -> ModeKey?
    func getObjectAcceptableModes() -> [ModeKey]?
    func getObjectExceptionalModes() -> [ModeKey]?
    
    func getSubjectUsedForce() -> ForceKey
    func getClosure(object: StatefulUnit) -> InteractiveClosureType?
}


struct InteractiveContext<Subject: Interactable, Object: Interactable>: InteractiveContextProtocol where Subject.ModeType: ModeProtocol,
                                                                                           Object.ModeType: ModeProtocol {
    var contextID: ContextID
    var subjectNextModeID: ModeKey? // returns if object being in objectAcceptableModes
    var subjectExceptionalNextModeID: ModeKey? // returns if object being in objectExceptionalModes
    var objectAcceptableModes: [ModeKey]?
    var objectExceptionalModes: [ModeKey]?
    var subjectUsedForce: ForceKey
    var wrapper: InteractiveClosureWrapper<Object>?

    
    init(subject: Subject,
         with beingMode: @escaping (Subject)->ModeKey,
         into nextMode: @escaping (Subject)->ModeKey?,
         ifException exceptionMode: ((Subject)->ModeKey)?,
         usedForce force: @escaping (Subject)->ForceKey,
         object: Object,
         when objectAcceptableModes: ((Object)->ModeKey)?...)  {
        
        contextID = createInteractiveContextKey(subjectKindID: subject.kindID, subjectBeingModeKey: beingMode(subject), objectKindID: object.kindID)
        
        subjectNextModeID = nextMode(subject)
        subjectUsedForce = force(subject)
        
        if let em = exceptionMode {
            subjectExceptionalNextModeID = em(subject)
        }
        
        objectAcceptableModes.forEach {mode in
            if let mode = mode {
                if self.objectAcceptableModes == nil {
                    self.objectAcceptableModes = []
                }
                self.objectAcceptableModes!.append(createModeKey(modeKey: mode(object)))
            }
        }
    }
    
    
    mutating func addExceptions(object: Object, except modes: ((Object)->ModeKey)?...) {
        modes.forEach {mode in
            if let mode = mode {
                if objectExceptionalModes == nil {
                    objectExceptionalModes = []
                }
                objectExceptionalModes!.append(createModeKey(modeKey: mode(object)))
            }
        }
    }
    
    
    func getSubjectNextMode() -> ModeKey? {
        subjectNextModeID
    }
    
    func getSubjectExceptionalNextMode() -> ModeKey? {
        subjectExceptionalNextModeID
    }
    
    func getObjectAcceptableModes() -> [ModeKey]? {
        objectAcceptableModes
    }
    
    func getObjectExceptionalModes() -> [ModeKey]? {
        objectExceptionalModes
    }
    
    func getSubjectUsedForce() -> ForceKey {
        subjectUsedForce
    }
    
    mutating func setWrapper(wrapper: @escaping InteractiveClosureWrapper<Object> )  {
        self.wrapper = wrapper
    }
    
    func getClosure(object: StatefulUnit) -> InteractiveClosureType? {
        guard let obj = object as? Object else { return nil }
        return wrapper?(obj)
    }
}


func addContext(context: InteractiveContextProtocol) {
    interactiveContexts[context.contextID] = context
}


//MARK:- Create ContextKey

func createInteractiveContextKey(subjectKindID: KindID, subjectBeingModeKey: ModeKey, objectKindID: KindID) -> ContextID {
    var hasher = Hasher()
    hasher.combine(subjectKindID)
    hasher.combine(subjectBeingModeKey)
    hasher.combine(objectKindID)
    return hasher.finalize()
}


func createModeKey(modeKey: ModeKey) -> ContextID {
    var hasher = Hasher()
    hasher.combine(modeKey)
    return hasher.finalize()
}




//MARK:- Get Interactivity Context

func tryGetAllInteractivityContext(subject: StatefulUnit,objects: [StatefulUnit]) -> AllInteractiveContextTuple? {

    var priorityModeKey: ModeKey = 10000
    var contexts: [Context] = []
    
    objects.forEach {object in
        let result = getContext(by: subject.kindID, with: subject.getModeKey(), by: object.kindID, with: object.getModeKey())

        if let (subjectNextModeKey, subjectUsedForce, interactiveClosure) = tryGetInteractivityContext(result, object: object) {
            
            if let nextModeKey = subjectNextModeKey,
                priorityModeKey > nextModeKey {
                priorityModeKey = nextModeKey
            }
            
            let context = Context(usedForceKey: subjectUsedForce, object: object, interactiveClosure: interactiveClosure)
            contexts.append(context)
        }
    }
    
    let finalSubjectModeKey = priorityModeKey == 1000 ? nil : priorityModeKey

    if contexts.count > 0 {
            return (finalSubjectModeKey, contexts)
    }
    return nil
}



func tryGetInteractivityContext(_ contextResult: ContextResult, object: StatefulUnit) -> InteractiveContextTuple? {
    switch contextResult {
        case .nextMode(let context):
            guard let closure = context.getClosure(object: object) else { return nil }
            return (context.getSubjectNextMode(), context.getSubjectUsedForce(), closure)
        case .failed, .exception(_):
            return nil
    }
}


func getContext(by subjectKindID: KindID, with subjectModeKey: ModeKey, by objectKindID: KindID, with objectBeingModeKey: ModeKey) -> ContextResult {
    
    let contextKey = createInteractiveContextKey(subjectKindID: subjectKindID, subjectBeingModeKey: subjectModeKey, objectKindID: objectKindID)
    
    if let context = interactiveContexts[contextKey] {
        if let exceptModes = context.getObjectExceptionalModes(),
            exceptModes.contains( createModeKey(modeKey: objectBeingModeKey )) {
            return ContextResult.exception(context)
        }
        
        if let allowedModes = context.getObjectAcceptableModes(),
            allowedModes.contains( createModeKey(modeKey: objectBeingModeKey )) {
            return ContextResult.nextMode(context)
        } else {
            return ContextResult.nextMode(context)
        }
    }
    return ContextResult.failed
}





//MARK:- Get Exception Mode

func tryGetIfExceptionMode(subject: StatefulUnit, objects: [StatefulUnit]) -> ModeKey? {
  
    var priorityModeKey: ModeKey = 10000
    
    objects.forEach { object in
        
        let result = getContext(by: subject.kindID, with: subject.getModeKey(), by: object.kindID, with: object.getModeKey())
    
        if let ignoringModeKey = tryGetExceptionMode(result) {
            if priorityModeKey > ignoringModeKey {
                priorityModeKey = ignoringModeKey
            }
        }
    }
    
    if priorityModeKey != 1000 {
        return priorityModeKey
    }
    return nil
}


private func tryGetExceptionMode(_ result: ContextResult) -> ModeKey? {
    switch result {
        case .exception(let context):
            return context.getSubjectExceptionalNextMode()
        default:
            return nil
    }
}
