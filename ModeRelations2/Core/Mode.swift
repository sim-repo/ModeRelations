//
//  Entity.swift
//  ReduxTemplate1
//
//  Created by Igor Ivanov on 12.11.2020.
//

import Foundation
import Combine

typealias ModeKey = Int

protocol EnumIndexable: CaseIterable, Equatable {}

public extension CaseIterable where Self: Equatable {
    func ordinal() -> Self.AllCases.Index {
        Self.allCases.firstIndex(of: self)!
    }
}



//MARK:- Mode
protocol ModeProtocol: CaseIterable, Equatable {
    func getKey() -> ModeKey
    func getKey(mode: Self) -> ModeKey
    mutating func switchMode(by key: ModeKey)
}



extension ModeProtocol {
    func getKey() -> ModeKey {
        self.ordinal() as! ModeKey
    }
    
    func getKey(mode: Self) -> ModeKey {
        Self.allCases[mode.ordinal()].ordinal() as! ModeKey
    }
    
    mutating func switchMode(by key: ModeKey) {
        let idx = key as! Self.AllCases.Index
        self = Self.allCases[idx]
    }
}



//MARK:- Status
enum StatusType<State: EnumIndexable>: EnumIndexable {
    
    case successful(State), pending(State), running(State), failed(State)
    
    static var allCases: [StatusType] {
                State.allCases.map(StatusType.successful)
            +   State.allCases.map(StatusType.pending)
            +   State.allCases.map(StatusType.running)
            +   State.allCases.map(StatusType.failed)
    }
}
