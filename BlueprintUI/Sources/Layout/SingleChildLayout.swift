import UIKit

/// Conforming types can calculate layout attributes for an array of children.
public protocol SingleChildLayout {
    
    /// TODO
    func layout(in constraint : SizeConstraint, child : MeasurableChild) -> SingleChildLayoutResult
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
        with constraint : SizeConstraint,
        size sizeProvider : (SizeConstraint) -> CGSize,
        layoutAttributes layoutAttributesProvider : (CGSize) -> LayoutAttributes
    ) {
        let size = sizeProvider(constraint)
        let layoutAttributes = layoutAttributesProvider(constraint.maximum)
        
        self.size = size
        self.layoutAttributes = layoutAttributes
    }
}


/// Please measure me and my son again
public struct MeasurableChild {
    
    private var provider : (SizeConstraint) -> CGSize
    
    init(_ provider : @escaping (SizeConstraint) -> CGSize) {
        self.provider = provider
    }
    
    public func size(in constraint : SizeConstraint) -> CGSize {
        self.provider(constraint)
    }
}
