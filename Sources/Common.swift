//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 06/01/2022.
//

import Foundation
import ArgumentParser
import PoieticCore
import SystemPackage

let DefaultDesignLocation = "design.poietic"
let DesignEnvironmentVariable = "POIETIC_DESIGN"

/// Error thrown by the command-line tool.
///
enum ToolError: Error, CustomStringConvertible {
    // TODO: Go through the errors and review (marked with OK are OK)
    // FIXME: Do not have this
    case internalError(Error)
    
    // I/O errors
    case malformedLocation(String)
    case fileDoesNotExist(String)
    case unableToSaveDesign(Error)
    case storeError(PersistentStoreError)
    case foreignFrameError(ForeignFrameError)
    case emptyDesign
    
    // Design errors
    case brokenStructuralIntegrity(StructuralIntegrityError)
    case unnamedObject(ObjectID)

    case validationFailed(DesignIssueCollection)   /* OK */
    case compilationFailed(DesignIssueCollection)  /* OK */
    
    // Simulation errors
    case unknownVariables([String])
    case unknownSolver(String)
    
    // Query errors
    case malformedObjectReference(String)
    case unknownObject(String)
    case nodeExpected(String)
    case unknownFrame(String)
    case frameExists(String)
    case invalidFrameID(String)

    // Editing errors
    case noChangesToUndo
    case noChangesToRedo
    case structuralTypeMismatch(String, String)
    // Metamodel errors
    case unknownObjectType(String)
    
    case invalidAttributeAssignment(String)
    case typeMismatch(String, String, String)

    case frameLoadingError(FrameLoaderError)
    
    public var description: String {
        switch self {
        case .internalError(let error):
            return "Internal error: \(error)"

        case .malformedLocation(let value):
            return "Malformed location: \(value)"
        case .unableToSaveDesign(let value):
            return "Unable to save design. Reason: \(value)"
        case .storeError(let error):
            return "Store error: \(error)"
        case .foreignFrameError(let error):
            return "Foreign frame error: \(error)"
        case .emptyDesign:
            return "The design is empty"

        // Design Errors
        case .brokenStructuralIntegrity(let error):
            return "Broken structural integrity: \(error)"
        case .validationFailed(let error):
            var detail: String = ""
            if !error.designIssues.isEmpty {
                detail += "\(error.designIssues.count) design issues"
            }
            if !error.objectIssues.isEmpty {
                if detail == "" {
                    detail += " "
                }
                detail += "\(error.objectIssues.count) objects with errors"
            }
            if detail == "" {
                detail = "unspecified validation error(s)"
            }
            return "Design validation failed: \(detail)"

        case .compilationFailed(let error):
            var detail: String = ""
            if !error.designIssues.isEmpty {
                detail += "\(error.designIssues.count) design issues"
            }
            if !error.objectIssues.isEmpty {
                if detail == "" {
                    detail += " "
                }
                detail += "\(error.objectIssues.count) objects with errors"
            }
            if detail == "" {
                detail = "unspecified compilation error(s)"
            }
            return "Design compilation failed: \(detail)"


        case .unnamedObject(let id):
            return "Object \(id) has no name"
        case .unknownSolver(let value):
            return "Unknown solver '\(value)'"
        case .unknownVariables(let names):
            let varlist = names.joined(separator: ", ")
            return "Unknown variables: \(varlist)"
        case .malformedObjectReference(let value):
            return "Malformed object reference '\(value). Use either object ID or object identifier."
        case .unknownObject(let value):
            return "Unknown object '\(value)'"
        case .unknownFrame(let value):
            return "Unknown frame: \(value)"
        case .frameExists(let value):
            return "Frame already exists: \(value)"
        case .invalidFrameID(let value):
            return "Invalid frame ID: \(value)"
        case .noChangesToUndo:
            return "No changes to undo"
        case .noChangesToRedo:
            return "No changes to re-do"
        case .structuralTypeMismatch(let given, let expected):
            return "Mismatch of structural type. Expected: \(expected), given: \(given)"
        case .unknownObjectType(let value):
            return "Unknown object type '\(value)'"
        case .nodeExpected(let value):
            return "Object is not a node: '\(value)'"
            
        case .invalidAttributeAssignment(let value):
            return "Invalid attribute assignment: \(value)"
        case .typeMismatch(let subject, let value, let expected):
            return "Type mismatch in \(subject) value '\(value)', expected type: \(expected)"
        case .frameLoadingError(let error):
            return "Frame loading error: \(error)"
        case .fileDoesNotExist(let file):
            return "File '\(file)' not found"
        }
    }
    
