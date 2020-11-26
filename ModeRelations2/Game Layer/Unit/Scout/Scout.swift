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
}


// MARK:- mode
enum ScoutMode: ModeProtocol {
    case destroyed
    case exploreMode(StatusType<ScoutExploreStates>)
    case defendMode(StatusType<ScoutDefendStates>)
    
    static var allCases: [ScoutMode] {
                  [ScoutMode.destroyed]
             +    StatusType.allCases.map(ScoutMode.exploreMode)
             +    StatusType.allCases.map(ScoutMode.defendMode)
    }
}


// MARK:- states:

enum ScoutExploreStates: Int, EnumIndexable {
    case hide, explore, back2Base
}

enum ScoutDefendStates: Int, EnumIndexable {
    case move2Base, defend
}


// MARK:- forces:
enum ScoutForceReceivable: ForceEffectProtocol {
    case fired, freezed, exploded, destroyed
}


enum ScoutForceSendable: UsedForceProtocol {
    case fire, freeze, electro
}

