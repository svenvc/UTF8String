Extension { #name : #ByteArray }

{ #category : #'*UTF8String' }
ByteArray >> asUTF8String [
	^ UTF8String on: self
]
