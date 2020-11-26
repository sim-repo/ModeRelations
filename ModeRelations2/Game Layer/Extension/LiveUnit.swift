//
//  Entity+Extensions.swift
//  ModeRelations2
//
//  Created by Igor Ivanov on 22.11.2020.
//

import UIKit

/*
    Расширение класса Entity
*/

typealias Location = CGPoint
typealias PunchZone = CGRect // зона удара рукой
typealias KickZone = CGRect // зона удара ногой
typealias Dxy = Int // скорость перемещения
typealias Health = Int



protocol LiveUnitProtocol: StatefulUnitProtocol {
    var position: Location { get set }
    var health: Health { get set }
}

    
/*
    Союзники.
*/
protocol MobileAllyProtocol: LiveUnitProtocol {
}


/*
 Враги делятся на мобильные и статичные. Разделение позволит в некоторых случаях перестраивать группу двигающихся врагов.
*/

protocol EnemyProtocol: LiveUnitProtocol {
}

protocol MobileEnemyProtocol: EnemyProtocol {
}

protocol StaticEnemyProtocol: EnemyProtocol {
}



class MobileEnemyUnit<ModeType: ModeProtocol, SubjectUsedForce: UsedForceProtocol, ObjectResultEffect: ForceEffectProtocol>: Entity<ModeType, SubjectUsedForce, ObjectResultEffect>, MobileEnemyProtocol {
    
    var position: Location = .zero
    var health: Health = 100
}


class StaticEnemyUnit<ModeType: ModeProtocol, SubjectUsedForce: UsedForceProtocol, ObjectResultEffect: ForceEffectProtocol>: Entity<ModeType, SubjectUsedForce, ObjectResultEffect>, StaticEnemyProtocol {
    
    var position: Location = .zero
    var health: Health = 100
}


class MobileAllyUnit<ModeType: ModeProtocol, SubjectUsedForce: UsedForceProtocol, ObjectResultEffect: ForceEffectProtocol>: Entity<ModeType, SubjectUsedForce, ObjectResultEffect>, MobileAllyProtocol {
    
    var position: Location = .zero
    var health: Health = 100
}
