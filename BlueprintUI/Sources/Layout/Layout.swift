import UIKit


/// Conforming types can calculate layout attributes for an array of children.
public protocol Layout : AnyLayout {
    
    /// Per-item metadata that is used during the measuring and layout pass.
    associatedtype Traits = ()
    
    /// Returns a default traits object.
    static var defaultTraits: Self.Traits { get }
    
    /// TODO
    func layout2(in constraint : SizeConstraint, items: [LayoutItem<Self>]) -> LayoutResult
}


public protocol AnyLayout {
    func anyLayout2(in constraint : SizeConstraint, items: [Any]) -> LayoutResult
}


extension Layout {
    public func anyLayout2(in constraint : SizeConstraint, items: [Any]) -> LayoutResult {
        self.layout2(in: constraint, items: items as! [LayoutItem<Self>])
    }
}


public struct MeasurableLayout {
    
    private let layout : AnyLayout
    private let items : [Any]
    
    internal init<LayoutType:Layout>(layout : LayoutType, items : [LayoutItem<LayoutType>]) {
        self.layout = layout
        self.items = items
    }
    
    public func layout2(in constraint : SizeConstraint) -> LayoutResult {
        self.layout.anyLayout2(in: constraint, items: self.items)
    }
    
    public func measure2(in constraint : SizeConstraint) -> CGSize {
        let result = self.layout2(in: constraint)
        return result.size
    }
}


extension Layout where Traits == () {
    
    public static var defaultTraits: () {
        return ()
    }
}


public struct LayoutResult {
    
    public var size : CGSize
    public var layoutAttributes : [LayoutAttributes]
    
    public init(
        size : CGSize,
        layoutAttributes : [LayoutAttributes]
    ) {
        self.size = size
        self.layoutAttributes = layoutAttributes
    }
    
    public init(
        size sizeProvider : () -> CGSize,
        layoutAttributes layoutAttributesProvider : (CGSize) -> [LayoutAttributes]
    ) {
        let size = sizeProvider()
        let layoutAttributes = layoutAttributesProvider(size)
        
        self.size = size
        self.layoutAttributes = layoutAttributes
    }
}


public struct LayoutItem<LayoutType:Layout> {
    public var element: Element
    public var content: ElementContent
    public var traits: LayoutType.Traits
    public var key: AnyHashable?
}
