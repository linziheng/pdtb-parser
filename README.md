#Java End-to-End PDTB-Styled Discourse Parser


PDTB parser based on:
<cite> Ziheng Lin, Hwee Tou Ng and Min-Yen Kan (2014).<b> A PDTB-Styled End-to-End Discourse Parser </b>. Natural Language Engineering, 20, pp 151-184. Cambridge University Press.</cite>

Version: 1.0.0

Last update: 10-May-2015

Requires JDK 1.7 or higher.

## Quick Start

1. `git clone https://github.com/ilija139/PDTB-Parser.git`
2. `cd PDTB-Parser/`
3. `java -jar runnable_jars/parser.jar  text_doc_to_parse.txt` 
4. The PDTB relations are in `tmp/text_doc_to_parse.txt`


## Installing and Usage


1. Clone the repo or download the code by clicking the "Download ZIP" button on the right.

2. Extract the zip file.

3. Move the PDTB corpus in a folder `data/pdtb/` or edit the location (requires re-compiling) in sg.edu.nus.comp.pdtb.util.Settings.java. The folder structure should be like: `data/pdtb/$section_number/`, where the section number goes from 00 to 25. 

4. Move the PTB corpus in a folder `data/ptb/` or edit the location (requires re-compiling) in sg.edu.nus.comp.pdtb.util.Settings.java. The folder structure should be like: `data/ptb/parse_tree/$section_number/` and `data/ptb/raw_text/$section_number/`, where the section nubmer goes from 00 to 25.

5. Open terminal or command prompt and navigate to PDTB-Parser-master directory.

6. Run `java -jar runnable_jars/SpanTreeExtractor.jar` to generate the auxiliary files used by the parser. 

7a. Run `java -jar Tester.jar` to generate the model files, run the tests and print out the results as reported in the paper.

7b. Run `java -jar Tester.jar -useOldModels` to use the pre-generated model files, run the tests and print out the results. <b>If you use the pre-generated model files, you can skip the previous 4 steps</b>

### Parsing any text

To parse any text document you will need the jar file `runnable_jars/parser.jar` and the model files in the `output` directory. Then run the following command:

`java -jar runnable_jars/parser.jar  text_doc_to_parse.txt` 

The argument `text_doc_to_parse.txt` is a file path to the document you want to parse. The location of the model files is specified in `config.properties` (by default `output`) and it's relative to the directory you are running the above command. 

The parser will output the relations in a pipe file format. This file and the other auxiliary files generated from the text document are stored by default in the `tmp/` directory, but you can specify a different directory in the `config.properties` file. 


## Required Resources

The PDTB and PTB (raw text and parse trees) corpora are required by all of the parser components. 

The NonExplicit component also requires dependency trees for training and testing. They can be generated using the Stanford parser found in `external/auto_parsers` directory. 

By running the `Tester.jar` feature files for all components are re-generated except for the auto+ep case. If you want to re-generate the feature files for this experiment you will have to also re-generate the auto parse trees using the parsers found in `external/auto_parsers` directory.

The directory paths to the these resources are specified in `sg.edu.nus.comp.pdtb.util.Settings` file. 


