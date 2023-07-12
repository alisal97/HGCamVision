
import ARKit

protocol FaceTriggerEvaluatorProtocol {
    func evaluate(_ blendShapes: [ARFaceAnchor.BlendShapeLocation: NSNumber], forDelegate delegate: FaceTriggerDelegate)
}

class SmileEvaluator: FaceTriggerEvaluatorProtocol {
    private var oldValue = false
    private let threshold: Float

    init(threshold: Float) {
        self.threshold = threshold
    }

    func evaluate(_ blendShapes: [ARFaceAnchor.BlendShapeLocation: NSNumber], forDelegate delegate: FaceTriggerDelegate) {
        if let mouthSmileLeft = blendShapes[.mouthSmileLeft], let mouthSmileRight = blendShapes[.mouthSmileRight] {
            let newValue = ((mouthSmileLeft.floatValue + mouthSmileRight.floatValue) / 2.0) >= threshold
            if newValue != oldValue {
                delegate.onSmileDidChange?(smiling: newValue)
                if newValue {
                    delegate.onSmile?()
                }
            }
            oldValue = newValue
        }
    }
}

class BlinkEvaluator: BothEvaluator {
    override func onBoth(delegate: FaceTriggerDelegate, newBoth: Bool) {
        delegate.onBlinkDidChange?(blinking: newBoth)
        if newBoth {
            delegate.onBlink?()
        }
    }

    override func onLeft(delegate: FaceTriggerDelegate, newLeft: Bool) {
        delegate.onBlinkLeftDidChange?(blinkingLeft: newLeft)
        if newLeft {
            delegate.onBlinkLeft?()
        }
    }

    override func onRight(delegate: FaceTriggerDelegate, newRight: Bool) {
        delegate.onBlinkRightDidChange?(blinkingRight: newRight)
        if newRight {
            delegate.onBlinkRight?()
        }
    }

    init(threshold: Float) {
        super.init(threshold: threshold, leftKey: .eyeBlinkLeft, rightKey: .eyeBlinkRight)
    }
}

class BrowDownEvaluator: BothEvaluator {
    override func onBoth(delegate: FaceTriggerDelegate, newBoth: Bool) {
        delegate.onBrowDownDidChange?(browDown: newBoth)
        if newBoth {
            delegate.onBrowDown?()
        }
    }

    init(threshold: Float) {
        super.init(threshold: threshold, leftKey: .browDownLeft, rightKey: .browDownRight)
    }
}

class BrowUpEvaluator: FaceTriggerEvaluatorProtocol {
    private var oldValue = false
    private let threshold: Float

    init(threshold: Float) {
        self.threshold = threshold
    }

    func evaluate(_ blendShapes: [ARFaceAnchor.BlendShapeLocation: NSNumber], forDelegate delegate: FaceTriggerDelegate) {
        if let browInnerUp = blendShapes[.browInnerUp] {
            let newValue = browInnerUp.floatValue >= threshold
            if newValue != oldValue {
                delegate.onBrowUpDidChange?(browUp: newValue)
                if newValue {
                    delegate.onBrowUp?()
                }
            }
            oldValue = newValue
        }
    }
}

class SquintEvaluator: BothEvaluator {
    override func onBoth(delegate: FaceTriggerDelegate, newBoth: Bool) {
        delegate.onSquintDidChange?(squinting: newBoth)
        if newBoth {
            delegate.onSquint?()
        }
    }

    init(threshold: Float) {
        super.init(threshold: threshold, leftKey: .eyeSquintLeft, rightKey: .eyeSquintRight)
    }
}

class BothEvaluator: FaceTriggerEvaluatorProtocol {
    private let threshold: Float
    private let leftKey: ARFaceAnchor.BlendShapeLocation
    private let rightKey: ARFaceAnchor.BlendShapeLocation

    init(threshold: Float, leftKey: ARFaceAnchor.BlendShapeLocation, rightKey: ARFaceAnchor.BlendShapeLocation) {
        self.threshold = threshold
        self.leftKey = leftKey
        self.rightKey = rightKey
    }

    func evaluate(_ blendShapes: [ARFaceAnchor.BlendShapeLocation: NSNumber], forDelegate delegate: FaceTriggerDelegate) {
        let left = blendShapes[leftKey]
        let right = blendShapes[rightKey]

        var newLeft = false
        if let left = left {
            newLeft = left.floatValue >= threshold
        }

        var newRight = false
        if let right = right {
            newRight = right.floatValue >= threshold
        }

        let newBoth = newLeft && newRight
        if newBoth {
            onBoth(delegate: delegate, newBoth: newBoth)
        } else {
            if newLeft {
                onLeft(delegate: delegate, newLeft: newLeft)
            } else if newRight {
                onRight(delegate: delegate, newRight: newRight)
            }
        }
    }

    func onBoth(delegate: FaceTriggerDelegate, newBoth: Bool) {
        // Subclasses should override this method
    }

    func onLeft(delegate: FaceTriggerDelegate, newLeft: Bool) {
        // Subclasses should override this method
    }

    func onRight(delegate: FaceTriggerDelegate, newRight: Bool) {
        // Subclasses should override this method
    }
}

class MouthPuckerEvaluator: FaceTriggerEvaluatorProtocol {
    private var oldValue = false
    private let threshold: Float

    init(threshold: Float) {
        self.threshold = threshold
    }

    func evaluate(_ blendShapes: [ARFaceAnchor.BlendShapeLocation: NSNumber], forDelegate delegate: FaceTriggerDelegate) {
        if let mouthPucker = blendShapes[.mouthPucker] {
            let newValue = mouthPucker.floatValue >= threshold
            if newValue != oldValue {
                delegate.onMouthPuckerDidChange?(mouthPuckering: newValue)
                if newValue {
                    delegate.onMouthPucker?()
                }
            }
            oldValue = newValue
        }
    }
}
