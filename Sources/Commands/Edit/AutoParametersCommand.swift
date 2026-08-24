//
//  AutoParametersCommand.swift
//  
//
//  Created by Stefan Urbanek on 04/07/2023.
//

@preconcurrency import ArgumentParser
import PoieticCore
import PoieticFlows

let ParameterResolutionSystems: [System.Type] = [
    ComputationOrderSystem.self,
    NameResolutionSystem.self,
    ExpressionParserSystem.self,
    ParameterResolutionSystem.self,
    ParameterConnectionProposalSystem.self,
]

extension PoieticTool {
    struct AutoParameters: ParsableCommand {
        static let configuration
            = CommandConfiguration(
                commandName: "auto-parameters",
                abstract: "Automatically connect parameter nodes: connect required, disconnect unused"
            )

        @OptionGroup var globalOptions: Options
        @OptionGroup var options: EditOptions

        @Flag(name: [.customLong("verbose"), .customShort("v")],
                help: "Print created and removed edges")
        var verbose: Bool = false

        mutating func run() throws {
            let session = try DesignSession(location: globalOptions.designLocation)
            let world = session.world
            let plane = try session.plane(options.deriveRef)
            world.setPlane(plane)
            
            try world.run(systems: ParameterResolutionSystems)

            guard let proposal: ParameterProposal = world.singleton() else {
                throw ToolError.internalError("No parameter proposal created")
            }
            
            let trans = try session.deriveOrCreate(options.deriveRef)

            for id in proposal.toRemove {
                if verbose,
                   let object = trans[id],
                   case .edge(let origin, let target) = object.topology
                {
                    let originName = trans[origin]?.name ?? "(unnamed)"
                    let targetName = trans[target]?.name ?? "(unnamed)"
                    print("Disconnected parameter \(originName) (\(origin)) from \(targetName) (\(target)), edge: \(object.objectID)")
                }
                trans.removeCascading(id)
            }
            for edgeProposal in proposal.toAdd {
                let edge = trans.createEdge(.Parameter,
                                            origin: edgeProposal.origin,
                                            target: edgeProposal.target)
                if verbose {
                    let originName = trans[edgeProposal.origin]?.name ?? "(unnamed)"
                    let targetName = trans[edgeProposal.target]?.name ?? "(unnamed)"
                    print("Connected parameter \(originName) (\(edgeProposal.origin)) to \(targetName) (\(edgeProposal.target)), edge: \(edge.objectID)")
                }
            }
            

            if proposal.isEmpty {
                print("All parameter connections seem to be ok.")
            }
            else {
                try session.accept(trans, replacing: options.replaceRef, appendHistory: options.appendHistory)
                try session.save()
                print("Added \(proposal.toAdd.count) edges and removed \(proposal.toRemove.count) edges.")
            }
        }
    }

}