## Pipe Format

 The parser uses the PDTB pipe-delimited format where every relation is represented
 on a single line and values are delimited by the pipe symbol.
 There must be 48 columns, but certain values may be blank. 
 
 
 The following lists the column values.
 For precise definitions of the terms used, please consult the [PDTB 2.0 annotation manual](http://www.seas.upenn.edu/~pdtb/PDTBAPI/pdtb-annotation-manual.pdf).

<b>Note the zero-based column index</b>

 - Col  0: Relation type (Explicit/Implicit/AltLex/EntRel/NoRel)
 - Col  1: Section number (0-24)
 - Col  2: File number (0-99)
 - Col  3: Connective/AltLex SpanList (only for Explicit and AltLex)
 - Col  4: Connective/AltLex GornAddressList (only for Explicit and AltLex)
 - Col  5: Connective/AltLex RawText (only for Explicit and AltLex)
 - Col  6: String position (only for Implicit, EntRel and NoRel) 
 - Col  7: Sentence number (only for Implicit, EntRel and NoRel)
 - Col  8: ConnHead (only for Explicit)
 - Col  9: Conn1 (only for Implicit)
 - Col 10: Conn2 (only for Implicit)
 - Col 11: 1st Semantic Class  corresponding to ConnHead, Conn1 or AltLex span (only for Explicit, Implicit and AltLex)
 - Col 12: 2nd Semantic Class  corresponding to ConnHead, Conn1 or AltLex span (only for Explicit, Implicit and AltLex)
 - Col 13: 1st Semantic Class corresponding to Conn2 (only for Implicit)
 - Col 14: 2nd Semantic Class corresponding to Conn2 (only for Implicit)
 - Col 15: Relation-level attribution: Source (only for Explicit, Implicit and AltLex)
 - Col 16: Relation-level attribution: Type (only for Explicit, Implicit and AltLex)
 - Col 17: Relation-level attribution: Polarity (only for Explicit, Implicit and AltLex)
 - Col 18: Relation-level attribution: Determinacy (only for Explicit, Implicit and AltLex)
 - Col 19: Relation-level attribution: SpanList (only for Explicit, Implicit and AltLex)
 - Col 20: Relation-level attribution: GornAddressList (only for Explicit, Implicit and AltLex)
 - Col 21: Relation-level attribution: RawText (only for Explicit, Implicit and AltLex)
 - Col 22: Arg1 SpanList
 - Col 23: Arg1 GornAddress
 - Col 24: Arg1 RawText
 - Col 25: Arg1 attribution: Source (only for Explicit, Implicit and AltLex)
 - Col 26: Arg1 attribution: Type (only for Explicit, Implicit and AltLex)
 - Col 27: Arg1 attribution: Polarity (only for Explicit, Implicit and AltLex)
 - Col 28: Arg1 attribution: Determinacy (only for Explicit, Implicit and AltLex)
 - Col 29: Arg1 attribution: SpanList (only for Explicit, Implicit and AltLex)
 - Col 30: Arg1 attribution: GornAddressList (only for Explicit, Implicit and AltLex)
 - Col 31: Arg1 attribution: RawText (only for Explicit, Implicit and AltLex)
 - Col 32: Arg2 SpanList
 - Col 33: Arg2 GornAddress
 - Col 34: Arg2 RawText
 - Col 35: Arg2 attribution: Source (only for Explicit, Implicit and AltLex)
 - Col 36: Arg2 attribution: Type (only for Explicit, Implicit and AltLex)
 - Col 37: Arg2 attribution: Polarity (only for Explicit, Implicit and AltLex)
 - Col 38: Arg2 attribution: Determinacy (only for Explicit, Implicit and AltLex)
 - Col 39: Arg2 attribution: SpanList (only for Explicit, Implicit and AltLex)
 - Col 40: Arg2 attribution: GornAddressList (only for Explicit, Implicit and AltLex)
 - Col 41: Arg2 attribution: RawText (only for Explicit, Implicit and AltLex)
 - Col 42: Sup1 SpanList (only for Explicit, Implicit and AltLex)
 - Col 43: Sup1 GornAddress (only for Explicit, Implicit and AltLex)
 - Col 44: Sup1 RawText (only for Explicit, Implicit and AltLex)
 - Col 45: Sup2 SpanList (only for Explicit, Implicit and AltLex)
 - Col 46: Sup2 GornAddress (only for Explicit, Implicit and AltLex)
 - Col 47: Sup2 RawText (only for Explicit, Implicit and AltLex)

Example relation:

`Explicit|18|70|262..265|1,0|But|||but|||Comparison.Contrast||||Wr|Comm|Null|Null||||9..258|0|From a helicopter a thousand feet above Oakland after the second-deadliest earthquake in U.S. history, a scene of devastation emerges: a freeway crumbled into a concrete sandwich, hoses pumping water into once-fashionable apartments, abandoned autos|Inh|Null|Null|Null||||266..354|1,1;1,2;1,3|this quake wasn't the big one, the replay of 1906 that has been feared for so many years|Inh|Null|Null|Null|||||||||`

## External libraries used

Stanford's CoreNLP Natural Language Processing Toolkit for reading and generating parse trees. 

Reference:

* Manning, Christopher D., Surdeanu, Mihai, Bauer, John, Finkel, Jenny, Bethard, Steven J., and McClosky, David. 2014. <b>The Stanford CoreNLP Natural Language Processing Toolkit.</b> In Proceedings of 52nd Annual Meeting of the Association for Computational Linguistics: System Demonstrations, pp. 55-60. </cite>

Two old versions of the Charniak parser. Copyright Mark Johnson, Eugene Charniak, 24th November 2005 --- August 2006.
References:

* Eugene Charniak and Mark Johnson. <b>Coarse-to-fine n-best parsing and
  MaxEnt discriminative reranking.</b> Proceedings of the 43rd Annual Meeting on Association for Computational Linguistics. Association for Computational Linguistics, 2005.

* Eugene Charniak. <b>A maximum-entropy-inspired parser.</b> Proceedings of the 1st North American chapter of the Association for Computational linguistics conference. Association for Computational Linguistics, 2000.


## Copyright notice and statement of copying permission

Copyright (C) 2015 WING, NUS and NUS NLP Group.                                                                     
                                                                                                  
This program is free software: you can redistribute it and/or modify it under the terms of the    
GNU General Public License as published by the Free Software Foundation, either version 3 of the  
License, or (at your option) any later version.                                                   
                                                                                                  
This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without 
even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU     
General Public License for more details.                                                          
                                                                                                  
You should have received a copy of the GNU General Public License along with this program. If     
not, see http://www.gnu.org/licenses/.                                                            
                                                                                                  
