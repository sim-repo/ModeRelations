//
//  Scout.swift
//  ReduxTemplate1
//
//  Created by Igor Ivanov on 12.11.2020.
//

import Foundation

typealias ScoutEntity = Scout<ScoutMode>


// MARK:- class
class Scout<ModeType: ModeProtocol>: MobileEnemyUnit<ModeType, ScoutForceSendable, ScoutForceReceivable> {
    var curWeaponClip: Int = 10
    let maxWeaponClip: Int = 10
    let damage: Int = 1
}


// MARK:- mode
enum ScoutMode: ModeProtocol {
    case destroyed
    case defenseMode(StatusType<ScoutDefenseStates>)
    case exploreMode(StatusType<ScoutExploreStates>)
   
    
    static var allCases: [ScoutMode] {
                  [ScoutMode.destroyed]
             +    StatusType.allCases.map(ScoutMode.defenseMode)
             +    StatusType.allCases.map(ScoutMode.exploreMode)
    }
}


// MARK:- states:

enum ScoutDefenseStates: Int, EnumIndexable {
    case hide, reload, attack, aim, scan
}

enum ScoutExploreStates: Int, EnumIndexable {
    case explore, back2Base
}



// MARK:- forces:
enum ScoutForceReceivable: ForceEffectProtocol {
    case fired, freezed, exploded, destroyed
}


enum ScoutForceSendable: UsedForceProtocol {
    case fire, freeze, electro
}

