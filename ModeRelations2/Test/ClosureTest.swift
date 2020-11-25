//
//  ClosureTest.swift
//  ModeRelations2
//
//  Created by Igor Ivanov on 19.11.2020.
//

import Foundation


protocol InteractiveClosureProtocol {
    func getClosure(object: StatefulUnit) -> InteractiveClosureType?
}

class ClosureTest {


    struct InteractiveClosure<Object: StatefulUnit>: InteractiveClosureProtocol {
        var contextID: ContextID?
        var wrapper: InteractiveClosureWrapper<Object>?

        mutating func setWrapper(wrapper: @escaping InteractiveClosureWrapper<Object> )  {
            self.wrapper = wrapper
        }

        func getClosure(object: StatefulUnit) -> InteractiveClosureType? {
            guard let obj = object as? Object else { return nil }
            return wrapper?(obj)
        }
    }

    init() {
        test()
    }
    
    func test() {
    
        var interact = InteractiveClosure<TurrelEntity>()
        
        interact.setWrapper() { turrel in
            return {
                print("ID: \(turrel.id)")
                turrel.health -= 4
                return turrel.selectForceEffect(type: .exploded)
            }
        }
        
        let turret2 = TurrelEntity(id: 1, kindID: .turrel, mode: .scanMode(.successful(.identification) ))
        
        let res = interact.getClosure(object: turret2)
        
        print(res?())
        print(turret2.health)
    }
}
