//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 04/07/2023.
//

@preconcurrency import ArgumentParser
import PoieticCore
import PoieticFlows

enum ParameterResolutionSchedule: ScheduleLabel {}


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
            let editor = try DesignEditor(location: globalOptions.designLocation)
            let world = editor.world

            let systems = SystemGroup(
                ComputationOrderSystem.self,
                NameResolutionSystem.self,
                ExpressionParserSystem.self,
                ParameterResolutionSystem.self,
                ParameterConnectionProposalSystem.self,
            )
            
            world.setSystems(schedule: ParameterResolutionSchedule.self, systems: systems)
            try world.run(schedule: ParameterResolutionSchedule.self)

            let proposal: ParameterProposal = world.singleton()!
            
            let trans = try editor.deriveOrCreate(options.deriveRef)

            for id in proposal.toRemove {
                if verbose,
                   let object = trans[id],
                   let edge = DesignObjectEdge(object, in: trans)
                {
                    let originName = trans[edge.origin]?.name ?? "(unnamed)"
                    let targetName = trans[edge.target]?.name ?? "(unnamed)"
                    print("Disconnected parameter \(originName) (\(edge.origin)) from \(targetName) (\(edge.target)), edge: \(edge.id)")
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
            
            for id in proposal.toRemove {
                trans.removeCascading(id)
            }
            for edgeProposal in proposal.toAdd {
                trans.createEdge(.Parameter,
                                 origin: edgeProposal.origin,
                                 target: edgeProposal.target)
            }

            if proposal.toAdd.count + proposal.toRemove.count > 0 {
                try editor.accept(trans, replacing: options.replaceRef, appendHistory: options.appendHistory)
                try editor.save()
                print("Added \(proposal.toAdd.count) edges and removed \(proposal.toRemove.count) edges.")
            }
            else {
                print("All parameter connections seem to be ok.")
            }
        }
    }

}
