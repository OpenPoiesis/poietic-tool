//
//  SVGExporter.swift
//  poietic
//
//  Created by Stefan Urbanek on 01/08/2025.
//

import Diagramming
import PoieticCore

enum DiagramStyle {

    static let DefaultConnector: ConnectorStyle = .thin(
        ThinConnectorStyle(
            headType: .none,
            tailType: .none,
            headSize: 0.0,
            tailSize: 0.0,
            lineType: .straight
        )
    )

    static let ParameterConnector: ConnectorStyle = .thin(
        ThinConnectorStyle(
            headType: .stick,
            tailType: .ball,
            headSize: 10.0,
            tailSize: 5.0,
            lineType: .curved
        )
    )

    static let FlowConnector: ConnectorStyle = .fat(
        FatConnectorStyle(
            headType: .regular,
            tailType: .none,
            headSize: 20.0,
            tailSize: 0.0,
            width: 10.0,
            joinType: .round
        )
    )
    
}

let DefaultPictograms: [Pictogram] = [
    Pictogram("DefaultCircle",
              path: BezierPath(circle: .zero, radius: 25),
              maskShape: CollisionShape(position: .zero, shape: .circle(25.0))),
    Pictogram("DefaultRect",
              path: BezierPath(rect: Rect2D(x: -50, y: -25, width: 100, height: 50)),
              maskShape: CollisionShape(position: .zero, shape: .rectangle(Vector2D(100, 50)))),
    Pictogram("DefaultSquare",
              path: BezierPath(rect: Rect2D(x: -25, y: -25, width: 50, height: 50)),
              maskShape: CollisionShape(position: .zero, shape: .rectangle(Vector2D(50, 50)))),
]

let DefaultPictogramName = "DefaultCircle"

let TypeToPictogramMap: [String:String] = [
    "Stock": "DefaultRect",
    "FlowRate": "DefaultCircle",
    "Auxiliary": "DefaultSquare",
    "GraphicalFunction": "DefaultCircle",
    "Smooth": "DefaultCircle",
    "Delay": "DefaultCircle",
    "Cloud": "DefaultCircle",
]


class DiagramController {
    let diagram: Diagram
    let collection: PictogramCollection
    init(pictograms: PictogramCollection? = nil) {
        self.diagram = Diagram()
        if let pictograms {
            collection = pictograms
        }
        else {
            collection = PictogramCollection([])
        }
    }

    func update(frame: StableFrame) {
        diagram.blocks.removeAll()
        diagram.connectors.removeAll()
        
        let nodes = frame.nodes(withTrait: .DiagramNode)
        for node in nodes {
            let block = makeBlock(node)
            diagram.insertBlock(block)
        }

        let edges = frame.edges(withTrait: .DiagramConnector)
        for edge in edges {
            let connector = makeConnector(edge, frame: frame)
            diagram.insertConnector(connector)
        }
    }
    
    func pictogram(for object: ObjectSnapshot) -> Pictogram {
        if let picto = collection.pictogram(object.type.name) {
            return picto
        }
        else {
            let name = TypeToPictogramMap[object.type.name] ?? DefaultPictogramName
            let pictogram: Pictogram = DefaultPictograms.first {
                $0.name == name
            } ?? DefaultPictograms.first!
            return pictogram
        }
    }
    
    func makeBlock(_ node: ObjectSnapshot) -> Block {
        let block = Block(
            id: node.objectID.intValue,
            position: node.position ?? .zero,
            pictogram: pictogram(for: node),
            label: node.label,
            secondaryLabel: node.secondaryLabel
        )

        return block
    }
    
