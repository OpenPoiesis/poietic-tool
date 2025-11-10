//
//  RuntimeFrame+extensions.swift
//  poietic
//
//  Created by Stefan Urbanek on 07/11/2025.
//

import PoieticCore
import PoieticFlows

extension AugmentedFrame {
    /// Get default display name of an object. Try to get simulation object name, then try to fall
    /// back to object name property, then use the default value.
    ///
    /// - Precondition: Object must exist in the frame.
    ///
    public func displayName(of objectID: ObjectID, default defaultName: String = "(unnamed)") -> String {
        let obj = self[objectID]!
        if let component: SimulationObjectNameComponent = self.component(for: .object(objectID)){
            return component.name
        }
        else {
            return obj.name ?? defaultName
        }

        
    }
}
