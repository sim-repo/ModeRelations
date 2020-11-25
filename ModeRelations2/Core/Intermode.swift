//
//  Intermode.swift
//  ModeRelations2
//
//  Created by Igor Ivanov on 20.11.2020.
//

import Foundation

/*
Реализация правил самостоятельных переходов субъектом в другой режим в случае отсутствия какого-либо внешнего сигнала.
Пример: в данном режиме субъект исчерпал все ресурсы или выполнил поставленную задачу.
*/

typealias RuleID = Int

// хранит правила для переходов в новый режим
var intermodeRules: [RuleID:ModeKey] = [:]


func addIntermodeRule<Subject: Interactable>(subject: Subject,
                                             with beingMode: @escaping (Subject)->ModeKey,
                                             into nextMode: @escaping (Subject)->ModeKey)
                                                                    where Subject.ModeType: ModeProtocol {
    let ruleID = createIntermodeRuleKey(subject: subject, with: beingMode(subject))
    let subjectNextModeID = nextMode(subject)
    intermodeRules[ruleID] = subjectNextModeID
}


// генерируем хэш-код для вида субъекта в исходном режиме
func createIntermodeRuleKey<Subject: Interactable>(subject: Subject, with beingMode: ModeKey) -> RuleID {
    var hasher = Hasher()
    hasher.combine(subject.kindID)
    hasher.combine(beingMode)
    return hasher.finalize()
}

