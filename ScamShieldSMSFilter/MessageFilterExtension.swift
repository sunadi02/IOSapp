//
//  MessageFilterExtension.swift
//  ScamShieldSMSFilter
//
//  Created by Sunadi on 2026-10-30.
//

import IdentityLookup

final class MessageFilterExtension: ILMessageFilterExtension {}

extension MessageFilterExtension: ILMessageFilterQueryHandling, ILMessageFilterCapabilitiesQueryHandling {

    func handle(_ capabilitiesQueryRequest: ILMessageFilterCapabilitiesQueryRequest, context: ILMessageFilterExtensionContext, completion: @escaping (ILMessageFilterCapabilitiesQueryResponse) -> Void) {
        completion(ILMessageFilterCapabilitiesQueryResponse())
    }

    func handle(_ queryRequest: ILMessageFilterQueryRequest, context: ILMessageFilterExtensionContext, completion: @escaping (ILMessageFilterQueryResponse) -> Void) {
        let response = ILMessageFilterQueryResponse()
        response.action = Self.filterAction(for: queryRequest)
        completion(response)
    }

    static func filterAction(for request: ILMessageFilterQueryRequest) -> ILMessageFilterAction {
        switch SMSFilterDecision.action(for: request.messageBody, sender: request.sender) {
        case .junk: return .junk
        case .none: return ILMessageFilterAction.none
        }
    }
}
