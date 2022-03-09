# UTF8String

A proof of concept / prototype alternative String implementation for Pharo
using a variable length UTF8 encoded internal representation.


## Introduction

In Pharo Strings, sequences of Characters, are implemented by storing the Unicode code points of the Characters.
In general, 32 bits are needed for Unicode code points. However, the most common ASCII and Latin1 code points fit in 8 bits.
Two subclasses of String, WideString and ByteString respectively, cover these cases, transparently.

When doing IO or using FFI, Strings must be encoded using an encoder, to and from a ByteArray or binary stream.
Many encodings are in common use, but today, UTF8 has basically won, as it is the default encoding almost everywhere.

There is a real cost associated with encoding and decoding, especially with a variable length encoding such as UTF8.

So one might ask the question: could we not use UTF8 as the internal representation of Strings.
Some other programming languages, most notably Swift, took this road year ago.


## Implementation

UTF8String is concept / prototype alternative String implementation for Pharo
using a variable length UTF8 encoded internal representation to explore this idea.
Furthermore UTF8String is readonly.

The main problem with UTF8 is that it is a variable length encoding, with Characters being encoded using 1 to 4 bytes.
This means two things: indexing is much harder, as it basically comes down to a linear scan
and similary knowning the length in number of Characters can only be done after a linear scan.

Replacing one character with another is almost impossible, since this might shift things.

There are two clear advantages: IO and FFI can be done with zero cost (to UTF8 obviously, not to other encodings)
and space usage is more efficient in most cases (when at least one character does not fit in 8 bits).


## Indexing and length caching

The UTF8String implementation just stores the UTF8 encoded bytes.
It tries to avoid indexing and counting if at all possible.
If indexing or the character count are needed, a single scan is performed,
that creates an index every stride (32) characters,
while also storing the length.
Further operations can then be performed faster.


## Operations

A surprising number of operations are possible that avoid indexing
or the character count: equality, hashing, character inclusion, substring searching.
Many other operation can be written using only a single (partial) scan:
finding tokens or formatting by interpolation.


## Discussion

The implementation was written to see if it could be done and how it would feel.
Not every algorithm is fully optimal, more specific loops are possible.

When creating a UTF8String on UTF8 encoded bytes, this is a zero cost operation
only if we assume the encoding is correct. A validate operation is available
to check this, but that defeats the speed advantage for the most part.

An aspect that was ignored is the concept of Unicode normalization with respect to concatenation.
This is a hard subject has been solved in Pharo using external code, but not integrated in this implementation.

The concept of readonly strings is worth considering and feels acceptable, but requires a certain mindset.


## Conclusion

Although this experiment went well, it is not meant for actual use.
