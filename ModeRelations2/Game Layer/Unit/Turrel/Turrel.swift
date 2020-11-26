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
class Turrel<ModeType: ModeProtocol>: MobileEnemyUnit<ModeType,TurrelForceSendable,TurrelForceReceivable> {
    var curWeaponClip: Int = 10
    let maxWeaponClip: Int = 10
    let damage: Int = 1
}


// MARK:- mode
enum TurrelMode: ModeProtocol {
    case destroyed
    case scanMode(StatusType<TurrelScanStates>)
    case attackMode(StatusType<TurrelAttackStates>)
    
    static var allCases: [TurrelMode] {
                [TurrelMode.destroyed]
            +   StatusType.allCases.map(TurrelMode.scanMode)
            +   StatusType.allCases.map(TurrelMode.attackMode)
    }
}


// MARK:- states:

enum TurrelDestroyedStates: Int, EnumIndexable {
    case destroyed
}

enum TurrelScanStates: Int, EnumIndexable {
    case scan, identification
}

enum TurrelAttackStates: Int, EnumIndexable {
    case aim, attack, reload
}



// MARK:- forces:
enum TurrelForceReceivable: ForceEffectProtocol {
    case fired, freezed, exploded
}


enum TurrelForceSendable: UsedForceProtocol {
    case fire, freeze, electro
}