    public var hint: String? {
        // NOTE: Keep this list without 'default' so we know which cases we
        //       covered.
        
        switch self {
        case .internalError(_):
            return "Not your fault. Contact the developers with more details - what you did and what the error was"
        case .malformedLocation(_):
            return nil
        case .unableToSaveDesign(_):
            return "Check whether the location is correct and that you have permissions for writing."

        case .brokenStructuralIntegrity(_):
            return "Unfortunately the only way is to inspect the database or a foreign frame. 'doctor' command is not yet implemented."
        case .validationFailed(_):
            return "Make sure that the design is conforming to the metamodel. (In the future there will be 'doctor' command to help you.)"
        case .compilationFailed(_):
            return "Make sure that the design is conforming to the metamodel and the rules of simulation. (In the future there will be 'doctor' command to help you.)"

        case .unknownSolver(_):
            return "Check the list of available solvers by running the 'info' command."
        case .unknownVariables(_):
            return "See the list of available simulation variables using the 'list' command."
        case .unnamedObject(_):
            return "Set object's attribute 'name'"
        case .malformedObjectReference(_):
            return "Use either object ID or object identifier."
        case .unknownObject(_):
            return "See the list of available objects and their names by using the 'list' command."
        case .unknownFrame(_):
            return nil
        case .frameExists(let value):
            return "Use another frame name or ID, or use force to replace existing"
        case .invalidFrameID(_):
            return "The frame ID is malformed. If you are trying to remove a named frame, use the --name flag"
        case .noChangesToUndo:
            return nil
        case .noChangesToRedo:
            return nil
        case .structuralTypeMismatch(_, _):
            return "See the metamodel to know structural type of the object type."
        case .unknownObjectType(_):
            return "See the metamodel for a list of known object types."
        case .nodeExpected(_):
            return nil
        case .invalidAttributeAssignment(_):
            return "Attribute assignment should be in a form: `attribute_name=value`, everything after '=' is considered a value. Ex.: `name=account`, `formula=fish * 10`."
        case .typeMismatch(_, _, _):
            return nil
        case .frameLoadingError(_):
            return nil
        case .fileDoesNotExist(_):
            return nil
        case .foreignFrameError(_):
            return nil
        case .storeError(_):
            return nil
        case .emptyDesign:
            return "Design has no frames, create a frame"
        }
    }

}

/// Parse single-string value assignment into a (attributeName, value) tuple.
///
/// The expected string format is: `attribute_name=value` where the value is
/// everything after the equals `=` character.
///
/// Returns `nil` if the string is malformed and can not be parsed.
///
/// - Note: In the future the format might change to include quotes on both sides
///         of the `=` character. Make sure to use this function instead of
///         splitting the assignment on your own.
///
func parseValueAssignment(_ assignment: String) -> (String, String)? {
    let split = assignment.split(separator: "=", maxSplits: 2)
    if split.count != 2 {
        return nil
    }
    
    return (String(split[0]), String(split[1]))
}

func setAttributeFromString(object: MutableObject,
                            attribute attributeName: String,
                            string: String) throws {
    let type = object.type
    if let attr = type.attribute(attributeName), attr.type.isArray {
        let json = try JSONValue(parsing: string)
        let arrayValue = try Variant(json: json)
        object.setAttribute(value: arrayValue,
                                forKey: attributeName)
    }
    else {
        object.setAttribute(value: Variant(string),
                                forKey: attributeName)
    }

}


// Frame reading
// ====================================================================

func makeFileURL(fromPath path: String) throws (ToolError) -> URL {
    let url: URL
    let manager = FileManager()

    if !manager.fileExists(atPath: path) {
        throw .fileDoesNotExist(path)
    }
    
    // Determine whether the file is a directory or a file
    
    if let attrs = try? manager.attributesOfItem(atPath: path) {
        if attrs[FileAttributeKey.type] as? FileAttributeType == FileAttributeType.typeDirectory {
            url = URL(fileURLWithPath: path, isDirectory: true)
        }
        else {
            url = URL(fileURLWithPath: path, isDirectory: false)
        }
    }
    else {
        url = URL(fileURLWithPath: path)
    }

    return url
}

func readFrame(fromPath path: String) throws (ToolError) -> any ForeignFrameProtocol {
    let reader = JSONFrameReader()
    let foreignFrame: any ForeignFrameProtocol
    let url = try makeFileURL(fromPath: path)
    
    do {
        if url.hasDirectoryPath {
            foreignFrame = try reader.read(bundleAtURL: url)
        }
        else {
            foreignFrame = try reader.read(fileAtURL: url)
        }
    }
    catch {
        throw .foreignFrameError(error)
    }
    return foreignFrame
}

func formatLabelledList(_ items: [(String?, String?)],
                        separator: String = ": ",
                        minimumWidth: Int? = nil) -> [String] {
    let maxWidth = items.map { $0.0?.count ?? 0 }.max() ?? 0
    let width = max(maxWidth, minimumWidth ?? 0)
    
    var result: [String] = []
    
    for (label, value) in items {
        let item: String

        if let label {
            let padding = String(repeating: " ", count: width - label.count)
            if let value {
                item = "\(label)\(padding)\(separator)\(value)"
            }
            else {
                item = "\(label)"
            }
        }
        else {
            if let value {
                let padding = String(repeating: " ", count: width)
                item = "\(padding)\(value)"
            }
            else {
                item = ""
            }
        }
        
        result.append(item)
    }
    
    return result
}

