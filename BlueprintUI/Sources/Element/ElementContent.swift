import UIKit

/// Represents the content of an element.
public struct ElementContent : Measurable {

    private let storage: AnyContentStorage

    /// Initializes a new `ElementContent` with the given layout and children.
    ///
    /// - parameter layout: The layout to use.
    /// - parameter configure: A closure that configures the layout and adds children to the container.
    public init<LayoutType: Layout>(layout: LayoutType, configure: (inout ContentStorage<LayoutType>) -> Void = { _ in }) {
        var storage = ContentStorage(layout: layout)
        configure(&storage)
        self.storage = storage
    }

    public var childCount: Int {
        return storage.childCount
    }

    func layoutElementTree(attributes: LayoutAttributes) -> [(identifier: ElementIdentifier, node: LayoutResultNode)] {
        return storage.layoutElementTree(attributes: attributes)
    }
    
    func layout2(in constraint : SizeConstraint) -> LayoutResult {
        self.storage.layout2(in: constraint)
    }
    
    // MARK: Measurable
    
    public func measure(in constraint: SizeConstraint) -> CGSize {
        return storage.measure(in: constraint)
    }
}


extension ElementContent {

    /// Initializes a new `ElementContent` with the given element and layout.
    ///
    /// - parameter element: The single child element.
    /// - parameter layout: The layout that will be used.
    public init(child: Element, layout: SingleChildLayout) {
        self = ElementContent(layout: SingleChildLayoutHost(wrapping: layout)) {
            $0.add(element: child)
        }
    }

    /// Initializes a new `ElementContent` with the given element.
    ///
    /// The given element will be used for measuring, and it will always fill the extent of the parent element.
    ///
    /// - parameter element: The single child element.
    public init(child: Element) {
        self = ElementContent(child: child, layout: PassthroughLayout())
    }

    /// Initializes a new `ElementContent` with no children that delegates to the provided `Measurable`.
    public init(measurable: Measurable) {
        self = ElementContent(
            layout: IntrinsicSizeLayout(measurable: measurable),
            configure: { _ in }
        )
    }

    /// Initializes a new `ElementContent` with no children that delegates to the provided measure function.
    public init(measureFunction: @escaping (SizeConstraint) -> CGSize) {
        struct Measurer: Measurable {
            var _measure: (SizeConstraint) -> CGSize
            func measure(in constraint: SizeConstraint) -> CGSize {
                return _measure(constraint)
            }
        }
        
        self = ElementContent(measurable: Measurer(_measure: measureFunction))
    }

    /// Initializes a new `ElementContent` with no children that uses the provided intrinsic size for measuring.
    public init(intrinsicSize: CGSize) {
        self = ElementContent(measureFunction: { _ in intrinsicSize })
    }

}


fileprivate protocol AnyContentStorage : Measurable {
    var childCount: Int { get }
    func layout2(in constraint : SizeConstraint) -> LayoutResult
    func layoutElementTree(attributes: LayoutAttributes) -> [(identifier: ElementIdentifier, node: LayoutResultNode)]
}


extension ElementContent {

    public struct ContentStorage<LayoutType: Layout> : Measurable, AnyContentStorage {

        /// The layout object that is ultimately responsible for measuring
        /// and layout tasks.
        public var layout: LayoutType

        /// Child elements.
        fileprivate var children: [Child] = []

        init(layout: LayoutType) {
            self.layout = layout
        }
        
        /// Adds the given child element.
        public mutating func add(element: Element, traits: LayoutType.Traits = LayoutType.defaultTraits, key: AnyHashable? = nil) {
            let child = Child(
                element: element,
                content: element.content,
                traits: traits,
                key: key
            )
            
            children.append(child)
        }
        
        fileprivate struct Child {

            var element: Element
            var content: ElementContent
            var traits: LayoutType.Traits
            var key: AnyHashable?
        }
        
        public func measure(in constraint: SizeConstraint) -> CGSize {
            return layout.measure(in: constraint, items: layoutItems)
        }
        
        // MARK: AnyContentStorage
        
        var childCount: Int {
            return children.count
        }
        
