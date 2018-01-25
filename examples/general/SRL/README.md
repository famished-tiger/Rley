WORK IN PROGRESS
================

This directory will contain a demo project that aims to implement a [Simple Regex Language](https://simple-regex.com) parser.
What is SRL?
------------
SRL is a small language lets you write regular expressions
with a readable syntax that bears some resemblance with English.
Here are a couple of hyperlinks of interest:  
[Main SRL website](https://simple-regex.com)  
[SRL libraries](https://github.com/SimpleRegex)

What is the purpose of this demo project?
-----------------------------------------
The objectives are:  
- Use _Rley_ as a parser of a language of moderate complexity,
- Show how to generate a regular expression from the parse tree.
- Be one of the very first Ruby implementation of the Simple Regex Language that passes the official test suite.
- Deliver a utility of value for those that are afraid to design complex regexp.

What's next?
------------
The intent is to deliver the project in small increments.
Each increment is a cycle organized as follows:
- Add a small subset of the SRL grammar,  
- Update the tokenizer to support the extension,  
- Test the parser with the new grammar subset,  
- Update the parse tree to support the tree nodes for the grammar subset
- Test the new grammar subset in the regular expression generation.

At the end, the complete SRL is supported and the [standard test suite](https://github.com/SimpleRegex/Test-Rules) is passing (hopefully).
