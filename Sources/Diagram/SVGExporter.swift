//
//  SVGExporter.swift
//  poietic
//
//  Created by Stefan Urbanek on 01/08/2025.
//

import Diagramming
import PoieticCore


struct SVGDiagramStyle {
    var pictogramLineWidth: Double = 1.0
}

class SVGDiagramExporter {
    /// Prefix for `id` attribute of SVG symbols representing a pictogram.
    ///
    public var pictogramSymbolIDPrefix = "pictogram-"
    
    /// Prefix of the `id` attribute of diagram blocks.
    ///
    /// If the `id` attribute of a block is not nil, then the `id` attribute of the SVG element
    /// representing the block will be the prefix followed by the block ID.
    ///
    public var blockIDPrefix = "block-"
    
    /// Prefix of the `id` attribute of diagram connectors.
    ///
    /// If the `id` attribute of a connector is not nil, then the `id` attribute of the SVG element
    /// representing the connector will be the prefix followed by the block ID.
    ///
    public var connectorIDPrefix = "connector-"
    
    var bbox: Rect2D
    var elements: [SVGElement]
    var symbols: [String:SVGSymbol]
    var style: SVGDiagramStyle
    
    init(style: SVGDiagramStyle = SVGDiagramStyle()) {
        self.bbox = Rect2D()
        self.elements = []
        self.symbols = [:]
        self.style = style
    }
    
    func export(diagram: Diagram, to path: String) throws {
        let image = try export(diagram: diagram)
        let writer = SVGWriter()
        try writer.writeToFile(image, path: path)
    }
    
    func export(diagram: Diagram) throws -> SVGImage {
        let image = SVGImage()
        
        for block in diagram.blocks {
            composeBlock(block)
        }
        for connector in diagram.connectors {
            composeConnector(connector)
        }
        
        for symbol in symbols.values {
            image.addChild(symbol)
        }
        for element in elements {
            image.addChild(element)
        }
        image.width = bbox.width
        image.height = bbox.height
        
        return image
    }
    
    public func symbolForPictogram(_ pictogram: Pictogram) -> SVGSymbol {
        let name = pictogram.name
        if let symbol = symbols[name] {
            return symbol
        }
        
        let path = SVGPath(pictogram.path)
        path.fill = "none"
        path.stroke = "black"
        path.strokeWidth = style.pictogramLineWidth
        
        let group = SVGGroup()
        group.addChild(path)
        
        let symbol = SVGSymbol()
        symbol.addChild(group)
        
        symbol.id = "\(pictogramSymbolIDPrefix)\(name)"
        
        symbols[name] = symbol
        
        return symbol
    }
    
    func composeBlock(_ block: Block) {
        let LabelFontFamily = "IBM Plex Sans"
        let SecondaryLabelFontFamily = "IBM Plex Sans"
        let LabelOffset: Double = 20.0
        let SecondaryLabelOffset: Double = 36.0
        
        let result = SVGGroup()
        
        guard let pictogram = block.pictogram else {
            return
        }

        // DEBUG
        let origin = SVGCircle(center: block.position, radius: 5)
        origin.setStyle(fill: "none", stroke: "lightblue")
        result.addChild(origin)
//
//        let debugBox = SVGRectangle(rect: block.pictogramBoundingBox)
//        debugBox.setStyle(fill: "none", stroke: "red")
//        result.addChild(debugBox)
//
//        let collision = block.collisionShape.toSVGElement()
//        collision.setStyle(fill: "lime", stroke: "green")
//        result.addChild(collision)
        let debug = debugGroup(pictogram,
                               id: "debug-\(block.objectID)",
                               position: block.position)
        if debug.transform == nil {
            debug.transform = SVGTransformList()
        }
        debug.transform?.append(
            .translate(tx: block.position.x,
                       ty: block.position.y)
        )
        result.addChild(debug)

        // MAIN CONTENT
        
        let _ = symbolForPictogram(pictogram)
        let pathBox = pictogram.pathBoundingBox.translated(block.position)
        self.bbox = self.bbox.union(pathBox)
        
        let use = SVGUse()
        use.x = block.position.x
        use.y = block.position.y
        use.href = "#\(pictogramSymbolIDPrefix)\(pictogram.name)"
        use.id = "\(blockIDPrefix)\(block.objectID)"
        
        result.addChild(use)
        
        if let label = block.label {
            let text = SVGText()
            text.textContent = label
            text.x = pathBox.center.x
            // Note: Flip here when using flipped coordinates
            text.y = pathBox.maxY + LabelOffset
            text.fontSize = 18
            text.textAnchor = "middle"
            text.fontFamily = LabelFontFamily
            text.fontWeight = "600"
            result.addChild(text)
        }
        if let label = block.secondaryLabel {
            let text = SVGText()
            text.textContent = label
            text.x = pathBox.center.x
            // Note: Flip here when using flipped coordinates
            text.y = pathBox.maxY + SecondaryLabelOffset
            text.textAnchor = "middle"
            text.fontSize = 14
            text.fontFamily = SecondaryLabelFontFamily
            text.fontStyle = "italic"
            text.fontWeight = "200"
            result.addChild(text)
        }

        
        elements.append(result)
    }
    
    func composeConnector(_ connector: Connector) {
        let paths = connector.paths()
        let group = SVGGroup()
        group.id = "\(connectorIDPrefix)\(connector.objectID)"
        for path in paths {
            let svgPath = SVGPath(path)
            svgPath.fill = "none"
            svgPath.stroke = connector.shapeStyle.lineColor
            group.addChild(svgPath)
        }
        elements.append(group)
    }
    
    func debugGroup(_ pictogram: Pictogram, id: String, position: Vector2D) -> SVGGroup {
        let DebugOriginFill = "salmon"
        let DebugOriginStroke = "red"
        
        let box = pictogram.path.boundingBox!
        let result: SVGGroup = SVGGroup()
        result.id = "debug-\(id)-pictogram"
        
        let bbox = SVGRectangle()
        bbox.x = box.origin.x
        bbox.y = box.origin.y
        bbox.width = box.width
        bbox.height = box.height
        bbox.fill = "none"
        bbox.stroke = "green"
        bbox.strokeWidth = 2.0
        result.addChild(bbox)
        
        let mask = SVGPath(pictogram.mask)
        mask.fill = "azure"
        mask.stroke = "blue"
        mask.strokeWidth = 1.0
        result.addChild(mask)
        
        let shape = pictogram.collisionShape.shape.toSVGElement()
        shape.fill = "none"
        shape.stroke = "orange"
        shape.strokeWidth = 4.0
        shape.transform = SVGTransformList([
            .translate(tx: pictogram.collisionShape.position.x,
                       ty: pictogram.collisionShape.position.y)
        ])
        result.addChild(shape)
        
        return result
    }
}

