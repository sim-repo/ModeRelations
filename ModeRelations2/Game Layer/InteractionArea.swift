//
//  InteractionArea.swift
//  ModeRelations2
//
//  Created by Igor Ivanov on 19.11.2020.
//

import UIKit

typealias Location = CGPoint


func getAvailableByDistanceUnits(location: Location) -> [StatefulUnit]? {
    var res: [StatefulUnit] = []
    unitRegister.forEach {unit in
        if let gameUnit = unit as? MoveableProtocol & StatefulUnit {
            if gameUnit.position == .zero {
                res.append(gameUnit)
            }
        }
    }
    return res.count > 0 ? res : nil
}