    func makeConnector(_ edge: EdgeObject, frame: StableFrame) -> Connector {
        let origin = edge.originObject.position ?? .zero
        let target = edge.targetObject.position ?? .zero
        let midpoints: [Point] = (try? edge.object["midpoints"]?.pointArray()) ?? []

        let style: ConnectorStyle
        
        switch edge.object.type.name {
        case "Parameter": style = DiagramStyle.ParameterConnector
        case "Flow": style = DiagramStyle.FlowConnector
        default: style = DiagramStyle.DefaultConnector
        }
        
        let connector = Connector(id: edge.key.intValue,
                                  originPoint: origin,
                                  targetPoint: target,
                                  midpoints: midpoints,
                                  style: style
                                  )

        // FIXME: This is a draft
        guard let originBlock = diagram.blocks.first(where: { $0.id == edge.origin.intValue }) else {
            print("No origin block with ID: \(edge.origin.intValue)")
            return connector
        }
        guard let targetBlock = diagram.blocks.first(where: { $0.id == edge.target.intValue })else {
            print("No target block with ID: \(edge.target.intValue)")
            return connector
        }
        // TODO: [IMPORTANT] remove force unwrap!
        connector.update(originShape: originBlock.pictogram!.collisionShape,
                         originPosition: originBlock.position - originBlock.pictogram!.origin,
                         targetShape: targetBlock.pictogram!.collisionShape,
                         targetPosition: targetBlock.position - targetBlock.pictogram!.origin)

        return connector
    }
}

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
        
        let _ = symbolForPictogram(pictogram)
        let box = pictogram.boundingBox.translated(block.position)
        self.bbox = self.bbox.union(box)
        
        let use = SVGUse()
        use.x = block.position.x - pictogram.origin.x
        use.y = block.position.y - pictogram.origin.y
        use.href = "#\(pictogramSymbolIDPrefix)\(pictogram.name)"
        if let id = block.id {
            use.id = "\(blockIDPrefix)\(id)"
        }
        
        result.addChild(use)
        
        if let label = block.label {
            let text = SVGText()
            text.textContent = label
            text.x = block.pictogramBoundingBox.center.x
            // Note: Flip here when using flipped coordinates
            text.y = block.pictogramBoundingBox.maxY + LabelOffset
            text.fontSize = 18
            text.textAnchor = "middle"
            text.fontFamily = LabelFontFamily
            text.fontWeight = "600"
            result.addChild(text)
        }
        if let label = block.secondaryLabel {
            let text = SVGText()
            text.textContent = label
            text.x = block.pictogramBoundingBox.center.x
            // Note: Flip here when using flipped coordinates
            text.y = block.pictogramBoundingBox.maxY + SecondaryLabelOffset
            text.textAnchor = "middle"
            text.fontSize = 14
            text.fontFamily = SecondaryLabelFontFamily
            text.fontStyle = "italic"
            text.fontWeight = "200"
            result.addChild(text)
        }

        // DEBUG
        let origin = SVGCircle(center: block.position, radius: 5)
        origin.setStyle(fill: "salmon", stroke: "red")
//        result.addChild(origin)

        let debugBox = SVGRectangle(rect: block.pictogramBoundingBox)
        debugBox.setStyle(fill: "none", stroke: "red")
//        result.addChild(debugBox)
        
        elements.append(result)
    }
    
    func composeConnector(_ connector: Connector) {
        let paths = connector.paths()
        let group = SVGGroup()
        if let id = connector.id {
            group.id = "\(connectorIDPrefix)\(id)"
        }
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
        
        // Origin
        let origin = SVGCircle()
        origin.id = "debug-\(id)-origin"
        origin.cx = pictogram.origin.x
        origin.cy = pictogram.origin.y
        origin.fill = DebugOriginFill
        origin.stroke = DebugOriginStroke
        origin.r = 2
        result.addChild(origin)

        let bbox = SVGRectangle()
        bbox.x = box.origin.x
        bbox.y = box.origin.y
        bbox.width = box.width
        bbox.height = box.height
        bbox.fill = "none"
        bbox.stroke = "yellow"
        result.addChild(bbox)
        
        let shape = pictogram.collisionShape.toSVGElement()
        bbox.fill = "none"
        bbox.stroke = "red"
        result.addChild(shape)
        
//        let offset = center - box.center
//        result.transform = SVGTransformList([
//            .translate(tx: origin.x, ty: origin.y),
////            .translate(tx: center.x-picto.origin.x, ty: center.y-picto.origin.y),
//            .translate(tx: offset.x, ty: offset.y),
//        ])
        return result
    }
}

