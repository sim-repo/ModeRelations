//
//  Entity+Extensions.swift
//  ModeRelations2
//
//  Created by Igor Ivanov on 22.11.2020.
//

import UIKit

internal protocol MoveableProtocol {
    var position: Location { get set }
}


class GameEntity<ModeType: ModeProtocol, SubjectUsedForce: SubjectUsedForceProtocol, ObjectResultEffect: ObjectResultingEffectProtocol>: Entity<ModeType, SubjectUsedForce, ObjectResultEffect>, MoveableProtocol {
    
    var position: Location = .zero
}


var unitRegister: [Unit] = []
