Extension { #name : #String }

{ #category : #'*UTF8String' }
String >> asUTF8String [
	^ UTF8String fromSystemString: self
]
