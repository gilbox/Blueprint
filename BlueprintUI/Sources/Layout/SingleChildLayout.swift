import UIKit

/// Conforming types can calculate layout attributes for an array of children.
public protocol SingleChildLayout {
    
    /// Computes the size that this layout requires
    ///
    /// - parameter constraint: The size constraint in which measuring should occur.
    /// - parameter child: A `Measurable` representing the single child of this layout.
    ///
    /// - returns: The measured size.
    func measure(in constraint: SizeConstraint, child: Measurable) -> CGSize

    /// Generates layout attributes for the child.
    ///
    /// - parameter size: The size that layout attributes should be generated within.
    ///
    /// - parameter child: A `Measurable` representing the single child of this layout.
    ///
    /// - returns: Layout attributes for the child of this layout.
    func layout(size: CGSize, child: Measurable) -> LayoutAttributes
    
    /// TODO
    func layout2(in constraint : SizeConstraint, child : Measurable) -> SingleChildLayoutResult
}


public struct SingleChildLayoutResult {
    public var size : CGSize
    public var layoutAttributes : LayoutAttributes
    
    public init(
        size : CGSize,
        layoutAttributes : LayoutAttributes
    ) {
        self.size = size
        self.layoutAttributes = layoutAttributes
    }
    
    public init(
        size sizeProvider : () -> CGSize,
        layoutAttributes layoutAttributesProvider : (CGSize) -> LayoutAttributes
    ) {
        let size = sizeProvider()
        let layoutAttributes = layoutAttributesProvider(size)
        
        self.size = size
        self.layoutAttributes = layoutAttributes
    }
}
