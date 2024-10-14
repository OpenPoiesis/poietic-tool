//
//  Metamodel+Markdown.swift
//  poietic
//
//  Created by Stefan Urbanek on 14/10/2024.
//

import PoieticCore
import Markdown

extension ObjectType {
    func asMarkdown(level: Int = 1) -> Document {
        var doc: [BlockMarkup] = []

        doc.append(Heading(level: level, Text(self.label)))
        
        doc.append(Paragraph(
            Strong(Text("Name: ")), InlineCode(self.label))
        )

        if !traits.isEmpty {
            let inlined: [[InlineMarkup]] = traits.map { [InlineCode($0.name)] }
            let joined = inlined.joined(separator: [Text(", ")]).flatMap { $0 }
            doc.append(Paragraph(
                [Strong(Text("Traits: "))] + joined
            ))
        }
        
        if let abstract {
            doc.append(Paragraph(
                Text(abstract))
            )
        }

        if attributes.isEmpty {
            doc.append(Paragraph(
                Text("Type "),
                InlineCode(self.name),
                Text(" has no attributes.")
            ))
        }
        else {
            var rows: [Table.Row] = []
            for attr in attributes {
                let required = attr.optional ? Text("") : Text("yes")
                let row = Table.Row(
                    Table.Cell(InlineCode(attr.name)),
                    Table.Cell(Text(attr.label)),
                    Table.Cell(Text(String(describing: attr.type))),
                    Table.Cell(required),
                    Table.Cell(Text(attr.abstract ?? ""))
                )
                rows.append(row)
            }
            
            let header = Table.Head(
                Table.Cell(Text("Attribute")),
                Table.Cell(Text("Label")),
                Table.Cell(Text("Type")),
                Table.Cell(Text("Required")),
                Table.Cell(Text("Description"))
            )
            
            let table = Table(columnAlignments: [.left, .left, .left, .left, .left],
                              header: header, body: Table.Body(rows))
            
            doc.append(table)
        }
        return Document(doc)
    }
}


extension Metamodel {
    func asMarkdown() -> Document {
        var doc: [BlockMarkup] = []
        
        doc.append(Markdown.Heading(level: 1, Text("Types and Components")))
        
        if !nodeTypes.isEmpty {
            doc.append(Markdown.Heading(level: 2, Text("Nodes")))
            for type in nodeTypes {
                let typeDoc = type.asMarkdown(level: 3)
                doc += typeDoc.blockChildren
            }
        }
        
        if !edgeTypes.isEmpty {
            doc.append(Markdown.Heading(level: 2, Text("Edges")))
            for type in edgeTypes {
                let typeDoc = type.asMarkdown(level: 3)
                doc += typeDoc.blockChildren
            }
        }
        
        if !unstructuredTypes.isEmpty {
            doc.append(Markdown.Heading(level: 2, Text("Unstructured Types")))
            for type in unstructuredTypes {
                let typeDoc = type.asMarkdown(level: 3)
                doc += typeDoc.blockChildren
            }
        }
        
        doc.append(Markdown.Heading(level: 1, Text("Constraints")))
        
        if constraints.isEmpty {
            doc.append(Paragraph(
                Text("There are no constraints in this metamodel.")
            ))
        }
        else {
            var rows: [Table.Row] = []
            for constraint in constraints {
                let abstractText: InlineMarkup
                
                if let abstract = constraint.abstract {
                    abstractText = Text(abstract)
                }
                else {
                    abstractText = Emphasis(Text("(no description)"))
                }
                
                let row = Table.Row(
                    Table.Cell(InlineCode(constraint.name)),
                    Table.Cell(abstractText)
                )
                rows.append(row)
            }
            
            let header = Table.Head(
                Table.Cell(Text("Name")),
                Table.Cell(Text("Description"))
            )
            
            let table = Table(columnAlignments: [.left, .left],
                              header: header, body: Table.Body(rows))
            
            doc.append(table)
        }
        
        return Document(doc)
    }
}

extension Constraint {
    func asMarkdown(level: Int = 1) -> Document {
        var doc: [BlockMarkup] = []

        doc.append(Markdown.Heading(level: 2, Text(name)))

        if let abstract {
            doc.append(Paragraph(
                Text(abstract))
            )
        }
        else {
            doc.append(Paragraph(
                Emphasis(Text("Constraint has no description."))
            ))
        }

        return Document(doc)
    }
}
