"
I am UTF8StringTests, holding unit tests for UTF8String.
I am a TestCase.
"
Class {
	#name : #UTF8StringTests,
	#superclass : #TestCase,
	#category : #UTF8String
}

{ #category : #accessing }
UTF8StringTests >> firstString [
	^ 'First string: élève Français à 10 € - 1'
]

{ #category : #accessing }
UTF8StringTests >> normalAsciiString [
	^ String loremIpsum 
]

{ #category : #accessing }
UTF8StringTests >> normalString [
	^ 'Les élèves Français à 10 € - Les élèves Français à 10 € - 0123456789 - Les élèves Français à 10 € - Les élèves Français à 10 €'
]

{ #category : #accessing }
UTF8StringTests >> secondString [
	^ 'Second string: élève Français à 20 € - 2'
]

{ #category : #accessing }
UTF8StringTests >> smallAsciiString [
	^ 'ABC123'
]

{ #category : #accessing }
UTF8StringTests >> smallString [
	^ 'Les élèves Français à 10 €'
]

{ #category : #accessing }
UTF8StringTests >> testAsLowercase [
	self 
		assert: (UTF8String fromSystemString: self smallString) asLowercase 
		equals: (UTF8String fromSystemString: self smallString asLowercase)
]

{ #category : #accessing }
UTF8StringTests >> testAsUppercase [
	self 
		assert: (UTF8String fromSystemString: self smallString) asUppercase 
		equals: (UTF8String fromSystemString: self smallString asUppercase)
]

{ #category : #testing }
UTF8StringTests >> testConcatenation [
	| first second concatenation |
	first := UTF8String fromSystemString: self firstString.
	second := UTF8String fromSystemString: self secondString.
	concatenation := UTF8String fromSystemString: self firstString , self secondString.
	self assert: first , second equals: concatenation 
]

{ #category : #testing }
UTF8StringTests >> testEmpty [
	| emptyString |
	emptyString := UTF8String empty.
	self assert: emptyString isEmpty.
	self assert: emptyString size equals: 0.
	self should: [ emptyString at: 1 ] raise: CollectionIsEmpty. 
	self assert: emptyString equals: UTF8String empty.
	self assert: emptyString equals: (UTF8String on: #[]).
	self assert: emptyString utf8EncodedBytes equals: #[].
	self deny: emptyString equals: (UTF8String fromSystemString: 'ABC')
]

{ #category : #tests }
UTF8StringTests >> testEnumeration [
	| string index |
	string := UTF8String fromSystemString: self normalString.
	index := 1.
	string do: [ :each |
		self assert: each equals: (self normalString at: index).
		index := index + 1 ].
	self assert: index equals: self normalString size + 1.
	index := self normalString size.
	string reverseDo: [ :each |
		self assert: each equals: (self normalString at: index).
		index := index - 1 ].
	self assert: index equals: 0
	
]

{ #category : #tests }
UTF8StringTests >> testIncludes [
	| string |
	string := UTF8String fromSystemString: self normalString.
	self normalString do: [ :each |
		self assert: (string includes: each) ]
]

{ #category : #tests }
UTF8StringTests >> testIncludesSubstring [
	| string |
	string := UTF8String fromSystemString: self normalString.
	(self normalString findTokens: ' -') do: [ :each |
		self assert: (string includesSubstring: (UTF8String fromSystemString: each)) ]
]

{ #category : #accessing }
UTF8StringTests >> testIndexNormal [
	| string map |
	string := UTF8String fromSystemString: self normalString.
	map := Array streamContents: [ :out |
		1 to: string size do: [ :characterIndex |
			out nextPut: characterIndex -> (string byteIndexAt: characterIndex) ] ].
	map do: [ :spec |
		self assert: (string characterIndexAt: spec value) equals: spec key ]
]

{ #category : #accessing }
UTF8StringTests >> testIndexOf [
	| str |
	str := UTF8String fromSystemString: self normalString.
	self assert: (str indexOf: $L) equals: 1.
	self assert: (str indexOf: $€) equals: 26.
	self assert: (str indexOf: $A) equals: 0
]

{ #category : #accessing }
UTF8StringTests >> testIndexSmall [
	| string map |
	string := UTF8String fromSystemString: self smallString.
	map := Array streamContents: [ :out |
		1 to: string size do: [ :characterIndex |
			out nextPut: characterIndex -> (string byteIndexAt: characterIndex) ] ].
	map do: [ :spec |
		self assert: (string characterIndexAt: spec value) equals: spec key ]
]

{ #category : #testing }
UTF8StringTests >> testNormal [
	| string |
	string := UTF8String fromSystemString: self normalString.
	self assert: string size equals: self normalString size.
	1 to: string size do: [ :index | 
		self assert: (string at: index) equals: (self normalString at: index) ].
	self deny: string isAscii.
	self deny: string isEmpty
]

{ #category : #testing }
UTF8StringTests >> testNormalAscii [
	| string |
	string := UTF8String fromSystemString: self normalAsciiString.
	self assert: string size equals: self normalAsciiString size.
	1 to: string size do: [ :index | 
		self assert: (string at: index) equals: (self normalAsciiString at: index) ].
	self assert: string isAscii.
	self deny: string isEmpty
]

{ #category : #tests }
UTF8StringTests >> testReverse [
	| string reverse |
	string := UTF8String fromSystemString: self normalString.
	reverse := UTF8String fromSystemString: self normalString reverse.
	self assert: string reverse equals: reverse
	
]

{ #category : #testing }
UTF8StringTests >> testSmall [
	| smallString |
	smallString := UTF8String fromSystemString: self smallString.
	self assert: smallString size equals: self smallString size.
	1 to: smallString size do: [ :index | 
		self assert: (smallString at: index) equals: (self smallString at: index) ].
	self deny: smallString isAscii
]

{ #category : #testing }
UTF8StringTests >> testSmallAscii [
	| smallString |
	smallString := UTF8String fromSystemString: self smallAsciiString.
	self assert: smallString size equals: self smallAsciiString size.
	1 to: smallString size do: [ :index | 
		self assert: (smallString at: index) equals: (self smallAsciiString at: index) ].
	self assert: smallString isAscii
]

{ #category : #tests }
UTF8StringTests >> testStreamContents [
	| string built |
	string := UTF8String fromSystemString: self normalString.
	built := UTF8String streamContents: [ :out |
		self normalString do: [ :each | out nextPut: each ] ].
	self assert: built equals: string
]
