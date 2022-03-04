"
I am UTF8StringTest, holding unit tests for UTF8String.
I am a TestCase.
"
Class {
	#name : #UTF8StringTest,
	#superclass : #TestCase,
	#category : #UTF8String
}

{ #category : #accessing }
UTF8StringTest >> firstString [
	^ 'First string: élève Français à 10 € - 1'
]

{ #category : #accessing }
UTF8StringTest >> normalAsciiString [
	^ String loremIpsum 
]

{ #category : #accessing }
UTF8StringTest >> normalString [
	^ 'Les élèves Français à 10 € - Les élèves Français à 10 € - 0123456789 - Les élèves Français à 10 € - Les élèves Français à 10 €'
]

{ #category : #accessing }
UTF8StringTest >> secondString [
	^ 'Second string: élève Français à 20 € - 2'
]

{ #category : #accessing }
UTF8StringTest >> smallAsciiString [
	^ 'ABC123'
]

{ #category : #accessing }
UTF8StringTest >> smallString [
	^ 'Les élèves Français à 10 €'
]

{ #category : #tests }
UTF8StringTest >> testAsLowercase [
	self 
		assert: (UTF8String fromSystemString: self smallString) asLowercase 
		equals: (UTF8String fromSystemString: self smallString asLowercase)
]

{ #category : #tests }
UTF8StringTest >> testAsUTF8String [
	| string |
	self 
		assert: (UTF8String fromSystemString: self smallString)
		equals: self smallString asUTF8String.
	string := #[ 65 66 67 ] asUTF8String.
	self assert: string equals: 'ABC' asUTF8String.
	self assert: string identicalTo: string asUTF8String  
]

{ #category : #tests }
UTF8StringTest >> testAsUppercase [
	self 
		assert: (UTF8String fromSystemString: self smallString) asUppercase 
		equals: (UTF8String fromSystemString: self smallString asUppercase)
]

{ #category : #tests }
UTF8StringTest >> testCapitalized [
	self 
		assert: (UTF8String fromSystemString: self smallString) capitalized 
		equals: (UTF8String fromSystemString: self smallString capitalized)
]

{ #category : #tests }
UTF8StringTest >> testConcatenation [
	| first second concatenation |
	first := UTF8String fromSystemString: self firstString.
	second := UTF8String fromSystemString: self secondString.
	concatenation := UTF8String fromSystemString: self firstString , self secondString.
	self assert: first , second equals: concatenation 
]

{ #category : #tests }
UTF8StringTest >> testEmpty [
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
UTF8StringTest >> testEnumeration [
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
UTF8StringTest >> testIncludes [
	| string |
	string := UTF8String fromSystemString: self normalString.
	self normalString do: [ :each |
		self assert: (string includes: each) ]
]

{ #category : #tests }
UTF8StringTest >> testIncludesSubstring [
	| string |
	string := UTF8String fromSystemString: self normalString.
	(self normalString findTokens: ' -') do: [ :each |
		self assert: (string includesSubstring: (UTF8String fromSystemString: each)) ]
]

{ #category : #tests }
UTF8StringTest >> testIndexNormal [
	| string map |
	string := UTF8String fromSystemString: self normalString.
	map := Array streamContents: [ :out |
		1 to: string size do: [ :characterIndex |
			out nextPut: characterIndex -> (string byteIndexAt: characterIndex) ] ].
	map do: [ :spec |
		self assert: (string characterIndexAt: spec value) equals: spec key ]
]

{ #category : #tests }
UTF8StringTest >> testIndexOf [
	| str |
	str := UTF8String fromSystemString: self normalString.
	self assert: (str indexOf: $L) equals: 1.
	self assert: (str indexOf: $€) equals: 26.
	self assert: (str indexOf: $A) equals: 0
]

{ #category : #tests }
UTF8StringTest >> testIndexSmall [
	| string map |
	string := UTF8String fromSystemString: self smallString.
	map := Array streamContents: [ :out |
		1 to: string size do: [ :characterIndex |
			out nextPut: characterIndex -> (string byteIndexAt: characterIndex) ] ].
	map do: [ :spec |
		self assert: (string characterIndexAt: spec value) equals: spec key ]
]

{ #category : #tests }
UTF8StringTest >> testNormal [
	| string |
	string := UTF8String fromSystemString: self normalString.
	self assert: string size equals: self normalString size.
	1 to: string size do: [ :index | 
		self assert: (string at: index) equals: (self normalString at: index) ].
	self deny: string isAscii.
	self deny: string isEmpty
]

{ #category : #tests }
UTF8StringTest >> testNormalAscii [
	| string |
	string := UTF8String fromSystemString: self normalAsciiString.
	self assert: string size equals: self normalAsciiString size.
	1 to: string size do: [ :index | 
		self assert: (string at: index) equals: (self normalAsciiString at: index) ].
	self assert: string isAscii.
	self deny: string isEmpty
]

{ #category : #tests }
UTF8StringTest >> testReverse [
	| string reverse |
	string := UTF8String fromSystemString: self normalString.
	reverse := UTF8String fromSystemString: self normalString reverse.
	self assert: string reverse equals: reverse
	
]

{ #category : #tests }
UTF8StringTest >> testSmall [
	| smallString |
	smallString := UTF8String fromSystemString: self smallString.
	self assert: smallString size equals: self smallString size.
	1 to: smallString size do: [ :index | 
		self assert: (smallString at: index) equals: (self smallString at: index) ].
	self deny: smallString isAscii
]

{ #category : #tests }
UTF8StringTest >> testSmallAscii [
	| smallString |
	smallString := UTF8String fromSystemString: self smallAsciiString.
	self assert: smallString size equals: self smallAsciiString size.
	1 to: smallString size do: [ :index | 
		self assert: (smallString at: index) equals: (self smallAsciiString at: index) ].
	self assert: smallString isAscii
]

{ #category : #tests }
UTF8StringTest >> testStreamContents [
	| string built |
	string := UTF8String fromSystemString: self normalString.
	built := UTF8String streamContents: [ :out |
		self normalString do: [ :each | out nextPut: each ] ].
	self assert: built equals: string
]

{ #category : #tests }
UTF8StringTest >> testValidate [
	#( firstString secondString normalString normalAsciiString smallString smallAsciiString ) do: [ :each |
		self assert: (UTF8String fromSystemString: (self perform: each)) validate ].
	{ #[235 140 4]. #[255]. #[255 128] } do: [ :each |
		self deny: (UTF8String on: each) validate ]
]
