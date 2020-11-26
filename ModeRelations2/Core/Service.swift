//
//  Services.swift
//  ReduxTemplate1
//
//  Created by Igor Ivanov on 04.11.2020.
//

import Foundation
import Combine


typealias ServiceID = UUID

enum ServiceDirective {
    case doAction, doContinue, doBreak
}


protocol ModePriorityPresentable {
    var representingMode: ModeKey { get }
}

protocol Servicable: ModePriorityPresentable {
    associatedtype Output: Interactable
    associatedtype Input: Interactable
    var serviceID: ServiceID { get }
    func subscribe() -> AnyPublisher<Output,Never>
    func request(subject: Input?, directive: ServiceDirective)
}


//MARK:- Context
// контекст взаимодействия между субъектом объекту
// usedForceKey - тип силы, прикладываемый субъектом
// object - объект, на который прикладывает силу субъект
// interactiveClosure - эффект, который получает объект от воздействия силы
class Context: Hashable, Equatable {
    let usedForceKey: ForceKey
    let object: StatefulUnitProtocol
    let interactiveClosure: InteractiveClosureType
    
    init(usedForceKey: ForceKey, object: StatefulUnitProtocol, interactiveClosure: @escaping InteractiveClosureType) {
        self.usedForceKey = usedForceKey
        self.object = object
        self.interactiveClosure = interactiveClosure
    }
    
