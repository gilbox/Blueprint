import UIKit

/// Conforming types can calculate layout attributes for an array of children.
public protocol SingleChildLayout {
    
    /// TODO
    func layout2(in constraint : SizeConstraint, child : MeasurableLayout) -> SingleChildLayoutResult
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
