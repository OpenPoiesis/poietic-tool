//
//  Common.swift
//  
//
//  Created by Stefan Urbanek on 06/01/2022.
//

import Foundation
import ArgumentParser
import PoieticCore

let DefaultDesignLocation = "design.poietic"
let DesignEnvironmentVariable = "POIETIC_DESIGN"

/// Error thrown by the command-line tool.
///
enum ToolError: Error, CustomStringConvertible {
    case internalError(String)
    case internalSystemError(InternalSystemError)

    // I/O errors
    case malformedLocation(String)
    case fileDoesNotExist(String)
    case unableToSaveDesign(Error)
    case storeError(DesignStoreError)
    case designReaderError(RawDesignReaderError, URL?)
    case designLoaderError(DesignLoaderError, URL?)
    case unableToWrite(URL, any Error)
    
    // Design errors
    case designIssues([ObjectID:[Issue]])
    case brokenStructuralIntegrity(StructuralIntegrityError)

    case validationFailed(PlaneValidationResult)
    
    // Simulation errors
    case unknownVariables([String])
    case simulationFailed(String)
    
    // Query errors
    /// Thrown by ``DesignSession/plane(_:)``, usually when option `--plane` is invalid.
    case unknownPlane(String)
    /// Thrown by ``DesignSession/plane(_:)`` when no planes was specified, no current plane exists
    /// and there are no planes or more than one plane in the design
    // TODO: Review with emptyDesign and noCurrentPlane
    case planeRequired
    
    case unknownObject(String)
    case nodeExpected(String)
    case planeExists(String)
    
    // Editing errors
    case noChangesToUndo
    case noChangesToRedo
    case topologyTypeMismatch(String, String)
    // Metamodel errors
    case unknownObjectType(String)
    
    case invalidAttributeAssignment(String)
    case typeMismatch(String, String, String)
    case invalidValue(String, String)
    
    public var description: String {
        switch self {
        case .internalError(let message):
            return "Internal error: \(message)"
        case .internalSystemError(let error):
            return "Internal systems error: \(error)"
            
        case .malformedLocation(let value):
            return "Malformed location: \(value)"
        case .unableToSaveDesign(let value):
            return "Unable to save design. Reason: \(value)"
        case .storeError(let error):
            return "Store error: \(error)"
        case .designReaderError(let error, let url):
            if let url {
                if url.isFileURL {
                    return "Unable to read \(url.path()): \(error)"
                }
                else {
                    return "Unable to read \(url): \(error)"
                }
            }
            else {
                return "Unable to read (from unknown source): \(error)"
            }
        case .designLoaderError(let error, let url):
            if let url {
                if url.isFileURL {
                    return "Unable to load \(url.path()): \(error)"
                }
                else {
                    return "Unable to load \(url): \(error)"
                }
            }
            else {
                return "Unable to load (from unknown source): \(error)"
            }

        case .unableToWrite(let url, let error):
            return "Unable to write to \(url): \(error)"

        // Design Errors
        case .brokenStructuralIntegrity(let error):
            return "Broken structural integrity: \(error)"
        case .validationFailed(let error):
            let detail: String = "Constraints violated: " + String(error.violations.count)
            + " object errors: " + String(error.objectErrors.count)
            + " edge rule violations: " + String(error.edgeRuleViolations.count)

            return "Design validation failed: " + detail

        case .designIssues(let issues):
            var detail: String = ""
            if !issues.isEmpty {
                detail += "\(issues.count) objects with errors"
            }
            if detail == "" {
                detail = "unspecified planning error(s)"
            }
            return "Simulation planning failed: \(detail)"

        case .unknownVariables(let names):
            let varlist = names.joined(separator: ", ")
            return "Unknown variables: \(varlist)"
        case .unknownObject(let value):
            return "Unknown object '\(value)'"
        case .unknownPlane(let value):
            return "Unknown plane: \(value)"
        case .planeExists(let value):
            return "Plane already exists: \(value)"
        case .noChangesToUndo:
            return "No changes to undo"
        case .noChangesToRedo:
            return "No changes to re-do"
        case .topologyTypeMismatch(let given, let expected):
            return "Mismatch of topology type. Expected: \(expected), given: \(given)"
        case .unknownObjectType(let value):
            return "Unknown object type '\(value)'"
        case .nodeExpected(let value):
            return "Object is not a node: '\(value)'"
            
        case .invalidAttributeAssignment(let value):
            return "Invalid attribute assignment: \(value)"
        case .typeMismatch(let subject, let value, let expected):
            return "Type mismatch in \(subject) value '\(value)', expected type: \(expected)"
        case .invalidValue(let variable, let value):
            return "Invalid value for \(variable): '\(value)'"
        case .fileDoesNotExist(let file):
            return "File '\(file)' not found"
            
        case .simulationFailed(let message):
            return "Simulation failed: \(message)"
        case .planeRequired:
            return "Plane ID or name required"
        }
    }
    
