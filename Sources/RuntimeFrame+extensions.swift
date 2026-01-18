//
//  RuntimeFrame+extensions.swift
//  poietic
//
//  Created by Stefan Urbanek on 07/11/2025.
//

import PoieticCore
import PoieticFlows

extension World {
    /// Get default display name of an object. Try to get simulation object name, then try to fall
    /// back to object name property, then use the default value.
    ///
    /// - Precondition: Object must exist in the frame.
    ///
    public func displayName(of objectID: ObjectID, default defaultName: String = "(unnamed)") -> String {
        if let component: SimulationObjectNameComponent = self.component(for: objectID){
            return component.name
        }
        else {
            let obj = self.frame?[objectID]
            return obj?.name ?? defaultName
        }
    }
}
