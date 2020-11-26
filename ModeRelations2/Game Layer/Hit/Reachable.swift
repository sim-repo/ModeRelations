//
//  Reachable.swift
//  ModeRelations2
//
//  Created by Igor Ivanov on 26.11.2020.
//

import Foundation


//MARK:- Враги:
// враги активизуются при входе в зону их видимости
func activateEnemies(playerLocation: Location) -> [EnemyProtocol]? {
    let enemies = liveEnemiesRegister.filter{ $1.position == playerLocation }
    return enemies.map{$1}
}


// враги активизуются при входе в зону их видимости
func canPunch(by enemy: EnemyProtocol, playerLocation: Location) -> Bool {
    return true
}


// враги активизуются при входе в зону их видимости
func canKick(by enemy: EnemyProtocol, playerLocation: Location) -> Bool {
    return true
}



//MARK:- Функции для работы с регистром

// получить всех врагов
func getReachableEnemies(playerLocation: Location) -> [EnemyProtocol]? {
    let enemies = liveEnemiesRegister.filter{ $1.position == playerLocation }
    let en = enemies.map{$1}
    return en.count == 0 ? nil : en
}



// получить всех союзных
func getReachableAllias(enemyLocation: Location) -> [MobileAllyProtocol]? {
    let enemies = liveAlliasRegister.filter{ $1.position == enemyLocation }
    let en = enemies.map{$1}
    return en.count == 0 ? nil : en
}

