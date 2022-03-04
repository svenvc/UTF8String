"
I am UTF8String, a new kind of String.

I hold an ordered collection or sequence of Character objects.

I use variable length UTF8 encoding as my internal representation so that I can offer IO operations with zero cost for binary streams or FFI. This representation is also space efficient.

I use a lazy computed count and index to deal with the variable length encoding. A character count requires a full linear scan. Character based indexing (#at:) needs such a linear scan as well. The index is used to map character to byte offsets every #stride characters to speed things up.  

I know when I am pure ASCII (an important optimization case).

I am readonly (and cannot be modified, I do not understand #at:put:).

I am compatible with the most important classic String API, while encouraging operations that avoid computing the count or index by scanning.

"
Class {
	#name : #UTF8String,
	#superclass : #Object,
	#instVars : [
		'bytes',
		'count',
		'index'
	],
	#category : #UTF8String
}

{ #category : #requirements }
UTF8String class >> empty [
	^ (self on: #[]) beAscii; yourself
]

{ #category : #'instance creation' }
UTF8String class >> fromCharacter: aCharacter [
	| codePoint bytes |
	codePoint := aCharacter asInteger.
	bytes := ByteArray 
		new: (ZnUTF8Encoder default encodedByteCountFor: codePoint) 
		streamContents: [ :out | 
			ZnUTF8Encoder default nextPutCodePoint: codePoint toStream: out ].
	^ self on: bytes
]

{ #category : #'instance creation' }
UTF8String class >> fromSystemString: string [
	^ self on: string utf8Encoded 
]

{ #category : #'instance creation' }
UTF8String class >> on: utf8EncodedBytes [
	^ self new on: utf8EncodedBytes; yourself
]

{ #category : #'instance creation' }
UTF8String class >> streamContents: block [
	| utf8EncodedBytes |
	utf8EncodedBytes := ByteArray streamContents: [ :binaryWriteStream |
		block value: (ZnCharacterWriteStream on: binaryWriteStream) ].
	^ self on: utf8EncodedBytes
]

{ #category : #copying }
UTF8String >> , anotherZnString [
	"Return a new string by concatenating myself with anotherZnString.
	In principle we should do 'Normalization Preserving Concatenation', 
	see https://medium.com/concerning-pharo/an-implementation-of-unicode-normalization-7c6719068f43
	For now, assume we don't need it."
	
	^ self on: self utf8EncodedBytes , anotherZnString utf8EncodedBytes
]

{ #category : #comparing }
UTF8String >> = anotherZnString [
	self == anotherZnString ifTrue: [ ^ true ].
	self class = anotherZnString class ifFalse: [ ^ false ].
	^ bytes = anotherZnString utf8EncodedBytes
]

{ #category : #converting }
UTF8String >> asLowercase [
	^ self collect: [ :each | each asLowercase ]
]

{ #category : #converting }
UTF8String >> asString [
	^ bytes utf8Decoded
]

{ #category : #converting }
UTF8String >> asUppercase [
	^ self collect: [ :each | each asUppercase ]
]

{ #category : #accessing }
UTF8String >> at: characterIndex [
	"Return the Character at characterIndex.
	Signal SubscriptOutOfBounds or CollectionIsEmpty when there is no such character."
	
	self emptyCheck.
	self boundsCheck: characterIndex.
	self isAscii ifTrue: [ ^ (bytes at: characterIndex) asCharacter ].
	^ self encodedCharacterAt: characterIndex
	
]

{ #category : #initialization }
UTF8String >> beAscii [
	count := bytes size.
	index := Array empty
	
]

{ #category : #testing }
UTF8String >> beginsWith: prefixZnString [
	^ bytes beginsWith: prefixZnString utf8EncodedBytes
]

{ #category : #private }
UTF8String >> boundsCheck: characterIndex [
	(characterIndex between: 1 and: self size) 
		ifFalse: [ self errorOutOfBounds: characterIndex ]
]

{ #category : #private }
UTF8String >> byteIndexAt: characterIndex [	
	| byteIndex |
	self isAscii ifTrue: [ ^ characterIndex ].
	byteIndex := characterIndex > self stride
		ifTrue: [ index at: characterIndex - 1 // self stride ]
		ifFalse: [ 1 ].
	characterIndex - 1 \\ self stride timesRepeat: [ 
		byteIndex := byteIndex + (self encodedByteCountAt: byteIndex) ].
	^ byteIndex
	
]

{ #category : #converting }
UTF8String >> capitalized [
]

{ #category : #private }
UTF8String >> characterIndexAt: byteIndex [
	| characterIndex byteCursor |
	self isAscii ifTrue: [ ^ byteIndex ].
	characterIndex := byteCursor := 1.
	index ifNotEmpty: [  
		index 
			findBinaryIndex: [ :x | byteIndex - x ] 
			do: [ :found | ^ (found * self stride) + 1 ] 
			ifNone: [ :lower :upper |
				lower = 0 
			 		ifFalse: [ 
						byteCursor := index at: lower. 
						characterIndex := (lower * self stride) + 1 ] ] ].
	[ byteCursor < bytes size ] whileTrue: [
		byteCursor = byteIndex 
			ifTrue: [ ^ characterIndex ].
		byteCursor := byteCursor + (self encodedByteCountAt: byteCursor).
		characterIndex := characterIndex + 1 ].
	^ 0
]

{ #category : #enumerating }
UTF8String >> collect: block [
	self isEmpty ifTrue: [ ^ self ].
	^ self class streamContents: [ :out |
			self do: [ :each |
				out nextPut: (block value: each) ] ]
]

{ #category : #private }
UTF8String >> computeCountAndIndex [
	self isEmpty ifTrue: [ ^ count := 0 ].
	"the number of characters cannot be larger than the byte size"
	bytes size <= self stride
		ifTrue: [ self computeCountNoIndex ]
		ifFalse: [ self computeCountAndIndexFull ]
]

{ #category : #private }
UTF8String >> computeCountAndIndexFull [
	count := 0.
	index := Array streamContents: [ :out | | byteIndex |
		byteIndex := 1.
		[ byteIndex <= bytes size ] whileTrue: [
			count := count + 1.
			(count > self stride and: [ (count - 1 \\ self stride) = 0 ]) 
				ifTrue: [ out nextPut: byteIndex ].
			byteIndex := byteIndex + (self encodedByteCountAt: byteIndex) ] ]
]

{ #category : #private }
UTF8String >> computeCountNoIndex [
	| byteIndex |
	count := 0.
	index := Array empty.
	byteIndex := 1.
	[ byteIndex <= bytes size ] whileTrue: [
		count := count + 1.
		byteIndex := byteIndex + (self encodedByteCountAt: byteIndex) ]
]

{ #category : #copying }
UTF8String >> copyFrom: startIndex to: stopIndex [
	| startByteIndex stopByteIndex substring |
	self boundsCheck: startIndex. 
	self boundsCheck: stopIndex. 
	startByteIndex := self byteIndexAt: startIndex.
	stopByteIndex := self byteIndexAt: stopIndex.
	stopByteIndex := stopByteIndex + (self encodedByteCountAt: stopByteIndex) - 1.
	substring := self class on: (bytes copyFrom: startByteIndex to: stopByteIndex).
	self isAscii ifTrue: [ substring beAscii ].
	^ substring
]

{ #category : #copying }
UTF8String >> copyUpTo: aCharacter [
	| readStream |
	readStream := self readStream.
	^ self class streamContents: [ :out |
		[ readStream atEnd or: [ readStream peek = aCharacter ] ] whileFalse: [ 
			out nextPut: readStream next ] ]
]

{ #category : #private }
UTF8String >> decodeCharacterAt: byteIndex [
	^ ZnUTF8Encoder default 
		nextFromStream: (bytes readStream position: byteIndex - 1)
]

{ #category : #enumerating }
UTF8String >> do: block [
	| readStream |
	self isEmpty ifTrue: [ ^ self ].
	readStream := self readStream.
	[ readStream atEnd ] whileFalse: [ 
		block value: readStream next ]
]

{ #category : #private }
UTF8String >> emptyCheck [
	self isEmpty ifTrue: [ self errorEmptyCollection ]
]

{ #category : #accessing }
UTF8String >> encodedByteCount [
	"Return the byte count of my UTF8 encoded representation"
	
	^ bytes size
]

{ #category : #private }
UTF8String >> encodedByteCountAt: byteIndex [
	| byte |
	(byte := bytes at: byteIndex) < 128 ifTrue: [ ^ 1 ].
	(byte bitAnd: 2r11100000) = 2r11000000 ifTrue: [ ^ 2 ].
	(byte bitAnd: 2r11110000) = 2r11100000 ifTrue: [ ^ 3 ].
	(byte bitAnd: 2r11111000) = 2r11110000 ifTrue: [ ^ 4 ].
	self errorIllegalLeadingByte  
]

{ #category : #private }
UTF8String >> encodedBytesFor: codePoint [
	^ ByteArray 
			new: (ZnUTF8Encoder default encodedByteCountFor: codePoint) 
			streamContents: [ :out | 
				ZnUTF8Encoder default nextPutCodePoint: codePoint toStream: out ]
]

{ #category : #private }
UTF8String >> encodedCharacterAt: characterIndex [	
	^ self decodeCharacterAt: (self byteIndexAt: characterIndex)
]

{ #category : #testing }
UTF8String >> endsWith: suffixZnString [
	^ bytes endsWith: suffixZnString utf8EncodedBytes
]

{ #category : #'error handling' }
UTF8String >> error: message [
	ZnCharacterEncodingError signal: message
]

{ #category : #'error handling' }
UTF8String >> errorEmptyCollection [
	 CollectionIsEmpty signalWith: self 
]

{ #category : #'error handling' }
UTF8String >> errorIllegalLeadingByte [
	^ self error: 'Illegal leading byte for utf-8 encoding'
]

{ #category : #'error handling' }
UTF8String >> errorOutOfBounds: characterIndex [
	SubscriptOutOfBounds 
		signalFor: characterIndex 
		lowerBound: 1 
		upperBound: self size 
		in: self 
]

{ #category : #accessing }
UTF8String >> first [
	self emptyCheck.
	^ self isAscii 
		ifTrue: [ bytes first asCharacter ] 
		ifFalse: [ self decodeCharacterAt: 1 ]
]

{ #category : #comparing }
UTF8String >> hash [
	^ bytes hash
]

{ #category : #testing }
UTF8String >> includes: aCharacter [
	| codePoint |
	self isEmpty ifTrue: [ ^ false ].
	codePoint := aCharacter asInteger.
	^ self isAscii
		ifTrue: [ 
			codePoint > 127 
				ifTrue: [ false ] 
				ifFalse: [ bytes includes: codePoint ] ] 
		ifFalse: [ 
			(bytes 
				indexOfSubCollection: (self encodedBytesFor: codePoint)
				startingAt: 1) ~= 0 ]
]

{ #category : #testing }
UTF8String >> includesSubstring: aSubZnString [
	self isEmpty ifTrue: [ ^ false ].
	aSubZnString isEmpty ifTrue: [ ^ true ].
	^ (bytes indexOfSubCollection: aSubZnString utf8EncodedBytes startingAt: 1) ~= 0
]

{ #category : #accessing }
UTF8String >> indexOf: aCharacter [
	| offset |
	offset := 1.
	self do: [ :each |
		each = aCharacter ifTrue: [ ^ offset ].
		offset := offset + 1 ].
	^ 0
]

{ #category : #accessing }
UTF8String >> indexOf: aCharacter startingAt: characterOffset [
	| codePoint found |
	self isEmpty ifTrue: [ ^ false ].
	self boundsCheck: characterOffset. 
	codePoint := aCharacter asInteger.
	^ self isAscii
		ifTrue: [ 
			codePoint > 127 
				ifTrue: [ false ] 
				ifFalse: [ bytes indexOf: codePoint startingAt: (self byteIndexAt: characterOffset) ] ] 
		ifFalse: [ 
			found := bytes 
				indexOfSubCollection: (self encodedBytesFor: codePoint)
				startingAt: (self byteIndexAt: characterOffset).
			found = 0 ifTrue: [ 0 ] ifFalse: [ self characterIndexAt: found ] ]
]

{ #category : #accessing }
UTF8String >> indexOfSubCollection: aSubZnString [
	| byteIndex |
	self isEmpty ifTrue: [ ^ 0 ].
	aSubZnString isEmpty ifTrue: [ ^ 1 ].
	byteIndex := bytes indexOfSubCollection: aSubZnString utf8EncodedBytes startingAt: 1.
	^ byteIndex ~= 0
		ifTrue: [ self characterIndexAt: byteIndex ]
		ifFalse: [ 0 ]
]

{ #category : #testing }
UTF8String >> isAscii [
	"Return true when I am pure 7-bit ASCII, which means each character is encoded as one byte"
	
	^ bytes size = count
]

{ #category : #testing }
UTF8String >> isEmpty [
	"Return true when I am empty, when I do not contain any characters"
	
	^ bytes isEmpty
]

{ #category : #accessing }
UTF8String >> last [
	self emptyCheck.
	^ self isAscii
		ifTrue: [ bytes last asCharacter ]
		ifFalse: [ | binaryReadStream |
			binaryReadStream := bytes readStream setToEnd.
			ZnUTF8Encoder default
				backOnStream: binaryReadStream;
				nextFromStream: binaryReadStream ]
]

{ #category : #initialization }
UTF8String >> on: utf8EncodedBytes [
	bytes := utf8EncodedBytes 
]

{ #category : #printing }
UTF8String >> printOn: stream [
	| max readStream |
	super printOn: stream.
	stream nextPut: $(; nextPut: $'.
	max := self stride / 2.
	readStream := self readStream.
	[ readStream atEnd or: [ max = 0 ] ] whileFalse: [
		stream peek = $' ifTrue: [ stream nextPut: $' ].
		stream nextPut: readStream next.
		max := max - 1 ].
	max = 0 ifTrue: [ stream nextPutAll: '...' ].
	stream nextPut: $'.
	count ifNotNil: [ stream space; nextPut: $#; print: count ].
	stream nextPut: $)
]

{ #category : #converting }
UTF8String >> readStream [
	^ ZnCharacterReadStream on: bytes readStream
]

{ #category : #converting }
UTF8String >> reverse [
	self isAscii 
		ifTrue: [ ^ (self class on: bytes reverse) beAscii ].
	^ self class streamContents: [ :out |
			self reverseDo: [ :each | out nextPut: each ] ]
]

{ #category : #enumerating }
UTF8String >> reverseDo: block [
	| binaryReadStream |
	self isEmpty ifTrue: [ ^ self ].
	binaryReadStream := bytes readStream setToEnd.
	[ block value: (ZnUTF8Encoder default
		backOnStream: binaryReadStream;
		nextFromStream: binaryReadStream) ] doWhileTrue: [
			ZnUTF8Encoder default backOnStream: binaryReadStream.
			binaryReadStream position > 0 ]
]

{ #category : #accessing }
UTF8String >> size [
	"Return how many characters I contain"
	
	self isEmpty ifTrue: [ ^ 0 ].
	count ifNil: [ self computeCountAndIndex ].
	^ count
]

{ #category : #private }
UTF8String >> stride [
	"Return the stride, the constant I use internally to build my index"
	
	^ 32
]

{ #category : #accessing }
UTF8String >> utf8EncodedBytes [
	^ bytes
]
