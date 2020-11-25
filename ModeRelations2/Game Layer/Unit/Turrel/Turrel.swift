//
//  Turrel.swift
//  ReduxTemplate1
//
//  Created by Igor Ivanov on 12.11.2020.
//

import UIKit
import Combine

typealias TurrelEntity = Turrel<TurrelMode>


// MARK:- class
class Turrel<ModeType: ModeProtocol>: GameEntity<ModeType,TurrelForceSendable,TurrelForceReceivable> {
    var curWeaponClip: Int = 10
    let maxWeaponClip: Int = 10
    let damage: Int = 1
    var health: Int = 100
}


// MARK:- mode
enum TurrelMode: ModeProtocol {
    case scanMode(StatusType<TurrelScanStates>)
    case attackMode(StatusType<TurrelAttackStates>)
    
    static var allCases: [TurrelMode] {
                StatusType.allCases.map(TurrelMode.scanMode)
            +   StatusType.allCases.map(TurrelMode.attackMode)
    }
}


// MARK:- states:
enum TurrelScanStates: Int, EnumIndexable {
    case scan, identification
}


enum TurrelAttackStates: Int, EnumIndexable {
    case aim, attack, reload
}



// MARK:- forces:
enum TurrelForceReceivable: ObjectResultingEffectProtocol {
    case fired, freezed, exploded
//    func get(by key: ResultingEffectKey) -> TurrelForceReceivable {
//        return Self.allCases[key]
//    }
}


enum TurrelForceSendable: SubjectUsedForceProtocol {
    case fire, freeze, electro
}

