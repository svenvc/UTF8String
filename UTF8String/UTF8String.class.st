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
	"Return the empty UTF8String instance.
	Since my instances are readonly, this could be cached."

	^ (self on: #[]) beAscii; yourself
]

{ #category : #accessing }
UTF8String class >> encoder [
	"Return the ZnCharacterEncoder that I use, obviously UTF8."
	
	^ ZnUTF8Encoder default
]

{ #category : #'instance creation' }
UTF8String class >> fromCharacter: character [
	"Return a new UTF8String containing a single character"
	
	| codePoint bytes |
	codePoint := character asInteger.
	bytes := ByteArray 
		new: (self encoder encodedByteCountFor: codePoint) 
		streamContents: [ :out | 
			self encoder nextPutCodePoint: codePoint toStream: out ].
	^ self on: bytes
]

{ #category : #'instance creation' }
UTF8String class >> fromSystemString: systemString [
	"Return a new UTF8String containing the characters in systemString."
	
	^ self on: systemString utf8Encoded 
]

{ #category : #'instance creation' }
UTF8String class >> on: utf8EncodedBytes [
	"Return an new UTF8String containing the characters encoded in utf8EncodedBytes, a ByteArray.
	Note that no validation is performed. See #validate"
	
	^ self new on: utf8EncodedBytes; yourself
]

{ #category : #'instance creation' }
UTF8String class >> streamContents: block [
	"Create a new UTF8String by writing characters to the character WriteStream passed to block"
	
	| utf8EncodedBytes |
	utf8EncodedBytes := ByteArray streamContents: [ :binaryWriteStream |
		block value: (ZnCharacterWriteStream on: binaryWriteStream) ].
	^ self on: utf8EncodedBytes
]

{ #category : #copying }
UTF8String >> , anotherUTF8String [
	"Return a new string by concatenating myself with anotherUTF8String.
	In principle we should do 'Normalization Preserving Concatenation', 
	see https://medium.com/concerning-pharo/an-implementation-of-unicode-normalization-7c6719068f43
	For now, assume we don't need it."
	
	^ self on: self utf8EncodedBytes , anotherUTF8String utf8EncodedBytes
]

{ #category : #comparing }
UTF8String >> < anotherUTF8String [
	"Return true when I come lexicographically before anotherUTF8String, false otherwise"
	
	^ (self threeWayCompareTo: anotherUTF8String) < 0 
]

{ #category : #comparing }
UTF8String >> <= anotherUTF8String [
	"Return true when I come lexicographically before or an equal to anotherUTF8String, false otherwise"
	
	^ (self threeWayCompareTo: anotherUTF8String) <= 0 
]

{ #category : #comparing }
UTF8String >> = anotherUTF8String [
	"Return true when I am equal to anotherUTF8String, false otherwise"
	
	self == anotherUTF8String ifTrue: [ ^ true ].
	self class = anotherUTF8String class ifFalse: [ ^ false ].
	^ bytes = anotherUTF8String utf8EncodedBytes
]

{ #category : #comparing }
UTF8String >> > anotherUTF8String [
	"Return true when I come lexicographically after anotherUTF8String, false otherwise"
	
	^ (self threeWayCompareTo: anotherUTF8String) > 0 
]

{ #category : #comparing }
UTF8String >> >= anotherUTF8String [
	"Return true when I come lexicographically after or am equal to anotherUTF8String, false otherwise"
	
	^ (self threeWayCompareTo: anotherUTF8String) >= 0 
]

{ #category : #converting }
UTF8String >> asByteArray [
	"Convert me to a ByteArray containing my UTF8 encoded representation"
	
	^ self utf8EncodedBytes
]

{ #category : #converting }
UTF8String >> asLowercase [
	"Return a copy of me with each character converted to lowercase."
	
	^ self collect: [ :each | each asLowercase ]
]

{ #category : #converting }
UTF8String >> asString [
	"Convert me to a system String"
	
	^ bytes utf8Decoded
]

{ #category : #converting }
UTF8String >> asUTF8Bytes [
	"Return a ByteArray with my UTF8 encoded representation"
	
	^ self utf8EncodedBytes
]

{ #category : #converting }
UTF8String >> asUTF8String [
	"Convert me to an UTF8String"
	
	^ self
]

{ #category : #converting }
UTF8String >> asUppercase [
	"Return a copy of me with each character converted to uppercase"
	
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
	"Mark me as being pure 7-bit ASCII, which means each character is encoded as one byte.
	This is an important optimisation as it prevents counting, scanning and indexing."
	
	count := bytes size.
	index := Array empty
]

{ #category : #testing }
UTF8String >> beginsWith: prefixUTF8String [
	"Return true when I begin with prefixUTF8String, false otherwise."
	
	^ bytes beginsWith: prefixUTF8String utf8EncodedBytes
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
	"Return a copy of me with my first character capitalized"
	
	| first |
	first := true.
	^ self collect: [ :each | 
			first
				ifTrue: [ first := false. each asUppercase ]
				ifFalse: [ each ] ]
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
	[ byteCursor <= bytes size ] whileTrue: [
		byteCursor = byteIndex 
			ifTrue: [ ^ characterIndex ].
		byteCursor := byteCursor + (self encodedByteCountAt: byteCursor).
		characterIndex := characterIndex + 1 ].
	^ 0
]

{ #category : #enumerating }
UTF8String >> collect: block [
	"Create a copy of me with each Character transformed by block, in order, from first to last"
	
	self isEmpty ifTrue: [ ^ self ].
	^ self class streamContents: [ :out |
			self do: [ :each |
				out nextPut: (block value: each) ] ]
]

{ #category : #private }
UTF8String >> computeCountAndIndex [
	self isEmpty ifTrue: [ count := 0. ^ self ].
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
	"Return a new string, a copy of me from startIndex to stopIndex, both character indices.
	Signal SubscriptOutOfBounds or CollectionIsEmpty in case of illegal indices."
	
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
	"Return a new string, a copy of me, from my first character 
	up to but not including the first occurrence of aCharacter."
	
	| readStream |
	readStream := self readStream.
	^ self class streamContents: [ :out |
		[ readStream atEnd or: [ readStream peek = aCharacter ] ] whileFalse: [ 
			out nextPut: readStream next ] ]
]

{ #category : #private }
UTF8String >> decodeCharacterAt: byteIndex [
	^ self encoder nextFromStream: (bytes readStream position: byteIndex - 1)
]

{ #category : #enumerating }
UTF8String >> do: block [
	"Execute block with each of my Characters as argument, in order, from first to last"
	
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
			new: (self encoder encodedByteCountFor: codePoint) 
			streamContents: [ :out | 
				self encoder nextPutCodePoint: codePoint toStream: out ]
]

{ #category : #private }
UTF8String >> encodedCharacterAt: characterIndex [	
	^ self decodeCharacterAt: (self byteIndexAt: characterIndex)
]

{ #category : #private }
UTF8String >> encoder [
	^ self class encoder
]

{ #category : #testing }
UTF8String >> endsWith: suffixUTF8String [
	"Return true when I end with suffixUTF8String, false otherwise."
	
	^ bytes endsWith: suffixUTF8String utf8EncodedBytes
]

{ #category : #'error handling' }
UTF8String >> errorEmptyCollection [
	 CollectionIsEmpty signalWith: self 
]

{ #category : #'error handling' }
UTF8String >> errorIllegalContinuationByte [
	^ self encoder errorIllegalContinuationByte
]

{ #category : #'error handling' }
UTF8String >> errorIllegalLeadingByte [
	^ self encoder errorIllegalLeadingByte
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
UTF8String >> findTokens: delimiters [
	"Return a collection of tokens, substrings, in me, separated by delimiters.
	Delimiters is a collection of characters or a single character.
	Delimiters are not included in the results, multiple delimiters in a row count as one."
	
	| separators in token |
	separators := delimiters isCharacter ifTrue: [ { delimiters } ] ifFalse: [ delimiters ].
	in := self readStream.
	^ OrderedCollection streamContents: [ :tokens |
		[ in atEnd ] whileFalse: [
			token := self class streamContents: [ :out |
				[ in atEnd or: [ separators includes: in peek ] ] whileFalse: [
					out nextPut: in next ] ].
			token isEmpty ifFalse: [ tokens nextPut: token ].
			[ in atEnd not and: [ separators includes: in peek ] ] whileTrue: [
				in next ] ] ]
]

{ #category : #accessing }
UTF8String >> first [
	"Return my first Character.
	Signal CollectionIsEmpty when there is no such character."

	self emptyCheck.
	^ self isAscii 
		ifTrue: [ bytes first asCharacter ] 
		ifFalse: [ self decodeCharacterAt: 1 ]
]

{ #category : #formatting }
UTF8String >> format: collection [ 
	"Format the receiver by interpolating elements from collection (see String>>#format:)"
	
	^ self class streamContents: [ :out | | in |
		in := self readStream.
		[ in atEnd ] whileFalse: [ | currentChar | 
			(currentChar := in next) == ${
				ifTrue: [ | expression key | 
					expression := in upTo: $}.
					key := Integer readFrom: expression ifFail: [ expression ].
					out nextPutAll: (collection at: key) asString asUTF8String ]
				ifFalse: [
					currentChar == $\
						ifTrue: [ in atEnd ifFalse: [ out nextPut: in next ] ]
						ifFalse: [ out nextPut: currentChar ] ] ] ]
]

{ #category : #comparing }
UTF8String >> hash [
	"Return my hash, a SmallInteger related to my identity"

	^ bytes hash
]

{ #category : #testing }
UTF8String >> includes: aCharacter [
	"Return true when I include aCharacter, false otherwise."
	
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
UTF8String >> includesSubstring: aSubUTF8String [
	"Return true when I include aSubUTF8String, false otherwise.
	The empty string contains nothing, an empty string is part of any non empty string."
	
	self isEmpty ifTrue: [ ^ false ].
	aSubUTF8String isEmpty ifTrue: [ ^ true ].
	^ (bytes indexOfSubCollection: aSubUTF8String utf8EncodedBytes startingAt: 1) ~= 0
]

{ #category : #accessing }
UTF8String >> indexOf: aCharacter [
	"Return the index of the first occurrence of aCharacter in me.
	If I do not contain aCharacter, return 0."
	
	^ self indexOf: aCharacter startingAt: 1
]

{ #category : #accessing }
UTF8String >> indexOf: aCharacter startingAt: characterOffset [
	"Return the index of the first occurrence of aCharacter after characterOffset in me.
	If I do not contain aCharacter after characterOffset, return 0."

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
UTF8String >> indexOfSubCollection: aSubUTF8String [
	"Return the index of the first occurrence of aSubUTF8String in me.
	Return 0 if aSubUTF8String does not occur in me."
	
	| byteIndex |
	self isEmpty ifTrue: [ ^ 0 ].
	aSubUTF8String isEmpty ifTrue: [ ^ 1 ].
	byteIndex := bytes indexOfSubCollection: aSubUTF8String utf8EncodedBytes startingAt: 1.
	^ byteIndex ~= 0
		ifTrue: [ self characterIndexAt: byteIndex ]
		ifFalse: [ 0 ]
]

{ #category : #testing }
UTF8String >> isAscii [
	"Return true when I am pure 7-bit ASCII, which means each character is encoded as one byte.
	It is an important optimisation to know this upfront, see #beAscii, 
	as it prevents counting, scanning and indexing."
	
	count ifNil: [ self computeCountAndIndex ].
	^ bytes size = count
]

{ #category : #testing }
UTF8String >> isByteString [
	"We are not compatible with a system ByteString"
	
	^ false
]

{ #category : #testing }
UTF8String >> isEmpty [
	"Return true when I am empty, when I do not contain any characters"
	
	^ bytes isEmpty
]

{ #category : #accessing }
UTF8String >> last [
	"Return my last Character.
	Signal CollectionIsEmpty when there is no such character."

	self emptyCheck.
	^ self isAscii
		ifTrue: [ bytes last asCharacter ]
		ifFalse: [ | binaryReadStream |
			binaryReadStream := bytes readStream setToEnd.
			self encoder
				backOnStream: binaryReadStream;
				nextFromStream: binaryReadStream ]
]

{ #category : #initialization }
UTF8String >> on: utf8EncodedBytes [
	"Initialize me on utf8EncodedBytes. No validation takes place. See #validate."
	
	bytes := utf8EncodedBytes 
]

{ #category : #printing }
UTF8String >> printDebugOn: stream [
	| max readStream |
	stream nextPutAll: 'a UTF8String('; nextPut: $'.
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

{ #category : #printing }
UTF8String >> printOn: stream [
	| readStream |
	stream nextPut: $'.
	readStream := self readStream.
	[ readStream atEnd ] whileFalse: [
		stream peek = $' ifTrue: [ stream nextPut: $' ].
		stream nextPut: readStream next ].
	stream nextPut: $'.
]

{ #category : #streaming }
UTF8String >> putOn: aStream [
	aStream nextPutAll: self
]

{ #category : #enumerating }
UTF8String >> readStream [
	"Return a Character ReadStream to iterate over my contents in order, from first to last"
	
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
	"Execute block with each of my Characters as argument, in reverse order, from last to first"

	| binaryReadStream |
	self isEmpty ifTrue: [ ^ self ].
	binaryReadStream := bytes readStream setToEnd.
	[ block value: (self encoder
		backOnStream: binaryReadStream;
		nextFromStream: binaryReadStream) ] doWhileTrue: [
			self encoder backOnStream: binaryReadStream.
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

{ #category : #comparing }
UTF8String >> threeWayCompareTo: anotherUTF8String [
	"Do a three-way comparison between the receiver and anotherUTF8String (see Magnitude>>#threeWayCompareTo:)"
	
	| readStream otherReadStream character otherCharacter |
	readStream := self readStream.
	otherReadStream := anotherUTF8String readStream.
	[ readStream atEnd or: [ otherReadStream atEnd ] ] whileFalse: [ 
		character := readStream next.
		otherCharacter := otherReadStream next.
		character = otherCharacter 
			ifFalse: [ 
				character < otherCharacter ifTrue: [ ^ -1 ] ifFalse: [ ^ 1 ] ] ].
	(readStream atEnd and: [ otherReadStream atEnd ]) ifTrue: [ ^ 0 ].
	^ readStream atEnd ifTrue: [ -1 ] ifFalse: [ 1 ]
]

{ #category : #converting }
UTF8String >> utf8Encoded [
	"Return a ByteArray with my UTF8 encoded representation"
	
	^ self utf8EncodedBytes
]

{ #category : #accessing }
UTF8String >> utf8EncodedBytes [
	"Return a ByteArray with a UTF8 encoded representation of me."
	
	^ bytes
]

{ #category : #initialization }
UTF8String >> validate [
	"Validate my byte representation, checking if the UTF8 encoding is correct.
	Since this requires a full scan, I compute my count and index as well.
	Return true when I am valid, false otherwise."
	
	self isEmpty ifTrue: [ count := 0. ^ true ].
	"the number of characters cannot be larger than the byte size"
	^ bytes size <= self stride
		ifTrue: [ self validateNoIndex ]
		ifFalse: [ self validateFullIndex ]
]

{ #category : #private }
UTF8String >> validateFullIndex [
	count := 0.
	[
		index := Array streamContents: [ :out | | readStream |
			readStream := self readStream.
			[ readStream atEnd ] whileFalse: [
				count := count + 1.
				readStream next.
				(count > self stride and: [ (count - 1 \\ self stride) = 0 ]) 
					ifTrue: [ out nextPut: readStream wrappedStream position ] ] ]
	] on: ZnCharacterEncodingError do: [ ^ false ].
	^ true
]

{ #category : #private }
UTF8String >> validateNoIndex [
	count := 0.
	index := Array empty.
	[ | readStream |
		readStream := self readStream.
		[ readStream atEnd ] whileFalse: [
			readStream next. 
			count := count + 1 ] 
	] on: ZnCharacterEncodingError do: [ ^ false ].
	^ true
]
