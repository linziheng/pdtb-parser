#A PDTB-Styled End-to-End Discourse Parser

##Required libraries

- Ruby (1.8.7)

- Rubygems

- OpenNLP Tools (opennlp-tools-1.3.0) 

  opennlp-tools-1.3.0.jar and jwnl-1.3.3.jar of the package needed

- OpenNLP MaxEnt (maxent-2.5.2) 

  maxent-2.5.2.jar and trove.jar of the package needed

- Stanford Parser (stanford-parser-2010-08-20)

- Morpha (http://www.informatics.susx.ac.uk/research/groups/nlp/carroll/morph.html)

  You need to use one of morpha.{ix86_linux|ppc_darwin|sun4_sunos} depending on your system

##Install

- Install the required libraries

- Change line 3 - 6 of src/variable.rb to point to your downloaded Stanford Parser, OpenNLP Tools, OpenNLP MaxEnt, and morpha.


##Running the parser

./parse.rb text-file

The input text is raw text in which paragraphs are separated by empty lines.

E.g., ./parse.rb ../test1


##Output format

- Explicit relations:

Example (1):

**{Exp_2_conn_Concession** Although **Exp_2_conn}** **{Exp_2_Arg2** preliminary findings were reported more than a year ago , **Exp_2_Arg2}** **{Exp_2_Arg1** the latest results appear in today 's New England Journal of Medicine , a forum likely to bring new attention to the problem . **Exp_2_Arg1}**

Explicit relations consist of 16 PDTB level-2 types: Asynchronous, Synchrony, Cause, Pragmatic_cause, Condition, Pragmatic_condition, Contrast, Pragmatic_contrast, Concession, Pragmatic_concession, Conjunction, Instantiation, Restatement, Alternative, Exception List

The connective string of an explicit relation is enclosed by **{Exp_id_conn_type** and **Exp_id_conn}**, where **id** and **type** are the id and relation type assigned to this explicit relation. Arg1 span is enclosed by **{Exp_id_Arg1** and **Exp_id_Arg1}**, and Arg2 span is enclosed by **{Exp_id_Arg2** and **Exp_id_Arg2}**.


- Non-Explicit relations:

Example (2):

**{NonExp_4_Arg1** Neither Lorillard nor the researchers who studied the workers were aware of any research on smokers of the Kent cigarettes . **NonExp_4_Arg1}**
**{NonExp_4_Arg2_Instantiation** `` We have no useful information on whether users are at risk , '' **{Attr_2** said James A. Talcott of Boston 's Dana-Farber Cancer Institute . **NonExp_4_Arg2}** **Attr_2}**

All Implicit, AltLex, EntRel and NoRel relations defined in the PDTB are lumped into Non-Explicit relations. They consist of 13 types: EntRel, NoRel, plus 11 PDTB level-2 types (Asynchronous, Synchrony, Cause, Pragmatic_cause, Contrast, Concession, Conjunction, Instantiation, Restatement, Alternative, List). 

Condition, Pragmatic_condition, Pragmatic_contrast, Pragmatic_concession, and Exception are not included due to lack of training instances.

Arg1 span is enclosed by **{NonExp_id_Arg1** and **NonExp_id_Arg1}**, and Arg2 span is enclosed by **{NonExp_id_Arg2** and **NonExp_id_Arg2}**.


- Attribution spans:

Attribution spans are enclosed by **{Attr_id** and **Attr_id}**. See example (2): **{Attr_2** said James A. Talcott of Boston 's Dana-Farber Cancer Institute . **Attr_2}**


##How to cite this work

Ziheng Lin, Hwee Tou Ng and Min-Yen Kan (2014). A PDTB-Styled End-to-End Discourse Parser. Natural Language Engineering, 20, pp 151-184. Cambridge University Press.


##Copyright notice and statement of copying permission

Copyright 2010-2012 Ziheng Lin

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
