//
//  Scout.swift
//  ReduxTemplate1
//
//  Created by Igor Ivanov on 12.11.2020.
//

import Foundation

typealias ScoutEntity = Scout<ScoutMode>


// MARK:- class
class Scout<ModeType: ModeProtocol>: GameEntity<ModeType, ScoutForceSendable, ScoutForceReceivable> {
    var health: Int = 100
}


// MARK:- mode
enum ScoutMode: ModeProtocol {
    case exploreMode(StatusType<ScoutExploreStates>)
    case defendMode(StatusType<ScoutDefendStates>)
    
    static var allCases: [ScoutMode] {
                 StatusType.allCases.map(ScoutMode.exploreMode)
             +   StatusType.allCases.map(ScoutMode.defendMode)
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
enum ScoutForceReceivable: ObjectResultingEffectProtocol {
    case fired, freezed, exploded
}


enum ScoutForceSendable: SubjectUsedForceProtocol {
    case fire, freeze, electro
}

