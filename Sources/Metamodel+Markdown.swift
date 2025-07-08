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
            Strong(Text("Name:")), InlineCode(self.name))
        )

        if !traits.isEmpty {
            let inlined: [[InlineMarkup]] = traits.map { [InlineCode($0.name)] }
            let joined = inlined.joined(separator: [Text(", ")]).compactMap { $0 }
            doc.append(Paragraph(
                [Strong(Text("Traits:"))] + joined
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
        
        doc.append(Markdown.Heading(level: 1, Text("Edge Rules")))
        

        if edgeRules.isEmpty {
            doc.append(Paragraph(
                Text("No edge rules.")
            ))
        }
        else {
            var rows: [Table.Row] = []
            let header = Table.Head(
                Table.Cell(Text("Edge Type")),
                Table.Cell(Text("Origin")),
                Table.Cell(Text("Target")),
                Table.Cell(Text("Cardinality at Origin")),
                Table.Cell(Text("Cardinality at Target"))
            )
            
            for rule in edgeRules {
                var originText: InlineMarkup
                var targetText: InlineMarkup
                
                if let pred = rule.originPredicate {
                    originText = InlineCode(String(describing: pred))
                }
                else {
                    originText = Emphasis(Text("any"))
                }
                if let pred = rule.targetPredicate {
                    targetText = InlineCode(String(describing: pred))
                }
                else {
                    targetText = Emphasis(Text("any"))
                }

                let row = Table.Row(
                    Table.Cell(Text(rule.type.name)),
                    Table.Cell(originText),
                    Table.Cell(targetText),
                    Table.Cell(Text("from \(rule.outgoing)")),
                    Table.Cell(Text("to \(rule.incoming)"))
                )
                rows.append(row)

            }
            let table = Table(columnAlignments: [.left, .left, .left, .center, .center],
                              header: header, body: Table.Body(rows))
            
            doc.append(table)

        }
        
        doc.append(Markdown.Heading(level: 1, Text("Constraints")))
        
        if constraints.isEmpty {
            doc.append(Paragraph(
                Text("No constraints.")
            ))
        }
        else {
            var rows: [Table.Row] = []

            let header = Table.Head(
                Table.Cell(Text("Name")),
                Table.Cell(Text("Description"))
            )
            
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