        func layout2(in constraint : SizeConstraint) -> LayoutResult {
            let layout = MeasurableLayout(layout: self.layout, items: self.children.map {
                LayoutItem(element: $0.element, content: $0.content, traits: $0.traits, key: $0.key)
            })
            
            return layout.layout2(in: constraint)
        }

        func layoutElementTree(attributes: LayoutAttributes) -> [(identifier: ElementIdentifier, node: LayoutResultNode)] {

            let childAttributes = layout.layout(size: attributes.bounds.size, items: layoutItems)
            
            var identifierFactory = ElementIdentifier.Factory(elementCount: children.count)
            
            return self.children.mapWithIndex { index, _, child in
                let childLayoutAttributes = childAttributes[index]

                let resultNode = LayoutResultNode(
                    element: child.element,
                    layoutAttributes: childLayoutAttributes,
                    content: child.content
                )
                
                let identifier = identifierFactory.nextIdentifier(
                    for: type(of: child.element),
                    key: child.key
                )

                return (identifier: identifier, node: resultNode)
            }
        }

        private var layoutItems: [(LayoutType.Traits, Measurable)] {
            return children.map { ($0.traits, $0.content) }
        }
    }
    
    public struct ChildLayoutResult {
        var identifier : ElementIdentifier
        var node : LayoutResultNode
    }
}


// All layout is ultimately performed by the `Layout` protocol – this implementations delegates to a wrapped
// `SingleChildLayout` implementation for use in elements with a single child.
fileprivate struct SingleChildLayoutHost: Layout {

    private var wrapped: SingleChildLayout

    init(wrapping layout: SingleChildLayout) {
        self.wrapped = layout
    }

    func measure(in constraint: SizeConstraint, items: [(traits: (), content: Measurable)]) -> CGSize {
        precondition(items.count == 1)
        return wrapped.measure(in: constraint, child: items.map { $0.content }.first!)
    }

    func layout(size: CGSize, items: [(traits: (), content: Measurable)]) -> [LayoutAttributes] {
        precondition(items.count == 1)
        
        let item = items[0]
        
        return [
            wrapped.layout(size: size, child: item.content)
        ]
    }
    
    func layout2(in constraint : SizeConstraint, items: [LayoutItem<Self>]) -> LayoutResult {
        precondition(items.count == 1)
        
        let item = items[0]
        
        // TODO: Not passing a child here... I think that's OK since we're using it above, but double check.
        
        return item.content.layout2(in: constraint)
    }
}

// Used for elements with a single child that requires no custom layout
fileprivate struct PassthroughLayout: SingleChildLayout {

    func measure(in constraint: SizeConstraint, child: Measurable) -> CGSize {
        return child.measure(in: constraint)
    }

    func layout(size: CGSize, child: Measurable) -> LayoutAttributes {
        return LayoutAttributes(size: size)
    }
    
    func layout2(in constraint : SizeConstraint, child : MeasurableLayout) -> SingleChildLayoutResult {
        SingleChildLayoutResult(
            size: { child.measure2(in: constraint) },
            layoutAttributes: { LayoutAttributes(size: $0) }
        )
    }
}

// Used for empty elements with an intrinsic size
fileprivate struct IntrinsicSizeLayout: Layout {

    var measurable: Measurable

    func measure(in constraint: SizeConstraint, items: [(traits: (), content: Measurable)]) -> CGSize {
        precondition(items.isEmpty)
        return measurable.measure(in: constraint)
    }

    func layout(size: CGSize, items: [(traits: (), content: Measurable)]) -> [LayoutAttributes] {
        precondition(items.isEmpty)
        return []
    }
    
    public func layout2(in constraint : SizeConstraint, items: [LayoutItem<Self>]) -> LayoutResult {
        precondition(items.isEmpty)

        return LayoutResult(
            size: measurable.measure(in: constraint),
            layoutAttributes: []
        )
    }
}

fileprivate extension Array {
    func mapWithIndex<Mapped>(_ block : (Int, Bool, Element) -> Mapped) -> [Mapped]
    {
        var mapped = [Mapped]()
        mapped.reserveCapacity(self.count)
        
        let count = self.count
        var index : Int = 0
        
        while index < count {
            let element = self[index]
            mapped.append(block(index, index == (count - 1), element))
            index += 1
        }
        
        return mapped
    }
}