    public var hint: String? {
        // NOTE: Keep this list without 'default' so we know which cases we
        //       covered.
        
        switch self {
        case .internalError(_),
                .internalSystemError(_):
            return "Not your fault. Contact the developers with more details - what you did and what the error was"
        case .malformedLocation(_):
            return nil
        case .unableToSaveDesign(_):
            return "Check whether the location is correct and that you have permissions for writing."
        case .unableToWrite(_, _):
            return nil

        case .brokenStructuralIntegrity(_):
            return "Unfortunately the only way is to inspect the database. You can try jq tool (third party) to perform surgery"
        case .validationFailed(_):
            return "Make sure that the design is conforming to the metamodel. (In the future there will be 'doctor' command to help you.)"
        case .designIssues(_):
            return "Make sure that the design is conforming to the metamodel and the rules of simulation. (In the future there will be 'doctor' command to help you.)"

        case .unknownVariables(_):
            return "See the list of available simulation variables using the 'list' command."
        case .unknownObject(_):
            return "See the list of available objects and their names by using the 'list' command."
        case .unknownPlane(_):
            return nil
        case .planeExists(_):
            return "Use another plane name or ID, or use force to replace existing"
        case .noChangesToUndo:
            return nil
        case .noChangesToRedo:
            return nil
        case .topologyTypeMismatch(_, _):
            return "See the metamodel to know topology type of the object type"
        case .unknownObjectType(_):
            return "See the metamodel for a list of known object types"
        case .nodeExpected(_):
            return nil
        case .invalidAttributeAssignment(_):
            return "Attribute assignment should be in a form: `attribute_name=value`, everything after '=' is considered a value. Ex.: `name=account`, `formula=fish * 10`."
        case .typeMismatch(_, _, _):
            return nil
        case .invalidValue(_, _):
            return nil
        case .designLoaderError(_, _):
            return "Check the metamodel version and potentially use a design doctor"
        case .designReaderError(_, _):
            return "Check the design source structure and format version"
        case .fileDoesNotExist(_):
            return nil
        case .storeError(_):
            return nil
        case .simulationFailed(_):
            return nil
        case .planeRequired:
            return "Specify --plane"
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
    let split = assignment.split(separator: "=", maxSplits: 1)
    if split.count != 2 {
        return nil
    }
    
    return (String(split[0]), String(split[1]))
}

func setAttributeFromString(object: TransientObject,
                            attribute attributeName: String,
                            string: String) throws (ToolError)
{
    let type: VariableType
    if let attribute = object.type.attribute(attributeName) {
        type = attribute.type
    }
    else {
        type = .any
    }
    
    let variant: Variant
    do {
        variant = try Variant(fromUserString: string, variableType: type)
    }
    catch {
        throw ToolError.invalidValue(attributeName, string)
    }
    object.setAttribute(value: variant, forKey: attributeName)
}

extension Variant {
    init(fromUserString string: String, variableType: VariableType) throws (ValueError) {
        switch variableType {
        case .any:
            do {
                self = try Variant(jsonWithFallback: string)
            }
            catch {
                self = Variant(string)
            }
        case .concrete(let valueType):
            self = try Variant(fromUserString: string, valueType: valueType)
        case .union(let types):
            var lastError = ValueError.invalidUserString(string)
            for type in types {
                do {
                    self = try Variant(fromUserString: string, valueType: type)
                    return
                }
                catch {
                    lastError = error
                }
            }
            throw lastError
        }
    }
    
    init(fromUserString string: String, valueType type: ValueType) throws (ValueError) {
        switch type {
        case .atom(let atomType):
            self = .atom(try VariantAtom(fromUserString: string, type: atomType))
        case .array(let arrayType):
            let value: Variant
            do {
                value = try Variant(jsonWithFallback: string)
            }
            catch {
                throw .invalidUserString(string)
            }
            
            switch arrayType {
            case .bool: self = .array(.bool(try value.boolArray()))
            case .int: self = .array(.int(try value.intArray()))
            case .double: self = .array(.double(try value.doubleArray()))
            case .string: self = .array(.string(try value.stringArray()))
            case .point: self = .array(.point(try value.pointArray()))
            }
        }
    }

}

extension VariantAtom {
    init(fromUserString string: String, type: AtomType) throws (ValueError) {
        let atom = VariantAtom.string(string)
        switch type {
        case .bool: self = .bool(try atom.boolValue())
        case .int: self = .int(try atom.intValue())
        case .double: self = .double(try atom.doubleValue())
        case .string: self = atom
        case .point: self = .point(try atom.pointValue())
        }
    }
}


// Plane reading
// ====================================================================

/// Get the design URL. The database location can be specified by options,
/// environment variable or as a default name, in respective order
func designURL(_ location: String?) throws (ToolError) -> URL {
    let actualLocation: String
    let env = ProcessInfo.processInfo.environment
    
    if let location {
        actualLocation = location
    }
    else if let location = env[DesignEnvironmentVariable] {
        actualLocation = location
    }
    else {
        actualLocation = DefaultDesignLocation
    }
    
    if let url = URL(string: actualLocation) {
        if url.scheme == nil {
            return URL(fileURLWithPath: actualLocation, isDirectory: false)
        }
        else {
            return url
        }
    }
    else {
        throw ToolError.malformedLocation(actualLocation)
    }
}


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

func readRawDesign(fromPath path: String) throws (ToolError) -> RawDesign {
    let reader = JSONDesignReader()
    let design: RawDesign
    let url = try makeFileURL(fromPath: path)
    
    do {
        design = try reader.read(fileAtURL: url)
    }
    catch {
        throw .designReaderError(error, url)
    }
    return design
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