    static func == (lhs: Context, rhs: Context) -> Bool {
        return true
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}



//MARK: -  СТРУКТУРЫ ДЛЯ ХРАНЕНИЯ СЕРВИСНЫХ ДАННЫХ
/*
 Behavior Services должны уметь передавать друг другу данные, например объекты, на которые воздействует субъект.
 Для этой цели служит Interservice Buffer.
 
Также необходимо чтобы сервис мог сохранять в локальный кэш данные, чтобы снова вернуться к ним спустя время.
 */


//MARK: Service Object Cache
// сервис сохраняет объекты, с кот. он работал, чтобы спустя время продолжить с ними работу
// пример: цикличное выполнение тасков

private var serviceCache: [ServiceID:[StatefulUnitProtocol]] = [:]

func pushServiceCache(with key: ServiceID, objects: [StatefulUnitProtocol]) {
    serviceCache[key] = objects
}

func popServiceCache(by key: ServiceID) -> StatefulUnitProtocol? {
    return serviceCache[key]?.popLast()
}



//MARK:  Context Service Cache
private var сontextServiceCache: [ServiceID:[Context]] = [:]

func pushCSC(with key: ServiceID, contexts: [Context]) {
    сontextServiceCache[key] = contexts
}

func popCSC(by key: ServiceID) -> Context? {
    return сontextServiceCache[key]?.popLast()
}

func getCSC(by key: ServiceID) -> [Context]? {
    if let contexts = сontextServiceCache[key] {
        сontextServiceCache[key] = nil
        return contexts
    }
    return nil
}




//MARK: Interservice Object Buffer
// буфер для обмена объектами между сервисами

private var interserviceObjectBuffer: [ModeKey:[StatefulUnitProtocol]] = [:]

func pushInterserviceObjectBuffer(with key: ModeKey, objects: [StatefulUnitProtocol]) {
    interserviceObjectBuffer[key] = objects
}


func popInterserviceObjectBuffer(by key: ModeKey) -> [StatefulUnitProtocol]? {
    if let context = interserviceObjectBuffer[key] {
        interserviceObjectBuffer[key] = nil
        return context
    }
    return nil
}



//MARK: Interservice Buffer
// буфер для обмена интерактивным контекстом между сервисами

private var interserviceInteractiveBuffer: [ModeKey:[Context]] = [:]


func pushISB(with key: ModeKey, context: [Context]) {
    interserviceInteractiveBuffer[key] = context
}


func getISB(by key: ModeKey) -> [Context]? {
    if let context = interserviceInteractiveBuffer[key] {
        interserviceInteractiveBuffer[key] = nil
        return context
    }
    return nil
}





//MARK:- СТРАТЕГИЯ ОБРАБОТКИ КОНТЕКСТА
/*
 Передавать данные между сервисами или извлекать данные из локального кэша сервиса можно с помощью разных стратегий.
 */


// MARK: Фильтрующие и работающие в цикле:

// Pop Interservice Buffer: извлечение из ISB для промежуточной обработки контекста поэлементно
// предназначены для Сервисов, которые запускаются в цикле и отдают при каждой итерации по одному контексту
func ISB_to_ISB_seq<Entity: Interactable>(subject: Entity, serviceID: ServiceID, popContext: @escaping (inout [Context]) -> Context? ) {
    let oldModeKey = subject.getModeKey()
    
    if var contexts = getISB(by: oldModeKey){  // достаем контексты, отгруженный с пред. сервиса из ISB
        if let selectedContext = popContext(&contexts) { // получаем искомый контекст к передаче др. сервису
            contexts.remove(at: contexts.firstIndex(of: selectedContext)!) //удаляем искомый контекст из общего списка
            pushISB(with: subject.getModeKey(), context: [selectedContext]) //записать искомый контекст в межсервисный буфер
            pushCSC(with: serviceID, contexts: contexts) // записываем общий список в кэш сервиса (CSC)
        }
    }
}


// Pop Context Service Cash: функция для поэлементной работы со списком контекста
func CSC_to_ISB_seq<Entity: Interactable>(subject: Entity, serviceID: ServiceID, handleContext: @escaping (inout Context) -> Void ) {
    if var context = popCSC(by: serviceID)  { // достаем контекст из CSC
        handleContext(&context)  // отдаем на обработку контекст
        pushISB(with: subject.getModeKey(), context: [context]) //записать контекст в межбуферный кэш и передать управление Attack
    }
}



func ISB_to_ISB<Entity: Interactable>(subject: Entity, serviceID: ServiceID, popContext: @escaping (inout [Context]) -> [Context]? ) {
    let oldModeKey = subject.getModeKey()
    
    if var contexts = getISB(by: oldModeKey){
        if let selectedContexts = popContext(&contexts) {
            pushISB(with: subject.getModeKey(), context: selectedContexts)
        }
    }
}



// MARK: Конечные обработчики контекста:

// извлечение из ISB списка контекста для финальной обработки
func sinkISB<Entity: Interactable>(subject: Entity, serviceID: ServiceID, finalHandleContext: @escaping (inout [Context]) -> Void ) {
    let oldModeKey = subject.getModeKey()
    
    if var contexts = getISB(by: oldModeKey){  // достаем контексты, отгруженный с пред. сервиса из ISB
        finalHandleContext(&contexts)
    }
}



// извлечение из ISB списка контекста для seq-обработки
// TASK работает в цикле
func ISB_to_CSC<Entity: Interactable>(subject: Entity, serviceID: ServiceID, handleContext: @escaping (inout [Context]) -> Void ) {
    let oldModeKey = subject.getModeKey()
    if var contexts = getISB(by: oldModeKey){
        
        handleContext(&contexts)
            
        if contexts.count > 0 {
            pushCSC(with: serviceID, contexts: contexts)
        }
    }
}


// извлечение из CSC списка контекста
func CSC_to_CSC(serviceID: ServiceID, handleContexts: @escaping (inout [Context]) -> Void ) {
    if var contexts = getCSC(by: serviceID)  {
        handleContexts(&contexts)
        if contexts.count > 0 {
            pushCSC(with: serviceID, contexts: contexts)
        }
    }
}






//MARK:- СЕРВИСНЫЕ ТАЙМЕРЫ
/*
 Каждый Behavior Service меняет состояние переданного ему субъекта (Entity).
 Иногда изменение субъекта производится асинхронно или в каком-то цикле, при этом нужен способ в любой момент отменить выполнение сервиса,
 например критический сервис должен немедленно выполнить обработку субъекта, тогда старый сервис должен прекратить работу.
 
 В каждый момент времени субъект может обрабатывать только один сервис.
 */


// регистр, в котором содержится ID-субъекта, в данный момент находящийся в процессе обработки одним из сервисов
var subjectBeingHandledRegister: [EntityID] = []

// регистр для активных таймеров
typealias TimerKey = Int
var timerByKeyRegister: [TimerKey:Timer] = [:]

func createTimerKey(entityID: EntityID, serviceID: ServiceID) -> TimerKey {
    var hasher = Hasher()
    hasher.combine(entityID)
    hasher.combine(serviceID)
    return hasher.finalize()
}

