%{
  /*
   morphg.lex - morphological generator created automatically from a
   morphological analyser developed by Kevin Humphreys
   <kwh@dcs.shef.ac.uk> and John Carroll
   <John.Carroll@cogs.susx.ac.uk> and Guido Minnen
   <Guido.Minnen@cogs.susx.ac.uk>.

   Copyright (c) 1998-2001 University of Sussex
   All rights reserved.

   Redistribution and use of source and derived binary forms are
   permitted provided that: 
   - they are not to be used in commercial products
   - the above copyright notice and this paragraph are duplicated in
   all such forms
   - any documentation, advertising materials, and other materials
   related to such distribution and use acknowledge that the software
   was developed by John Carroll <john.carroll@cogs.susx.ac.uk> and
   Guido Minnen <Guido.Minnen@cogs.susx.ac.uk> and refer to the
   following related publication:

     Guido Minnen, John Carroll and Darren Pearce. 2000. Robust, Applied
     Morphological Generation. In Proceedings of the First International
     Natural Language Generation Conference (INLG), Mitzpe Ramon, Israel.
     201-208.

   The name of University of Sheffield may not be used to endorse or
   promote products derived from this software without specific prior
   written permission.
  
   This software is provided "as is" and without any express or
   implied warranties, including, without limitation, the implied
   warranties of merchantibility and fitness for a particular purpose.

   If you make any changes, the authors would appreciate it
   if you sent them details of what you have done.

   Covers the English productive affixes:

   -s	  plural of nouns, 3rd sing pres of verbs
   -ed	  past tense
   -en    past participle
   -ing	  progressive of verbs

   Compilation: flex -i -8 -Cfe -omorphg.yy.c morphg.lex
                gcc -o morphg morphg.yy.c

   Usage:       morphg [options:actuf verbstem-file] < file.txt 
   N.B. A file with a list of verb stems that allow for 
	consonant doubling in British English (called 'verbstem.list')
        is expected to be present in the same directory as morphg

   Options: (Are the same as those of morpha; for morphg option 'a'
             is vacuous though.)
            c this option ensures that casing is left untouched
              wherever possible
            t this option ensures that tags are output; N.B. if
              the option 'u' is set and the input text is tagged 
	      the tag will always be output even if this option 
	      is not set
            u this option should be used when the input file is 
	      untagged
            f a file with British English verb stems that allow for 
	      consonant doubling (called 'verbstem.list') is expected 
	      to be present in the same directory as morphg; using 
	      this option it is possible to specify a different file,
	      i.e., 'verbstem-file'

   Guido Minnen <Guido.Minnen@cogs.susx.ac.uk>
   original version: 03/12/98 - normal form and  different treatment of 
	                        consonant doubling introduced in order to 
				support automatic reversal; usage of 
				external list of verb stems (derived 
		                from the BNC) that allow for consonant 
				doubling in British English introduced
	    revised: 19/05/99 - improvement of option handling
	    revised: 03/08/99 - introduction of option -f; adaption of 
	                        normal form to avoid the loss of case 
   				information
	    revised: 01/09/99 - changed from normal form to compiler 
	                        directives format
	    revised: 02/12/99 - incorporated data extracted from the 
	 			CELEX lexical databases 
	    revised: 07/06/00 - adaption of Makefile to enable various 
	                        Flex optimizations 

   John Carroll <John.Carroll@cogs.susx.ac.uk>
            revised: 25/01/01 - new version of inversion program,
                                associated changes to directives; new
                                C preprocessor flag 'interactive'

   Diana McCarthy <dianam@cogs.susx.ac.uk>
            revised: 23/02/02 - fixed bug reading in verbstem file.
 
   John Carroll <John.Carroll@cogs.susx.ac.uk>
            revised: 19/06/02 - inversion was incorrect for e.g. verbs
                                ending VVC -- fixed
 
   Exception lists are taken from WordNet 1.5, the CELEX lexical
   database (Copyright Centre for Lexical Information; Baayen,
   Piepenbrock and Van Rijn; 1993) and various other corpora and MRDs.

   Many thanks to Chris Brew, Bill Fisher, Gerald Gazdar, Dale
   Gerdemann, Adam Kilgarriff and Ehud Reiter for suggested improvements 
   
   WordNet> WordNet 1.5 Copyright 1995 by Princeton University.
   WordNet> All rights reseved.
   WordNet>
   WordNet> THIS SOFTWARE AND DATABASE IS PROVIDED "AS IS" AND PRINCETON
   WordNet> UNIVERSITY MAKES NO REPRESENTATIONS OR WARRANTIES, EXPRESS OR
   WordNet> IMPLIED.  BY WAY OF EXAMPLE, BUT NOT LIMITATION, PRINCETON
   WordNet> UNIVERSITY MAKES NO REPRESENTATIONS OR WARRANTIES OF MERCHANT-
   WordNet> ABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE OR THAT THE USE
   WordNet> OF THE LICENSED SOFTWARE, DATABASE OR DOCUMENTATION WILL NOT
   WordNet> INFRINGE ANY THIRD PARTY PATENTS, COPYRIGHTS, TRADEMARKS OR
   WordNet> OTHER RIGHTS.
   WordNet>
   WordNet> The name of Princeton University or Princeton may not be used in
   WordNet> advertising or publicity pertaining to distribution of the software
   WordNet> and/or database.  Title to copyright in this software, database and
   WordNet> any associated documentation shall at all times remain with
   WordNet> Princeton Univerisy and LICENSEE agrees to preserve same.

  */
 
#include <string.h>

#ifdef interactive 
#define YY_INPUT(buf,result,max_size) \
              { \
              int c = getchar(); \
              result = (c == EOF) ? YY_NULL : (buf[0] = c, 1); \
              }
#define ECHO (void) fwrite( yytext, yyleng, 1, yyout ); fflush(yyout)
#endif

#define TRUE  (1==1)
#define FALSE  (1==0)
#define forever (TRUE)
#define UnSetOption(o)	(options.o = 0)
#define SetOption(o)	(options.o = 1)
#define Option(o)	(options.o)
#define MAXSTR    200

#ifdef __cplusplus
void downcase( char *text, int len );
char *upcase( char *vanilla_text );
char up8(char c);
int scmp(const char *a, const char *b);
int vcmp(const void *a, const void *b);
int gstem(int del, char *add);
int gcondub_stem(int del, char *add);
int gsemi_reg_stem(int del, char *add);
void capitalise( char *text, int len );
int proper_name_stem();
int common_noun_stem();
int gnull_stem();
int nnull_stem();
char get_option(int argc, char *argv[], char *options, int *arg, , int *i);
int read_verbstem(char *fn);
BOOL read_verbstem_file(char *argv[],unsigned int maxbuff, int *arg, int *i,char letter);
void set_up_options(int argc, char *argv[]);
#endif

int lex_tag;

typedef struct
    {unsigned int
		print_affixes : 1,
		change_case   : 1,
                tag_output    : 1,
		fspec         : 1;
} options_st;
typedef int BOOL;

options_st options;
int state;

%}

%option noyywrap

%x verb noun any scan

A ['+a-z0-9]
V [aeiou]
VY [aeiouy]
C [bcdfghjklmnpqrstvwxyz]
CXY [bcdfghjklmnpqrstvwxz]
CXY2 "bb"|"cc"|"dd"|"ff"|"gg"|"hh"|"jj"|"kk"|"ll"|"mm"|"nn"|"pp"|"qq"|"rr"|"ss"|"tt"|"vv"|"ww"|"xx"|"zz"
S2 "ss"|"zz"
S [sxz]|([cs]"h")
PRE "be"|"ex"|"in"|"mis"|"pre"|"pro"|"re"
EDING "en"|"ed"|"ing"
ESEDING "en"|"es"|"ed"|"ing"

AFFS "+en"|"+ed"|"+"
SAFFS "+s"
ALLAFFS "+en"|"+ed"|"+s"|"+"

G [^[:space:]_<>]
G- [^[:space:]_<>-]
SKIP [[:space:]]

%%

<verb,any>shall{ALLAFFS}  { return(nnull_stem()); }
<verb,any>would{ALLAFFS}  { return(nnull_stem()); }
<verb,any>may{ALLAFFS}  { return(nnull_stem()); }
<verb,any>might{ALLAFFS}  { return(nnull_stem()); }
<verb,any>ought{ALLAFFS}  { return(nnull_stem()); }
<verb,any>should{ALLAFFS}  { return(nnull_stem()); }
<verb,any>be"+"  { return(gstem(3,"am")); }
  /* disprefer <verb,any>be"+"  { return(gstem(3,"are")); } */
<verb,any>be"+"s  { return(gstem(4,"is")); }
<verb,any>be"+"ed  { return(gstem(5,"was")); }
  /* disprefer <verb,any>be"+"ed  { return(gstem(5,"wast")); } */
  /* disprefer <verb,any>be"+"ed  { return(gstem(5,"wert")); } */
  /* disprefer <verb,any>be"+"ed  { return(gstem(5,"were")); } */
<verb,any>be"+"ing  { return(gstem(6,"being")); }
<verb,any>be"+"en  { return(gstem(5,"been")); }
<verb,any>have"+"e[dn]  { return(gstem(7,"had")); }
<verb,any>have"+"s  { return(gstem(6,"has")); }
  /* disprefer <verb,any>have"+"s  { return(gstem(6,"hath")); } */
<verb,any>do"+"s  { return(gstem(4,"does")); }
<verb,any>do"+"ed  { return(gstem(5,"did")); }
<verb,any>do"+"en  { return(gstem(5,"done")); }
  /* disprefer <verb,any>do"+"ed  { return(gstem(5,"didst")); } */
<verb,any>will"+"  { return(gstem(5,"'ll")); }
  /* disprefer <verb,any>be"+"  { return(gstem(3,"'m")); } */
  /* disprefer <verb,any>be"+"  { return(gstem(3,"'re")); } */
<verb,any>have"+"  { return(gstem(5,"'ve")); }

<verb,any>(beat|browbeat)"+"en  { return(gstem(3,"en")); }
<verb,any>(beat|beset|bet|broadcast|browbeat|burst|cost|cut|hit|let|set|shed|shut|slit|split|put|quit|spread|sublet|spred|thrust|upset|hurt|bust|cast|forecast|inset|miscast|mishit|misread|offset|outbid|overbid|preset|read|recast|reset|telecast|typecast|typeset|underbid|undercut|wed|wet){AFFS}  { return(gnull_stem()); }
<verb,noun,any>ache"+"s  { return(gstem(3,"es")); }
<verb,any>ape"+"e[dn]  { return(gstem(4,"ed")); }
<verb,any>ax"+"e[dn]  { return(gstem(3,"ed")); }
<verb,any>(bias|canvas)"+"s  { return(gstem(2,"es")); }
<verb,any>(cadd|v)ie"+"e[dn]  { return(gstem(4,"ed")); }
<verb,any>(cadd|v)ie"+"ing  { return(gstem(6,"ying")); }
<verb,noun,any>cooee"+"s  { return(gstem(3,"es")); }
<verb,any>cooee"+"e[dn]  { return(gstem(5,"eed")); }
<verb,any>(ey|dy)e"+"e[dn]  { return(gstem(4,"ed")); }
<verb,any>eye"+"ing  { return(gstem(4,"ing")); }
  /* disprefer <verb,any>eye"+"ing  { return(gstem(5,"ing")); } */
<verb,any>die"+"ing  { return(gstem(6,"ying")); }
<verb,any>(geld|gild)"+"ed  { return(gstem(3,"ed")); }
<verb,any>(outvi|hi)e"+"ed  { return(gstem(4,"ed")); }
<verb,any>outlie"+"e[dn]  { return(gstem(5,"ay")); }
<verb,any>rebind"+"e[dn]  { return(gstem(6,"ound")); }
<verb,any>plummet"+"s  { return(gstem(2,"s")); }
<verb,any>queue"+"ing  { return(gstem(4,"ing")); }
<verb,any>stomach"+"s  { return(gstem(2,"s")); }
<verb,any>trammel"+"s  { return(gstem(2,"s")); }
<verb,any>tarmac"+"e[dn]  { return(gstem(3,"ked")); }
<verb,any>transfix"+"e[dn]  { return(gstem(3,"ed")); }
<verb,any>underlie"+"ed  { return(gstem(5,"ay")); }
<verb,any>overlie"+"ed  { return(gstem(5,"ay")); }
<verb,any>overfly"+"en  { return(gstem(4,"own")); }
<verb,any>relay"+"e[dn]  { return(gstem(5,"aid")); }
<verb,any>shit"+"e[dn]  { return(gstem(6,"hat")); }
<verb,any>bereave"+"e[dn]  { return(gstem(7,"eft")); }
  /* disprefer <verb,any>cleave"+"e[dn]  { return(gstem(7,"ave")); } */
  /* disprefer <verb,any>work"+"e[dn]  { return(gstem(6,"rought")); } */
  /* disprefer <verb,any>dare"+"e[dn]  { return(gstem(6,"urst")); } */
<verb,any>foreswear"+"e[dn]  { return(gstem(6,"ore")); }
<verb,any>outfight"+"e[dn]  { return(gstem(7,"ought")); }
<verb,any>garotte"+"ing  { return(gstem(5,"ing")); }
<verb,any>shear"+"en  { return(gstem(6,"orn")); }
  /* disprefer <verb,any>speak"+"e[dn]  { return(gstem(6,"ake")); } */
<verb,any>(analys|paralys|cach|brows|glimps|collaps|eclips|elaps|laps|traips|relaps|puls|repuls|cleans|rins|recompens|condens|dispens|incens|licens|sens|tens)e"+"s  { return(gstem(2,"s")); }
<verb,any>cache"+"ed  { return(gstem(4,"ed")); }
<verb,any>cache"+"ing  { return(gstem(5,"ing")); }
<verb,any>(tun|gangren|wan|grip|unit|coher|comper|rever|semaphor|commun|reunit|dynamit|superven|telephon|ton|aton|bon|phon|plan|profan|importun|enthron|elop|interlop|sellotap|sideswip|slop|scrap|mop|lop|expung|lung|past|premier|rang|secret)e"+"{EDING}  { return(gsemi_reg_stem(1,"")); }
<verb,any>(unroll|unscroll)"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>unseat"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>whang"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>(bath|billet|collar|ballot|earth|fathom|fillet|mortar|parrot|profit|ransom|slang)"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>(disunit|aquaplan|enplan|reveng|ripost|sein)e"+"e[dn]  { return(gstem(4,"ed")); }
  /* disprefer <verb,any>tope"+"ing  { return(gstem(5,"ing")); } */
<verb,any>(disti|fulfi|appa)l"+"s  { return(gstem(2,"ls")); }
<verb,any>(overca|misca)ll"+"ed  { return(gstem(3,"ed")); }
<verb,any>catcall"+"ing  { return(gstem(4,"ing")); }
<verb,any>(catcall|squall)"+"ing  { return(gstem(4,"ing")); }
<verb,any>(browbeat|ax|dubbin)"+"ing  { return(gstem(4,"ing")); }
<verb,any>summons"+"s  { return(gstem(2,"es")); }
<verb,any>putt"+"ed  { return(gstem(3,"ed")); }
<verb,any>summons"+"ed  { return(gstem(3,"ed")); }
<verb,any>(sugar|tarmacadam|beggar|betroth|boomerang|chagrin|envenom|miaou|pressgang)"+"ed  { return(gstem(3,"ed")); }
<verb,any>abide"+"e[dn]  { return(gstem(6,"ode")); }
<verb,any>aby"+"e[dn]  { return(gstem(4,"ought")); }
<verb,any>aby"+"s  { return(gstem(2,"es")); }
  /* disprefer <verb,any>address"+"e[dn]  { return(gstem(6,"est")); } */
<verb,any>age"+"ing  { return(gstem(5,"eing")); }
<verb,any>agree"+"e[dn]  { return(gstem(5,"eed")); }
<verb,any>ante"+"e[dn]  { return(gstem(5,"ted")); }
<verb,any>ante"+"s  { return(gstem(3,"es")); }
<verb,any>arise"+"en  { return(gstem(5,"sen")); }
<verb,any>arise"+"ed  { return(gstem(6,"ose")); }
<verb,any>eat"+"ed  { return(gstem(6,"ate")); }
<verb,any>awake"+"ed  { return(gstem(6,"oke")); }
<verb,any>awake"+"en  { return(gstem(6,"oken")); }
<verb,any>backbite"+"ed  { return(gstem(7,"bit")); }
<verb,any>backbite"+"ing  { return(gstem(6,"ting")); }
<verb,any>backbite"+"en  { return(gstem(4,"ten")); }
<verb,any>backslide"+"ed  { return(gstem(7,"lid")); }
<verb,any>backslide"+"en  { return(gstem(4,"den")); }
  /* disprefer <verb,any>bid"+"ed  { return(gstem(6,"bad")); } */
<verb,any>bid"+"ed  { return(gstem(5,"ade")); }
<verb,any>bandy"+"s  { return(gstem(3,"ieds")); }
<verb,any>become"+"e[dn]  { return(gstem(6,"ame")); }
<verb,any>befall"+"en  { return(gstem(4,"len")); }
<verb,any>befall"+"ing  { return(gstem(5,"ling")); }
<verb,any>befall"+"ed  { return(gstem(6,"ell")); }
<verb,any>begin"+"ed  { return(gstem(6,"gan")); }
  /* disprefer <verb,any>beget"+"ed  { return(gstem(6,"gat")); } */
<verb,any>begird"+"e[dn]  { return(gstem(6,"irt")); }
<verb,any>beget"+"ed  { return(gstem(6,"got")); }
<verb,any>beget"+"en  { return(gstem(5,"otten")); }
<verb,any>begin"+"en  { return(gstem(6,"gun")); }
<verb,any>behold"+"ed  { return(gstem(6,"eld")); }
<verb,any>behold"+"en  { return(gstem(4,"den")); }
<verb,any>bename"+"e[dn]  { return(gstem(6,"empt")); }
<verb,any>bend"+"e[dn]  { return(gstem(6,"ent")); }
<verb,any>beseech"+"e[dn]  { return(gstem(7,"ought")); }
<verb,any>bespeak"+"ed  { return(gstem(6,"oke")); }
<verb,any>bespeak"+"en  { return(gstem(6,"oken")); }
<verb,any>bestrew"+"en  { return(gstem(5,"ewn")); }
  /* disprefer <verb,any>bestride"+"ed  { return(gstem(7,"rid")); } */
<verb,any>bestride"+"en  { return(gstem(4,"den")); }
<verb,any>bestride"+"ed  { return(gstem(6,"ode")); }
<verb,any>betake"+"en  { return(gstem(5,"ken")); }
<verb,any>bethink"+"e[dn]  { return(gstem(6,"ought")); }
<verb,any>betake"+"ed  { return(gstem(6,"ook")); }
<verb,any>bid"+"en  { return(gstem(3,"den")); }
<verb,any>bite"+"ed  { return(gstem(7,"bit")); }
<verb,any>bite"+"ing  { return(gstem(6,"ting")); }
<verb,any>bite"+"en  { return(gstem(4,"ten")); }
<verb,any>bleed"+"e[dn]  { return(gstem(7,"led")); }
  /* disprefer <verb,any>bless"+"e[dn]  { return(gstem(6,"est")); } */
<verb,any>blow"+"ed  { return(gstem(6,"lew")); }
<verb,any>blow"+"en  { return(gstem(5,"own")); }
<verb,any>bog-down"+"e[dn]  { return(gstem(8,"ged-down")); }
<verb,any>bog-down"+"ing  { return(gstem(9,"ging-down")); }
<verb,any>bog-down"+"s  { return(gstem(7,"s-down")); }
<verb,any>boogie"+"e[dn]  { return(gstem(5,"ied")); }
<verb,any>boogie"+"s  { return(gstem(3,"es")); }
<verb,any>bear"+"ed  { return(gstem(6,"ore")); }
  /* disprefer <verb,any>bear"+"en  { return(gstem(6,"orne")); } */
<verb,any>bear"+"en  { return(gstem(6,"orn")); }
<verb,any>buy"+"e[dn]  { return(gstem(5,"ought")); }
<verb,any>bind"+"e[dn]  { return(gstem(6,"ound")); }
<verb,any>breastfeed"+"e[dn]  { return(gstem(7,"fed")); }
<verb,any>breed"+"e[dn]  { return(gstem(7,"red")); }
<verb,any>brei"+"e[dn]  { return(gstem(5,"eid")); }
<verb,any>bring"+"ing  { return(gstem(5,"ging")); }
<verb,any>break"+"ed  { return(gstem(6,"oke")); }
<verb,any>break"+"en  { return(gstem(6,"oken")); }
<verb,any>bring"+"e[dn]  { return(gstem(6,"ought")); }
<verb,any>build"+"e[dn]  { return(gstem(6,"ilt")); }
  /* disprefer <verb,any>burn"+"e[dn]  { return(gstem(5,"rnt")); } */
  /* disprefer <verb,any>bypass"+"e[dn]  { return(gstem(6,"ast")); } */
<verb,any>come"+"e[dn]  { return(gstem(6,"ame")); }
<verb,any>catch"+"e[dn]  { return(gstem(6,"ught")); }
<verb,any>chasse"+"e[dn]  { return(gstem(5,"sed")); }
<verb,any>chasse"+"ing  { return(gstem(5,"eing")); }
<verb,any>chasse"+"s  { return(gstem(3,"es")); }
  /* disprefer <verb,any>chivy"+"e[dn]  { return(gstem(6,"evied")); } */
  /* disprefer <verb,any>chivy"+"s  { return(gstem(5,"evies")); } */
  /* disprefer <verb,any>chivy"+"ing  { return(gstem(7,"evying")); } */
  /* disprefer <verb,any>chide"+"ed  { return(gstem(7,"hid")); } */
  /* disprefer <verb,any>chide"+"en  { return(gstem(4,"den")); } */
<verb,any>chivy"+"e[dn]  { return(gstem(4,"vied")); }
<verb,any>chivy"+"s  { return(gstem(3,"vies")); }
<verb,any>chivy"+"ing  { return(gstem(5,"vying")); }
<verb,any>choose"+"ed  { return(gstem(7,"ose")); }
<verb,any>choose"+"en  { return(gstem(6,"sen")); }
<verb,any>clothe"+"e[dn]  { return(gstem(8,"lad")); }
  /* disprefer <verb,any>cleave"+"e[dn]  { return(gstem(7,"eft")); } */
  /* disprefer <verb,any>clepe"+"e[dn]  { return(gstem(6,"ept")); } */
<verb,any>cling"+"ing  { return(gstem(5,"ging")); }
<verb,any>cleave"+"ed  { return(gstem(7,"ove")); }
<verb,any>cleave"+"en  { return(gstem(7,"oven")); }
<verb,any>cling"+"e[dn]  { return(gstem(6,"ung")); }
<verb,any>countersink"+"ed  { return(gstem(6,"ank")); }
<verb,any>countersink"+"en  { return(gstem(6,"unk")); }
<verb,any>creep"+"e[dn]  { return(gstem(6,"ept")); }
<verb,any>crossbreed"+"e[dn]  { return(gstem(7,"red")); }
<verb,any>curet"+"s  { return(gstem(2,"tes")); }
  /* disprefer <verb,any>curse"+"e[dn]  { return(gstem(6,"rst")); } */
<verb,any>deal"+"e[dn]  { return(gstem(5,"alt")); }
<verb,any>decree"+"e[dn]  { return(gstem(5,"eed")); }
<verb,any>degas"+"s  { return(gstem(2,"es")); }
<verb,any>dele"+"ing  { return(gstem(5,"eing")); }
<verb,any>disagree"+"e[dn]  { return(gstem(5,"eed")); }
  /* disprefer <verb,any>disenthral"+"s  { return(gstem(2,"ls")); } */
<verb,any>disenthral"+"s  { return(gstem(3,"ls")); }
<verb,any>dow"+"e[dn]  { return(gstem(4,"ught")); }
  /* disprefer <verb,any>dive"+"e[dn]  { return(gstem(6,"ove")); } */
<verb,any>drink"+"ed  { return(gstem(6,"ank")); }
<verb,any>draw"+"en  { return(gstem(5,"awn")); }
<verb,any>dream"+"e[dn]  { return(gstem(5,"amt")); }
<verb,any>dree"+"e[dn]  { return(gstem(5,"eed")); }
<verb,any>draw"+"ed  { return(gstem(6,"rew")); }
<verb,any>drive"+"en  { return(gstem(5,"ven")); }
<verb,any>drive"+"ed  { return(gstem(6,"ove")); }
<verb,any>drink"+"en  { return(gstem(6,"unk")); }
<verb,any>dig"+"e[dn]  { return(gstem(6,"dug")); }
<verb,any>dwell"+"e[dn]  { return(gstem(6,"elt")); }
<verb,any>eat"+"en  { return(gstem(4,"ten")); }
<verb,any>emcee"+"e[dn]  { return(gstem(5,"eed")); }
<verb,any>enwind"+"e[dn]  { return(gstem(6,"ound")); }
<verb,any>facsimile"+"ing  { return(gstem(5,"eing")); }
<verb,any>fall"+"en  { return(gstem(4,"len")); }
<verb,any>feed"+"e[dn]  { return(gstem(7,"fed")); }
<verb,any>fall"+"ed  { return(gstem(6,"ell")); }
<verb,any>feel"+"e[dn]  { return(gstem(6,"elt")); }
<verb,any>filagree"+"e[dn]  { return(gstem(5,"eed")); }
<verb,any>filigree"+"e[dn]  { return(gstem(5,"eed")); }
<verb,any>fillagree"+"e[dn]  { return(gstem(5,"eed")); }
<verb,any>flee"+"e[dn]  { return(gstem(6,"led")); }
<verb,any>fly"+"ed  { return(gstem(5,"lew")); }
<verb,any>fling"+"ing  { return(gstem(5,"ging")); }
<verb,any>floodlight"+"e[dn]  { return(gstem(8,"lit")); }
<verb,any>fly"+"en  { return(gstem(4,"own")); }
<verb,any>fling"+"e[dn]  { return(gstem(6,"ung")); }
<verb,any>flyblow"+"ed  { return(gstem(6,"lew")); }
<verb,any>flyblow"+"en  { return(gstem(5,"own")); }
<verb,any>forbid"+"ed  { return(gstem(5,"ade")); }
  /* disprefer <verb,any>forbid"+"ed  { return(gstem(6,"bad")); } */
<verb,any>forbid"+"en  { return(gstem(3,"den")); }
<verb,any>forbear"+"ed  { return(gstem(6,"ore")); }
<verb,any>forbear"+"en  { return(gstem(6,"orne")); }
<verb,any>fordo"+"ed  { return(gstem(5,"did")); }
<verb,any>fordo"+"en  { return(gstem(4,"one")); }
<verb,any>foredo"+"ed  { return(gstem(5,"did")); }
<verb,any>foredo"+"en  { return(gstem(4,"one")); }
<verb,any>forego"+"en  { return(gstem(4,"one")); }
<verb,any>foreknow"+"ed  { return(gstem(6,"new")); }
<verb,any>foreknow"+"en  { return(gstem(5,"own")); }
<verb,any>forerun"+"e[dn]  { return(gstem(6,"ran")); }
<verb,any>foresee"+"ed  { return(gstem(6,"saw")); }
<verb,any>foresee"+"en  { return(gstem(5,"een")); }
<verb,any>foreshow"+"en  { return(gstem(5,"own")); }
<verb,any>forespeak"+"ed  { return(gstem(6,"oke")); }
<verb,any>forespeak"+"en  { return(gstem(6,"oken")); }
<verb,any>foretell"+"ing  { return(gstem(5,"ling")); }
<verb,any>foretell"+"e[dn]  { return(gstem(6,"old")); }
<verb,any>forego"+"ed  { return(gstem(5,"went")); }
<verb,any>forgive"+"ed  { return(gstem(6,"ave")); }
<verb,any>forgive"+"en  { return(gstem(5,"ven")); }
<verb,any>forgo"+"en  { return(gstem(4,"one")); }
<verb,any>forget"+"ed  { return(gstem(6,"got")); }
<verb,any>forget"+"en  { return(gstem(5,"otten")); }
<verb,any>forsake"+"en  { return(gstem(5,"ken")); }
<verb,any>forsake"+"ed  { return(gstem(6,"ook")); }
<verb,any>forspeak"+"ed  { return(gstem(6,"oke")); }
<verb,any>forspeak"+"en  { return(gstem(6,"oken")); }
<verb,any>forswear"+"ed  { return(gstem(6,"ore")); }
<verb,any>forswear"+"en  { return(gstem(6,"orn")); }
<verb,any>forgo"+"ed  { return(gstem(5,"went")); }
<verb,any>fight"+"e[dn]  { return(gstem(7,"ought")); }
<verb,any>find"+"e[dn]  { return(gstem(6,"ound")); }
<verb,any>free"+"e[dn]  { return(gstem(5,"eed")); }
<verb,any>fricassee"+"e[dn]  { return(gstem(5,"eed")); }
<verb,any>freeze"+"ed  { return(gstem(7,"oze")); }
<verb,any>freeze"+"en  { return(gstem(7,"ozen")); }
<verb,any>gainsay"+"e[dn]  { return(gstem(5,"aid")); }
<verb,any>gin"+"en  { return(gstem(6,"gan")); }
<verb,any>garnishee"+"e[dn]  { return(gstem(5,"eed")); }
<verb,any>gas"+"s  { return(gstem(2,"es")); }
<verb,any>give"+"ed  { return(gstem(6,"ave")); }
<verb,any>gee"+"e[dn]  { return(gstem(5,"eed")); }
<verb,any>geld"+"e[dn]  { return(gstem(6,"elt")); }
<verb,any>gen-up"+"e[dn]  { return(gstem(6,"ned-up")); }
<verb,any>gen-up"+"ing  { return(gstem(7,"ning-up")); }
<verb,any>gen-up"+"s  { return(gstem(5,"s-up")); }
<verb,any>ghostwrite"+"ing  { return(gstem(6,"ting")); }
<verb,any>ghostwrite"+"en  { return(gstem(4,"ten")); }
<verb,any>ghostwrite"+"ed  { return(gstem(6,"ote")); }
  /* disprefer <verb,any>gild"+"e[dn]  { return(gstem(6,"ilt")); } */
  /* disprefer <verb,any>gird"+"e[dn]  { return(gstem(6,"irt")); } */
<verb,any>give"+"en  { return(gstem(5,"ven")); }
<verb,any>gnaw"+"en  { return(gstem(5,"awn")); }
<verb,any>go"+"en  { return(gstem(4,"one")); }
<verb,any>get"+"ed  { return(gstem(6,"got")); }
<verb,any>get"+"en  { return(gstem(5,"otten")); }
<verb,any>grave"+"en  { return(gstem(5,"ven")); }
<verb,any>gree"+"e[dn]  { return(gstem(5,"eed")); }
<verb,any>grow"+"ed  { return(gstem(6,"rew")); }
  /* disprefer <verb,any>grip"+"e[dn]  { return(gstem(5,"ipt")); } */
<verb,any>grind"+"e[dn]  { return(gstem(6,"ound")); }
<verb,any>grow"+"en  { return(gstem(5,"own")); }
<verb,any>guarantee"+"e[dn]  { return(gstem(5,"eed")); }
<verb,any>hacksaw"+"en  { return(gstem(5,"awn")); }
<verb,any>hamstring"+"ing  { return(gstem(5,"ging")); }
<verb,any>hamstring"+"e[dn]  { return(gstem(6,"ung")); }
<verb,any>handfeed"+"e[dn]  { return(gstem(7,"fed")); }
<verb,any>hear"+"e[dn]  { return(gstem(5,"ard")); }
<verb,any>hold"+"e[dn]  { return(gstem(6,"eld")); }
<verb,any>hew"+"en  { return(gstem(5,"ewn")); }
<verb,any>hide"+"ed  { return(gstem(7,"hid")); }
<verb,any>hide"+"en  { return(gstem(4,"den")); }
<verb,any>honey"+"e[dn]  { return(gstem(5,"ied")); }
  /* disprefer <verb,any>heave"+"e[dn]  { return(gstem(7,"ove")); } */
<verb,any>hang"+"e[dn]  { return(gstem(6,"ung")); }
<verb,any>impanel"+"s  { return(gstem(2,"ls")); }
<verb,any>inbreed"+"e[dn]  { return(gstem(7,"red")); }
<verb,any>indwell"+"ing  { return(gstem(5,"ling")); }
<verb,any>indwell"+"e[dn]  { return(gstem(6,"elt")); }
<verb,any>inlay"+"e[dn]  { return(gstem(5,"aid")); }
<verb,any>interbreed"+"e[dn]  { return(gstem(7,"red")); }
<verb,any>interlay"+"e[dn]  { return(gstem(5,"aid")); }
  /* disprefer <verb,any>interplead"+"e[dn]  { return(gstem(7,"led")); } */
<verb,any>interweave"+"ed  { return(gstem(7,"ove")); }
<verb,any>interweave"+"en  { return(gstem(7,"oven")); }
<verb,any>inweave"+"ed  { return(gstem(7,"ove")); }
<verb,any>inweave"+"en  { return(gstem(7,"oven")); }
  /* disprefer <verb,any>join"+"e[dn]  { return(gstem(5,"int")); } */
<verb,any>ken"+"e[dn]  { return(gstem(5,"ent")); }
<verb,any>keep"+"e[dn]  { return(gstem(6,"ept")); }
<verb,any>knee"+"e[dn]  { return(gstem(5,"eed")); }
<verb,any>kneel"+"e[dn]  { return(gstem(6,"elt")); }
<verb,any>know"+"ed  { return(gstem(6,"new")); }
<verb,any>know"+"en  { return(gstem(5,"own")); }
<verb,any>lade"+"en  { return(gstem(5,"den")); }
<verb,any>ladify"+"e[dn]  { return(gstem(6,"yfied")); }
<verb,any>ladify"+"s  { return(gstem(5,"yfies")); }
<verb,any>ladify"+"ing  { return(gstem(7,"yfying")); }
<verb,any>lay"+"e[dn]  { return(gstem(5,"aid")); }
<verb,any>lie"+"en  { return(gstem(5,"ain")); }
  /* disprefer <verb,any>lean"+"e[dn]  { return(gstem(5,"ant")); } */
<verb,any>leap"+"e[dn]  { return(gstem(5,"apt")); }
<verb,any>learn"+"e[dn]  { return(gstem(5,"rnt")); }
<verb,any>lead"+"e[dn]  { return(gstem(7,"led")); }
<verb,any>leave"+"e[dn]  { return(gstem(7,"eft")); }
<verb,any>lend"+"e[dn]  { return(gstem(6,"ent")); }
<verb,any>light"+"e[dn]  { return(gstem(8,"lit")); }
<verb,any>lose"+"e[dn]  { return(gstem(6,"ost")); }
<verb,any>make"+"e[dn]  { return(gstem(6,"ade")); }
<verb,any>mean"+"e[dn]  { return(gstem(5,"ant")); }
<verb,any>meet"+"e[dn]  { return(gstem(7,"met")); }
<verb,any>misbecome"+"e[dn]  { return(gstem(6,"ame")); }
<verb,any>misdeal"+"e[dn]  { return(gstem(5,"alt")); }
<verb,any>misgive"+"ed  { return(gstem(6,"ave")); }
<verb,any>misgive"+"en  { return(gstem(5,"ven")); }
<verb,any>mishear"+"e[dn]  { return(gstem(5,"ard")); }
<verb,any>mislay"+"e[dn]  { return(gstem(5,"aid")); }
<verb,any>mislead"+"e[dn]  { return(gstem(7,"led")); }
  /* disprefer <verb,any>misplead"+"e[dn]  { return(gstem(7,"led")); } */
  /* disprefer <verb,any>misspell"+"e[dn]  { return(gstem(6,"elt")); } */
<verb,any>misspend"+"e[dn]  { return(gstem(6,"ent")); }
<verb,any>mistake"+"en  { return(gstem(5,"ken")); }
<verb,any>mistake"+"e[dn]  { return(gstem(6,"ook")); }
<verb,any>misunderstand"+"e[dn]  { return(gstem(6,"ood")); }
<verb,any>melt"+"en  { return(gstem(6,"olten")); }
<verb,any>mow"+"en  { return(gstem(5,"own")); }
  /* disprefer <verb,any>outbid"+"en  { return(gstem(3,"den")); } */
<verb,any>outbreed"+"e[dn]  { return(gstem(7,"red")); }
<verb,any>outdo"+"ed  { return(gstem(5,"did")); }
<verb,any>outdo"+"en  { return(gstem(4,"one")); }
<verb,any>outgo"+"en  { return(gstem(4,"one")); }
<verb,any>outgrow"+"ed  { return(gstem(6,"rew")); }
<verb,any>outgrow"+"en  { return(gstem(5,"own")); }
<verb,any>outlay"+"e[dn]  { return(gstem(5,"aid")); }
<verb,any>outrun"+"e[dn]  { return(gstem(6,"ran")); }
<verb,any>outride"+"en  { return(gstem(4,"den")); }
<verb,any>outride"+"ed  { return(gstem(6,"ode")); }
<verb,any>outsell"+"ing  { return(gstem(5,"ling")); }
<verb,any>outshine"+"e[dn]  { return(gstem(6,"one")); }
<verb,any>outshoot"+"e[dn]  { return(gstem(7,"hot")); }
<verb,any>outsell"+"e[dn]  { return(gstem(6,"old")); }
<verb,any>outstand"+"e[dn]  { return(gstem(6,"ood")); }
<verb,any>outthink"+"e[dn]  { return(gstem(6,"ought")); }
<verb,any>outgo"+"e[dn]  { return(gstem(5,"went")); }
<verb,any>outwear"+"ed  { return(gstem(6,"ore")); }
<verb,any>outwear"+"en  { return(gstem(6,"orn")); }
  /* disprefer <verb,any>overbid"+"en  { return(gstem(3,"den")); } */
<verb,any>overblow"+"ed  { return(gstem(6,"lew")); }
<verb,any>overblow"+"en  { return(gstem(5,"own")); }
<verb,any>overbear"+"ed  { return(gstem(6,"ore")); }
<verb,any>overbear"+"en  { return(gstem(6,"orne")); }
<verb,any>overbuild"+"e[dn]  { return(gstem(6,"ilt")); }
<verb,any>overcome"+"e[dn]  { return(gstem(6,"ame")); }
<verb,any>overdo"+"ed  { return(gstem(5,"did")); }
<verb,any>overdo"+"en  { return(gstem(4,"one")); }
<verb,any>overdraw"+"en  { return(gstem(5,"awn")); }
<verb,any>overdraw"+"ed  { return(gstem(6,"rew")); }
<verb,any>overdrive"+"en  { return(gstem(5,"ven")); }
<verb,any>overdrive"+"ed  { return(gstem(6,"ove")); }
<verb,any>overfly"+"e[dn]  { return(gstem(5,"lew")); }
<verb,any>overgrow"+"ed  { return(gstem(6,"rew")); }
<verb,any>overgrow"+"en  { return(gstem(5,"own")); }
<verb,any>overhang"+"ing  { return(gstem(5,"ging")); }
<verb,any>overhear"+"e[dn]  { return(gstem(5,"ard")); }
<verb,any>overhang"+"e[dn]  { return(gstem(6,"ung")); }
<verb,any>overlay"+"e[dn]  { return(gstem(5,"aid")); }
<verb,any>overlie"+"en  { return(gstem(5,"ain")); }
<verb,any>overlie"+"s  { return(gstem(3,"es")); }
<verb,any>overlie"+"ing  { return(gstem(6,"ying")); }
<verb,any>overpay"+"e[dn]  { return(gstem(5,"aid")); }
<verb,any>overpass"+"e[dn]  { return(gstem(6,"ast")); }
<verb,any>overrun"+"e[dn]  { return(gstem(6,"ran")); }
<verb,any>override"+"en  { return(gstem(4,"den")); }
<verb,any>override"+"ed  { return(gstem(6,"ode")); }
<verb,any>oversee"+"ed  { return(gstem(6,"saw")); }
<verb,any>oversee"+"en  { return(gstem(5,"een")); }
<verb,any>oversell"+"ing  { return(gstem(5,"ling")); }
<verb,any>oversew"+"en  { return(gstem(5,"ewn")); }
<verb,any>overshoot"+"e[dn]  { return(gstem(7,"hot")); }
<verb,any>oversleep"+"e[dn]  { return(gstem(6,"ept")); }
<verb,any>oversell"+"e[dn]  { return(gstem(6,"old")); }
<verb,any>overspend"+"e[dn]  { return(gstem(6,"ent")); }
  /* disprefer <verb,any>overspill"+"e[dn]  { return(gstem(6,"ilt")); } */
<verb,any>overtake"+"en  { return(gstem(5,"ken")); }
<verb,any>overthrow"+"ed  { return(gstem(6,"rew")); }
<verb,any>overthrow"+"en  { return(gstem(5,"own")); }
<verb,any>overtake"+"ed  { return(gstem(6,"ook")); }
<verb,any>overwind"+"e[dn]  { return(gstem(6,"ound")); }
<verb,any>overwrite"+"ing  { return(gstem(6,"ting")); }
<verb,any>overwrite"+"en  { return(gstem(4,"ten")); }
<verb,any>overwrite"+"ed  { return(gstem(6,"ote")); }
<verb,any>pay"+"e[dn]  { return(gstem(5,"aid")); }
<verb,any>partake"+"en  { return(gstem(5,"ken")); }
<verb,any>partake"+"ed  { return(gstem(6,"ook")); }
<verb,any>pee"+"e[dn]  { return(gstem(5,"eed")); }
  /* disprefer <verb,any>pen"+"e[dn]  { return(gstem(5,"ent")); } */
  /* disprefer <verb,any>plead"+"e[dn]  { return(gstem(7,"led")); } */
<verb,any>prepay"+"e[dn]  { return(gstem(5,"aid")); }
<verb,any>prologue"+"s  { return(gstem(5,"gs")); }
<verb,any>prove"+"en  { return(gstem(5,"ven")); }
<verb,any>puree"+"e[dn]  { return(gstem(5,"eed")); }
<verb,any>quartersaw"+"en  { return(gstem(5,"awn")); }
<verb,any>queue"+"e[dn]  { return(gstem(5,"ued")); }
<verb,any>queue"+"s  { return(gstem(3,"es")); }
  /* disprefer <verb,any>queue"+"ing  { return(gstem(6,"uing")); } */
<verb,any>run"+"e[dn]  { return(gstem(6,"ran")); }
<verb,any>ring"+"ed  { return(gstem(6,"ang")); }
<verb,any>rarefy"+"e[dn]  { return(gstem(4,"ied")); }
<verb,any>rarefy"+"s  { return(gstem(3,"ies")); }
<verb,any>rarefy"+"ing  { return(gstem(5,"ying")); }
<verb,any>razee"+"ed  { return(gstem(5,"eed")); }
<verb,any>rebuild"+"e[dn]  { return(gstem(6,"ilt")); }
<verb,any>recce"+"e[dn]  { return(gstem(5,"ced")); }
<verb,any>red"+"e[dn]  { return(gstem(6,"red")); }
<verb,any>redo"+"ed  { return(gstem(5,"did")); }
<verb,any>redo"+"en  { return(gstem(4,"one")); }
<verb,any>referee"+"e[dn]  { return(gstem(5,"eed")); }
<verb,any>reave"+"e[dn]  { return(gstem(7,"eft")); }
<verb,any>remake"+"e[dn]  { return(gstem(6,"ade")); }
<verb,any>repay"+"e[dn]  { return(gstem(5,"aid")); }
<verb,any>rerun"+"e[dn]  { return(gstem(6,"ran")); }
<verb,any>resit"+"e[dn]  { return(gstem(6,"sat")); }
<verb,any>retake"+"en  { return(gstem(5,"ken")); }
<verb,any>rethink"+"e[dn]  { return(gstem(6,"ought")); }
<verb,any>retake"+"ed  { return(gstem(6,"ook")); }
<verb,any>rewind"+"e[dn]  { return(gstem(6,"ound")); }
<verb,any>rewrite"+"ing  { return(gstem(6,"ting")); }
<verb,any>rewrite"+"en  { return(gstem(4,"ten")); }
<verb,any>rewrite"+"ed  { return(gstem(6,"ote")); }
<verb,any>ride"+"en  { return(gstem(4,"den")); }
<verb,any>rise"+"en  { return(gstem(5,"sen")); }
<verb,any>rive"+"en  { return(gstem(5,"ven")); }
<verb,any>ride"+"ed  { return(gstem(6,"ode")); }
<verb,any>rise"+"ed  { return(gstem(6,"ose")); }
<verb,any>reeve"+"e[dn]  { return(gstem(7,"ove")); }
<verb,any>ring"+"en  { return(gstem(6,"ung")); }
<verb,any>say"+"e[dn]  { return(gstem(5,"aid")); }
<verb,any>sing"+"ed  { return(gstem(6,"ang")); }
<verb,any>sink"+"ed  { return(gstem(6,"ank")); }
<verb,any>sit"+"e[dn]  { return(gstem(6,"sat")); }
<verb,any>see"+"ed  { return(gstem(6,"saw")); }
<verb,any>saw"+"en  { return(gstem(5,"awn")); }
<verb,any>see"+"en  { return(gstem(5,"een")); }
<verb,any>send"+"e[dn]  { return(gstem(6,"ent")); }
<verb,any>sew"+"en  { return(gstem(5,"ewn")); }
<verb,any>shake"+"en  { return(gstem(5,"ken")); }
<verb,any>shave"+"en  { return(gstem(5,"ven")); }
<verb,any>shend"+"e[dn]  { return(gstem(6,"ent")); }
<verb,any>shew"+"en  { return(gstem(5,"ewn")); }
<verb,any>shoe"+"e[dn]  { return(gstem(6,"hod")); }
<verb,any>shine"+"e[dn]  { return(gstem(6,"one")); }
<verb,any>shake"+"ed  { return(gstem(6,"ook")); }
<verb,any>shoot"+"e[dn]  { return(gstem(7,"hot")); }
<verb,any>show"+"en  { return(gstem(5,"own")); }
<verb,any>shrink"+"ed  { return(gstem(6,"ank")); }
<verb,any>shrive"+"en  { return(gstem(5,"ven")); }
<verb,any>shrive"+"ed  { return(gstem(6,"ove")); }
<verb,any>shrink"+"en  { return(gstem(6,"unk")); }
  /* disprefer <verb,any>shrink"+"en  { return(gstem(6,"unken")); } */
<verb,any>sightsee"+"ed  { return(gstem(6,"saw")); }
<verb,any>sightsee"+"en  { return(gstem(5,"een")); }
<verb,any>ski"+"e[dn]  { return(gstem(4,"i'd")); }
<verb,any>skydive"+"e[dn]  { return(gstem(6,"ove")); }
<verb,any>slay"+"en  { return(gstem(5,"ain")); }
<verb,any>sleep"+"e[dn]  { return(gstem(6,"ept")); }
<verb,any>slay"+"ed  { return(gstem(6,"lew")); }
<verb,any>slide"+"ed  { return(gstem(7,"lid")); }
<verb,any>slide"+"en  { return(gstem(4,"den")); }
<verb,any>sling"+"ing  { return(gstem(5,"ging")); }
<verb,any>sling"+"e[dn]  { return(gstem(6,"ung")); }
<verb,any>slink"+"e[dn]  { return(gstem(6,"unk")); }
  /* disprefer <verb,any>smell"+"e[dn]  { return(gstem(6,"elt")); } */
<verb,any>smite"+"ed  { return(gstem(7,"mit")); }
<verb,any>smite"+"ing  { return(gstem(6,"ting")); }
<verb,any>smite"+"en  { return(gstem(4,"ten")); }
  /* disprefer <verb,any>smite"+"e[dn]  { return(gstem(6,"ote")); } */
<verb,any>sell"+"e[dn]  { return(gstem(6,"old")); }
<verb,any>soothsay"+"e[dn]  { return(gstem(5,"aid")); }
<verb,any>sortie"+"e[dn]  { return(gstem(5,"ied")); }
<verb,any>sortie"+"s  { return(gstem(3,"es")); }
<verb,any>seek"+"e[dn]  { return(gstem(6,"ought")); }
<verb,any>sow"+"en  { return(gstem(5,"own")); }
<verb,any>spit"+"e[dn]  { return(gstem(6,"pat")); }
<verb,any>speed"+"e[dn]  { return(gstem(7,"ped")); }
<verb,any>spellbind"+"e[dn]  { return(gstem(6,"ound")); }
  /* disprefer <verb,any>spell"+"e[dn]  { return(gstem(6,"elt")); } */
<verb,any>spend"+"e[dn]  { return(gstem(6,"ent")); }
  /* disprefer <verb,any>spill"+"e[dn]  { return(gstem(6,"ilt")); } */
<verb,any>spoil"+"e[dn]  { return(gstem(5,"ilt")); }
<verb,any>speak"+"ed  { return(gstem(6,"oke")); }
<verb,any>speak"+"en  { return(gstem(6,"oken")); }
<verb,any>spotlight"+"e[dn]  { return(gstem(8,"lit")); }
<verb,any>spring"+"ed  { return(gstem(6,"ang")); }
<verb,any>spring"+"ing  { return(gstem(5,"ging")); }
<verb,any>spring"+"en  { return(gstem(6,"ung")); }
<verb,any>spin"+"e[dn]  { return(gstem(6,"pun")); }
<verb,any>squeegee"+"e[dn]  { return(gstem(5,"eed")); }
<verb,any>stink"+"ed  { return(gstem(6,"ank")); }
<verb,any>sting"+"ing  { return(gstem(5,"ging")); }
<verb,any>steal"+"ed  { return(gstem(6,"ole")); }
<verb,any>steal"+"en  { return(gstem(6,"olen")); }
<verb,any>stand"+"e[dn]  { return(gstem(6,"ood")); }
<verb,any>stave"+"e[dn]  { return(gstem(6,"ove")); }
<verb,any>strew"+"en  { return(gstem(5,"ewn")); }
<verb,any>stride"+"en  { return(gstem(4,"den")); }
<verb,any>string"+"ing  { return(gstem(5,"ging")); }
<verb,any>strive"+"en  { return(gstem(5,"ven")); }
<verb,any>stride"+"ed  { return(gstem(6,"ode")); }
<verb,any>strive"+"ed  { return(gstem(6,"ove")); }
<verb,any>strow"+"en  { return(gstem(5,"own")); }
<verb,any>strike"+"e[dn]  { return(gstem(6,"uck")); }
<verb,any>string"+"e[dn]  { return(gstem(6,"ung")); }
<verb,any>stick"+"e[dn]  { return(gstem(6,"uck")); }
<verb,any>sting"+"e[dn]  { return(gstem(6,"ung")); }
<verb,any>stink"+"en  { return(gstem(6,"unk")); }
<verb,any>sing"+"en  { return(gstem(6,"ung")); }
<verb,any>sink"+"en  { return(gstem(6,"unk")); }
  /* disprefer <verb,any>sink"+"en  { return(gstem(6,"unken")); } */
<verb,any>swim"+"ed  { return(gstem(6,"wam")); }
<verb,any>sweep"+"e[dn]  { return(gstem(6,"ept")); }
<verb,any>swing"+"ing  { return(gstem(5,"ging")); }
<verb,any>swell"+"en  { return(gstem(6,"ollen")); }
<verb,any>swear"+"ed  { return(gstem(6,"ore")); }
<verb,any>swear"+"en  { return(gstem(6,"orn")); }
<verb,any>swim"+"en  { return(gstem(6,"wum")); }
<verb,any>swing"+"e[dn]  { return(gstem(6,"ung")); }
<verb,any>take"+"en  { return(gstem(5,"ken")); }
<verb,any>teach"+"e[dn]  { return(gstem(7,"aught")); }
  /* disprefer <verb,any>taxi"+"ing  { return(gstem(5,"ying")); } */
<verb,any>tee"+"e[dn]  { return(gstem(5,"eed")); }
<verb,any>think"+"e[dn]  { return(gstem(6,"ought")); }
<verb,any>throw"+"ed  { return(gstem(6,"rew")); }
  /* disprefer <verb,any>thrive"+"en  { return(gstem(5,"ven")); } */
  /* disprefer <verb,any>thrive"+"ed  { return(gstem(6,"ove")); } */
<verb,any>throw"+"en  { return(gstem(5,"own")); }
<verb,any>tinge"+"e[dn]  { return(gstem(5,"ged")); }
<verb,any>tinge"+"ing  { return(gstem(5,"eing")); }
  /* disprefer <verb,any>tinge"+"ing  { return(gstem(6,"ging")); } */
<verb,any>tell"+"e[dn]  { return(gstem(6,"old")); }
<verb,any>take"+"ed  { return(gstem(6,"ook")); }
<verb,any>tear"+"ed  { return(gstem(6,"ore")); }
<verb,any>tear"+"en  { return(gstem(6,"orn")); }
  /* disprefer <verb,any>trammel"+"s  { return(gstem(5,"els")); } */
  /* disprefer <verb,any>transfix"+"e[dn]  { return(gstem(5,"ixt")); } */
<verb,any>transship"+"e[dn]  { return(gstem(7,"hip")); }
<verb,any>tread"+"ed  { return(gstem(7,"rod")); }
<verb,any>tread"+"en  { return(gstem(6,"odden")); }
<verb,any>typewrite"+"ing  { return(gstem(6,"ting")); }
<verb,any>typewrite"+"en  { return(gstem(4,"ten")); }
<verb,any>typewrite"+"ed  { return(gstem(6,"ote")); }
<verb,any>unbend"+"e[dn]  { return(gstem(6,"ent")); }
<verb,any>unbind"+"e[dn]  { return(gstem(6,"ound")); }
<verb,any>unclothe"+"e[dn]  { return(gstem(8,"lad")); }
<verb,any>underbuy"+"e[dn]  { return(gstem(5,"ought")); }
<verb,any>underfeed"+"e[dn]  { return(gstem(7,"fed")); }
<verb,any>undergird"+"e[dn]  { return(gstem(6,"irt")); }
<verb,any>undergo"+"en  { return(gstem(4,"one")); }
<verb,any>underlay"+"e[dn]  { return(gstem(5,"aid")); }
<verb,any>underlie"+"en  { return(gstem(5,"ain")); }
<verb,any>underlie"+"s  { return(gstem(3,"es")); }
<verb,any>underlie"+"ing  { return(gstem(6,"ying")); }
<verb,any>underpay"+"e[dn]  { return(gstem(5,"aid")); }
<verb,any>undersell"+"ing  { return(gstem(5,"ling")); }
<verb,any>undershoot"+"e[dn]  { return(gstem(7,"hot")); }
<verb,any>undersell"+"e[dn]  { return(gstem(6,"old")); }
<verb,any>understand"+"e[dn]  { return(gstem(6,"ood")); }
<verb,any>undertake"+"en  { return(gstem(5,"ken")); }
<verb,any>undertake"+"ed  { return(gstem(6,"ook")); }
<verb,any>undergo"+"ed  { return(gstem(5,"went")); }
<verb,any>underwrite"+"ing  { return(gstem(6,"ting")); }
<verb,any>underwrite"+"en  { return(gstem(4,"ten")); }
<verb,any>underwrite"+"ed  { return(gstem(6,"ote")); }
<verb,any>undo"+"ed  { return(gstem(5,"did")); }
<verb,any>undo"+"en  { return(gstem(4,"one")); }
<verb,any>unfreeze"+"ed  { return(gstem(7,"oze")); }
<verb,any>unfreeze"+"en  { return(gstem(7,"ozen")); }
<verb,any>unlay"+"e[dn]  { return(gstem(5,"aid")); }
<verb,any>unlearn"+"e[dn]  { return(gstem(5,"rnt")); }
<verb,any>unmake"+"e[dn]  { return(gstem(6,"ade")); }
<verb,any>unreeve"+"e[dn]  { return(gstem(7,"ove")); }
<verb,any>unsay"+"e[dn]  { return(gstem(5,"aid")); }
<verb,any>unsling"+"ing  { return(gstem(5,"ging")); }
<verb,any>unsling"+"e[dn]  { return(gstem(6,"ung")); }
<verb,any>unspeak"+"ed  { return(gstem(6,"oke")); }
<verb,any>unspeak"+"en  { return(gstem(6,"oken")); }
<verb,any>unstring"+"ing  { return(gstem(5,"ging")); }
<verb,any>unstring"+"e[dn]  { return(gstem(6,"ung")); }
<verb,any>unstick"+"e[dn]  { return(gstem(6,"uck")); }
<verb,any>unswear"+"ed  { return(gstem(6,"ore")); }
<verb,any>unswear"+"en  { return(gstem(6,"orn")); }
<verb,any>unteach"+"e[dn]  { return(gstem(7,"aught")); }
<verb,any>unthink"+"e[dn]  { return(gstem(6,"ought")); }
<verb,any>untread"+"ed  { return(gstem(7,"rod")); }
<verb,any>untread"+"en  { return(gstem(6,"odden")); }
<verb,any>unwind"+"e[dn]  { return(gstem(6,"ound")); }
<verb,any>upbuild"+"e[dn]  { return(gstem(6,"ilt")); }
<verb,any>uphold"+"e[dn]  { return(gstem(6,"eld")); }
<verb,any>upheave"+"e[dn]  { return(gstem(7,"ove")); }
<verb,any>up"+"e[dn]  { return(gstem(3,"ped")); }
<verb,any>up"+"ing  { return(gstem(4,"ping")); }
<verb,any>uprise"+"en  { return(gstem(5,"sen")); }
<verb,any>uprise"+"ed  { return(gstem(6,"ose")); }
<verb,any>upspring"+"ed  { return(gstem(6,"ang")); }
<verb,any>upspring"+"ing  { return(gstem(5,"ging")); }
<verb,any>upspring"+"en  { return(gstem(6,"ung")); }
<verb,any>upsweep"+"e[dn]  { return(gstem(6,"ept")); }
<verb,any>upswing"+"ing  { return(gstem(5,"ging")); }
  /* disprefer <verb,any>upswell"+"en  { return(gstem(6,"ollen")); } */
<verb,any>upswing"+"e[dn]  { return(gstem(6,"ung")); }
<verb,any>visa"+"e[dn]  { return(gstem(4,"aed")); }
<verb,any>visa"+"ing  { return(gstem(5,"aing")); }
<verb,any>waylay"+"ed  { return(gstem(5,"aid")); }
<verb,any>waylay"+"en  { return(gstem(5,"ain")); }
<verb,any>go"+"ed  { return(gstem(5,"went")); }
<verb,any>weep"+"e[dn]  { return(gstem(6,"ept")); }
<verb,any>whipsaw"+"en  { return(gstem(5,"awn")); }
<verb,any>winterfeed"+"e[dn]  { return(gstem(7,"fed")); }
<verb,any>wiredraw"+"en  { return(gstem(5,"awn")); }
<verb,any>wiredraw"+"ed  { return(gstem(6,"rew")); }
<verb,any>withdraw"+"en  { return(gstem(5,"awn")); }
<verb,any>withdraw"+"ed  { return(gstem(6,"rew")); }
<verb,any>withhold"+"e[dn]  { return(gstem(6,"eld")); }
<verb,any>withstand"+"e[dn]  { return(gstem(6,"ood")); }
<verb,any>wake"+"ed  { return(gstem(6,"oke")); }
<verb,any>wake"+"en  { return(gstem(6,"oken")); }
<verb,any>win"+"e[dn]  { return(gstem(6,"won")); }
<verb,any>wear"+"ed  { return(gstem(6,"ore")); }
<verb,any>wear"+"en  { return(gstem(6,"orn")); }
<verb,any>wind"+"e[dn]  { return(gstem(6,"ound")); }
<verb,any>weave"+"ed  { return(gstem(7,"ove")); }
<verb,any>weave"+"en  { return(gstem(7,"oven")); }
<verb,any>wring"+"ing  { return(gstem(5,"ging")); }
<verb,any>write"+"ing  { return(gstem(6,"ting")); }
<verb,any>write"+"en  { return(gstem(4,"ten")); }
<verb,any>write"+"ed  { return(gstem(6,"ote")); }
<verb,any>wring"+"e[dn]  { return(gstem(6,"ung")); }
  /* disprefer <verb,any>clepe"+"e[dn]  { return(gstem(8,"ycleped")); } */
  /* disprefer <verb,any>clepe"+"e[dn]  { return(gstem(8,"yclept")); } */
<noun,any>ABC"+"s  { return(gstem(5,"ABCs")); }
<noun,any>bacterium"+"s  { return(gstem(4,"a")); }
<noun,any>loggia"+"s  { return(gstem(2,"s")); }
<noun,any>basis"+"s  { return(gstem(4,"es")); }
<noun,any>schema"+"s  { return(gstem(2,"ta")); }
<noun,any>(curi|formul|vertebr|larv|uln|alumn)a"+"s  { return(gstem(2,"e")); }
<noun,any>(beldam|boss|crux|larynx|sphinx|trellis|yes|atlas)"+"s  { return(gstem(2,"es")); }
<noun,any>(alumn|loc|thromb|tars|streptococc|stimul|solid|radi|mag|cumul|bronch|bacill)us"+"s  { return(gstem(4,"i")); }
<noun,any>(Brahman|German|dragoman|ottoman|shaman|talisman|Norman|Pullman|Roman)"+"s  { return(gstem(2,"s")); }
<noun,any>(Czech|diptych|Sassenach|abdomen|alibi|aria|bandit|begonia|bikini|caryatid|colon|cornucopia|cromlech|cupola|dryad|eisteddfod|encyclopaedia|epoch|eunuch|flotilla|gardenia|gestalt|gondola|hierarch|hose|impediment|koala|loch|mania|manservant|martini|matriarch|monarch|oligarch|omen|parabola|pastorale|patriarch|pea|peninsula|pfennig|phantasmagoria|pibroch|poly|real|safari|sari|specimen|standby|stomach|swami|taxi|tech|toccata|triptych|villa|yogi|zloty)"+"s  { return(gstem(2,"s")); }
<noun,any>(asyl|sanct|rect|pl|pendul|mausole|hoodl|for)um"+"s  { return(gstem(2,"s")); }
<noun,any>(Bantu|Bengalese|Beninese|Boche|Burmese|Chinese|Congolese|Gabonese|Guyanese|Japanese|Javanese|Lebanese|Maltese|Olympics|Portuguese|Senegalese|Siamese|Singhalese|Sinhalese|Sioux|Sudanese|Swiss|Taiwanese|Togolese|Vietnamese|aircraft|anopheles|apparatus|asparagus|barracks|bellows|bison|bluefish|bob|bourgeois|bream|brill|butterfingers|carp|catfish|chassis|chub|cod|codfish|coley|contretemps|corps|crawfish|crayfish|crossroads|cuttlefish|dace|dice|dogfish|doings|dory|downstairs|eldest|finnan|firstborn|fish|flatfish|flounder|fowl|fry|fries|{A}+-works|gasworks|glassworks|globefish|goldfish|grand|gudgeon|gulden|haddock|hake|halibut|headquarters|herring|hertz|horsepower|hovercraft|hundredweight|ironworks|jackanapes|kilohertz|kurus|kwacha|ling|lungfish|mackerel|means|megahertz|moorfowl|moorgame|mullet|offspring|pampas|parr|patois|pekinese|penn'orth|perch|pickerel|pike|pince-nez|plaice|precis|quid|rand|rendezvous|revers|roach|roux|salmon|samurai|series|shad|sheep|shellfish|smelt|spacecraft|species|starfish|stockfish|sunfish|superficies|sweepstakes|swordfish|tench|tope|triceps|trout|tuna|tunafish|tunny|turbot|undersigned|veg|waterfowl|waterworks|waxworks|whiting|wildfowl|woodworm|yen){SAFFS}  { return(gnull_stem()); }
<noun,any>Aries"+"s  { return(gstem(3,"s")); }
<noun,any>Pisces"+"s  { return(gstem(3,"s")); }
<noun,any>Bengali"+"s  { return(gstem(3,"i")); }
<noun,any>Somali"+"s  { return(gstem(3,"i")); }
<noun,any>cicatrix"+"s  { return(gstem(3,"ces")); }
<noun,any>cachou"+"s  { return(gstem(2,"s")); }
<noun,any>confidante"+"s  { return(gstem(2,"s")); }
<noun,any>weltanschauung"+"s  { return(gstem(2,"en")); }
<noun,any>apologetic"+"s  { return(gstem(2,"s")); }
<noun,any>due"+"s  { return(gstem(2,"s")); }
<noun,any>whir"+"s  { return(gstem(2,"rs")); }
<noun,any>emu"+"s  { return(gstem(2,"s")); }
<noun,any>equity"+"s  { return(gstem(3,"ies")); }
<noun,any>ethic"+"s  { return(gstem(2,"s")); }
<noun,any>extortion"+"s  { return(gstem(2,"s")); }
<noun,any>folk"+"s  { return(gstem(2,"s")); }
<noun,any>fume"+"s  { return(gstem(2,"s")); }
<noun,any>fungus"+"s  { return(gstem(4,"i")); }
<noun,any>ganglion"+"s  { return(gstem(4,"a")); }
<noun,any>gnu"+"s  { return(gstem(2,"s")); }
<noun,any>going"+"s  { return(gstem(2,"s")); }
<noun,any>grocery"+"s  { return(gstem(3,"ies")); }
<noun,any>guru"+"s  { return(gstem(2,"s")); }
<noun,any>halfpenny"+"s  { return(gstem(4,"ce")); }
<noun,any>hostility"+"s  { return(gstem(3,"ies")); }
<noun,any>hysteric"+"s  { return(gstem(2,"s")); }
<noun,any>impromptu"+"s  { return(gstem(2,"s")); }
<noun,any>incidental"+"s  { return(gstem(2,"s")); }
<noun,any>juju"+"s  { return(gstem(2,"s")); }
<noun,any>landau"+"s  { return(gstem(2,"s")); }
<noun,any>loin"+"s  { return(gstem(2,"s")); }
<noun,any>main"+"s  { return(gstem(2,"s")); }
<noun,any>menu"+"s  { return(gstem(2,"s")); }
  /* disprefer <noun,any>milieu"+"s  { return(gstem(2,"s")); } */
<noun,any>mocker"+"s  { return(gstem(2,"s")); }
<noun,any>moral"+"s  { return(gstem(2,"s")); }
<noun,any>motion"+"s  { return(gstem(2,"s")); }
<noun,any>mu"+"s  { return(gstem(2,"s")); }
<noun,any>nib"+"s  { return(gstem(2,"s")); }
<noun,any>ninepin"+"s  { return(gstem(2,"s")); }
<noun,any>nipper"+"s  { return(gstem(2,"s")); }
<noun,any>oilskin"+"s  { return(gstem(2,"s")); }
<noun,any>overtone"+"s  { return(gstem(2,"s")); }
<noun,any>parvenu"+"s  { return(gstem(2,"s")); }
<noun,any>plastic"+"s  { return(gstem(2,"s")); }
<noun,any>polemic"+"s  { return(gstem(2,"s")); }
<noun,any>race"+"s  { return(gstem(2,"s")); }
<noun,any>refreshment"+"s  { return(gstem(2,"s")); }
<noun,any>reinforcement"+"s  { return(gstem(2,"s")); }
<noun,any>reparation"+"s  { return(gstem(2,"s")); }
<noun,any>return"+"s  { return(gstem(2,"s")); }
<noun,any>rheumatic"+"s  { return(gstem(2,"s")); }
<noun,any>rudiment"+"s  { return(gstem(2,"s")); }
<noun,any>sadhu"+"s  { return(gstem(2,"s")); }
<noun,any>shire"+"s  { return(gstem(2,"s")); }
<noun,any>shiver"+"s  { return(gstem(2,"s")); }
<noun,any>si"+"s  { return(gstem(2,"s")); }
<noun,any>spoil"+"s  { return(gstem(2,"s")); }
<noun,any>stamen"+"s  { return(gstem(2,"s")); }
<noun,any>stay"+"s  { return(gstem(2,"s")); }
<noun,any>subtitle"+"s  { return(gstem(2,"s")); }
<noun,any>tare"+"s  { return(gstem(2,"s")); }
<noun,any>thankyou"+"s  { return(gstem(2,"s")); }
<noun,any>thew"+"s  { return(gstem(2,"s")); }
<noun,any>toil"+"s  { return(gstem(2,"s")); }
<noun,any>tong"+"s  { return(gstem(2,"s")); }
<noun,any>Hindu"+"s  { return(gstem(2,"s")); }
<noun,any>ancient"+"s  { return(gstem(2,"s")); }
<noun,any>bagpipe"+"s  { return(gstem(2,"s")); }
<noun,any>bleacher"+"s  { return(gstem(2,"s")); }
<noun,any>buttock"+"s  { return(gstem(2,"s")); }
<noun,any>common"+"s  { return(gstem(2,"s")); }
<noun,any>Israeli"+"s  { return(gstem(2,"s")); }
  /* disprefer <noun,any>Israeli"+"s  { return(gstem(3,"i")); } */
<noun,any>dodgem"+"s  { return(gstem(2,"s")); }
<noun,any>causerie"+"s  { return(gstem(2,"s")); }
<noun,any>quiche"+"s  { return(gstem(2,"s")); }
<noun,any>ration"+"s  { return(gstem(2,"s")); }
<noun,any>recompense"+"s  { return(gstem(2,"s")); }
<noun,any>rinse"+"s  { return(gstem(2,"s")); }
<noun,any>lied"+"s  { return(gstem(2,"er")); }
<noun,any>passer-by"+"s  { return(gstem(5,"s-by")); }
<noun,any>prolegomenon"+"s  { return(gstem(4,"a")); }
<noun,any>signora"+"s  { return(gstem(3,"e")); }
<noun,any>nepalese"+"s  { return(gstem(3,"e")); }
<noun,any>alga"+"s  { return(gstem(2,"e")); }
<noun,any>clutch"+"s  { return(gstem(2,"es")); }
<noun,any>continuum"+"s  { return(gstem(4,"a")); }
<noun,any>digging"+"s  { return(gstem(2,"s")); }
<noun,any>K"+"s  { return(gstem(2,"'s")); }
<noun,any>seychellois"+"s  { return(gstem(3,"s")); }
<noun,any>afterlife"+"s  { return(gstem(4,"ves")); }
<noun,any>avens"+"s  { return(gstem(3,"s")); }
<noun,any>axis"+"s  { return(gstem(4,"es")); }
<noun,any>bonsai"+"s  { return(gstem(3,"i")); }
<noun,any>coypu"+"s  { return(gstem(2,"s")); }
<noun,any>duodenum"+"s  { return(gstem(4,"a")); }
<noun,any>genie"+"s  { return(gstem(3,"i")); }
<noun,any>leaf"+"s  { return(gstem(3,"ves")); }
<noun,any>mantelshelf"+"s  { return(gstem(3,"ves")); }
<noun,any>meninx"+"s  { return(gstem(3,"ges")); }
<noun,any>moneybags"+"s  { return(gstem(3,"s")); }
<noun,any>obbligato"+"s  { return(gstem(3,"i")); }
<noun,any>orchis"+"s  { return(gstem(2,"es")); }
<noun,any>palais"+"s  { return(gstem(3,"s")); }
<noun,any>pancreas"+"s  { return(gstem(2,"es")); }
<noun,any>phalanx"+"s  { return(gstem(3,"ges")); }
<noun,any>portcullis"+"s  { return(gstem(2,"es")); }
<noun,any>pubes"+"s  { return(gstem(3,"s")); }
<noun,any>pulse"+"s  { return(gstem(2,"s")); }
<noun,any>ratlin"+"s  { return(gstem(2,"es")); }
<noun,any>signor"+"s  { return(gstem(2,"i")); }
<noun,any>spindle-shanks"+"s  { return(gstem(3,"s")); }
<noun,any>substratum"+"s  { return(gstem(4,"a")); }
<noun,any>woolly"+"s  { return(gstem(4,"ies")); }
<noun,any>moggy"+"s  { return(gstem(3,"ies")); }
<noun,any>(ghill|group|honk|mean|road|short|smooth|book|cabb|hank|toots|tough|trann)ie"+"s  { return(gstem(3,"es")); }
<noun,any>(christmas|judas)"+"s  { return(gstem(2,"es")); }
  /* disprefer <noun,any>(flamb|plat|portmant|tabl|b|bur|trouss)eau"+"s  { return(gstem(3,"us")); } */
<noun,any>(maharaj|raj|myn|mull)a"+"s  { return(gstem(2,"hs")); }
<noun,any>(Boch|apocalyps|aps|ars|avalanch|backach|tens|relaps|barouch|brioch|cloch|collaps|cops|crech|crevass|douch|eclips|expans|expens|finess|glimps|gouach|heartach|impass|impuls|laps|mans|microfich|mouss|nonsens|pastich|peliss|poss|prolaps|psych)e"+"s  { return(gstem(2,"s")); }
<noun,any>addendum"+"s  { return(gstem(5,"da")); }
<noun,any>adieu"+"s  { return(gstem(3,"ux")); }
<noun,any>aide-de-camp"+"s  { return(gstem(10,"s-de-camp")); }
<noun,any>alias"+"s  { return(gstem(2,"es")); }
<noun,any>alkali"+"s  { return(gstem(2,"es")); }
<noun,any>alto"+"s  { return(gstem(4,"ti")); }
<noun,any>amanuensis"+"s  { return(gstem(4,"es")); }
<noun,any>analysis"+"s  { return(gstem(4,"es")); }
<noun,any>anthrax"+"s  { return(gstem(3,"ces")); }
<noun,any>antithesis"+"s  { return(gstem(4,"es")); }
<noun,any>aphis"+"s  { return(gstem(3,"des")); }
<noun,any>apex"+"s  { return(gstem(4,"ices")); }
<noun,any>appendix"+"s  { return(gstem(3,"ces")); }
<noun,any>arboretum"+"s  { return(gstem(5,"ta")); }
  /* disprefer <noun,any>atlas"+"s  { return(gstem(3,"ntes")); } */
<noun,any>eyrir"+"s  { return(gstem(7,"aurar")); }
<noun,any>automaton"+"s  { return(gstem(5,"ta")); }
  /* disprefer <noun,any>axis"+"s  { return(gstem(2,"es")); } */
<noun,any>bambino"+"s  { return(gstem(4,"ni")); }
<noun,any>bandeau"+"s  { return(gstem(3,"ux")); }
  /* disprefer <noun,any>bandit"+"s  { return(gstem(2,"ti")); } */
<noun,any>basso"+"s  { return(gstem(4,"si")); }
<noun,any>beau"+"s  { return(gstem(3,"ux")); }
<noun,any>beef"+"s  { return(gstem(3,"ves")); }
<noun,any>biceps"+"s  { return(gstem(2,"es")); }
<noun,any>bijou"+"s  { return(gstem(3,"ux")); }
<noun,any>billet-doux"+"s  { return(gstem(7,"s-doux")); }
<noun,any>borax"+"s  { return(gstem(3,"ces")); }
  /* disprefer <noun,any>boss"+"s  { return(gstem(2,"ies")); } */
<noun,any>brainchild"+"s  { return(gstem(2,"ren")); }
<noun,any>brother-in-law"+"s  { return(gstem(9,"s-in-law")); }
<noun,any>bucktooth"+"s  { return(gstem(6,"eeth")); }
<noun,any>bund"+"s  { return(gstem(3,"de")); }
<noun,any>bureau"+"s  { return(gstem(3,"ux")); }
<noun,any>cactus"+"s  { return(gstem(4,"i")); }
<noun,any>calf"+"s  { return(gstem(3,"ves")); }
<noun,any>calyx"+"s  { return(gstem(3,"ces")); }
<noun,any>candelabrum"+"s  { return(gstem(5,"ra")); }
  /* disprefer <noun,any>capriccio"+"s  { return(gstem(5,"ci")); } */
<noun,any>caribou"+"s  { return(gstem(3,"us")); }
  /* disprefer <noun,any>caryatid"+"s  { return(gstem(7,"ides")); } */
<noun,any>catalysis"+"s  { return(gstem(4,"es")); }
<noun,any>cerebrum"+"s  { return(gstem(5,"ra")); }
<noun,any>cervix"+"s  { return(gstem(3,"ces")); }
<noun,any>chateau"+"s  { return(gstem(3,"ux")); }
<noun,any>child"+"s  { return(gstem(2,"ren")); }
<noun,any>chilli"+"s  { return(gstem(2,"es")); }
<noun,any>chrysalis"+"s  { return(gstem(3,"des")); }
  /* disprefer <noun,any>chrysalis"+"s  { return(gstem(2,"es")); } */
<noun,any>cicerone"+"s  { return(gstem(4,"ni")); }
<noun,any>cloverleaf"+"s  { return(gstem(3,"ves")); }
<noun,any>coccyx"+"s  { return(gstem(3,"ges")); }
<noun,any>codex"+"s  { return(gstem(4,"ices")); }
<noun,any>colloquy"+"s  { return(gstem(3,"ies")); }
  /* disprefer <noun,any>colon"+"s  { return(gstem(2,"es")); } */
<noun,any>concertante"+"s  { return(gstem(4,"ti")); }
<noun,any>concerto"+"s  { return(gstem(4,"ti")); }
<noun,any>concertino"+"s  { return(gstem(4,"ni")); }
<noun,any>conquistador"+"s  { return(gstem(2,"es")); }
<noun,any>consortium"+"s  { return(gstem(4,"a")); }
<noun,any>contralto"+"s  { return(gstem(4,"ti")); }
<noun,any>corpus"+"s  { return(gstem(4,"ora")); }
<noun,any>corrigendum"+"s  { return(gstem(5,"da")); }
<noun,any>cortex"+"s  { return(gstem(4,"ices")); }
  /* disprefer <noun,any>crescendo"+"s  { return(gstem(4,"di")); } */
<noun,any>crisis"+"s  { return(gstem(4,"es")); }
<noun,any>criterion"+"s  { return(gstem(5,"ia")); }
  /* disprefer <noun,any>crux"+"s  { return(gstem(3,"ces")); } */
<noun,any>cul-de-sac"+"s  { return(gstem(9,"s-de-sac")); }
<noun,any>cyclops"+"s  { return(gstem(3,"es")); }
  /* disprefer <noun,any>cyclops"+"s  { return(gstem(2,"es")); } */
<noun,any>datum"+"s  { return(gstem(5,"ta")); }
<noun,any>daughter-in-law"+"s  { return(gstem(9,"s-in-law")); }
<noun,any>desideratum"+"s  { return(gstem(5,"ta")); }
<noun,any>diaeresis"+"s  { return(gstem(4,"es")); }
  /* disprefer <noun,any>diaeresis"+"s  { return(gstem(6,"ses")); } */
<noun,any>dialysis"+"s  { return(gstem(4,"es")); }
<noun,any>diathesis"+"s  { return(gstem(6,"ses")); }
<noun,any>dictum"+"s  { return(gstem(5,"ta")); }
<noun,any>dieresis"+"s  { return(gstem(4,"es")); }
<noun,any>dilettante"+"s  { return(gstem(3,"es")); }
  /* disprefer <noun,any>dilettante"+"s  { return(gstem(4,"ti")); } */
<noun,any>divertimento"+"s  { return(gstem(4,"ti")); }
<noun,any>dogtooth"+"s  { return(gstem(6,"eeth")); }
<noun,any>dormouse"+"s  { return(gstem(6,"ice")); }
  /* disprefer <noun,any>dryad"+"s  { return(gstem(2,"es")); } */
  /* disprefer <noun,any>duo"+"s  { return(gstem(4,"ui")); } */
  /* disprefer <noun,any>duodenum"+"s  { return(gstem(7,"na")); } */
  /* disprefer <noun,any>duodenum"+"s  { return(gstem(7,"nas")); } */
<noun,any>tutu"+"s  { return(gstem(2,"s")); }
<noun,any>vicissitude"+"s  { return(gstem(2,"s")); }
<noun,any>virginal"+"s  { return(gstem(2,"s")); }
<noun,any>volume"+"s  { return(gstem(2,"s")); }
<noun,any>zebu"+"s  { return(gstem(2,"s")); }
<noun,any>dwarf"+"s  { return(gstem(3,"ves")); }
  /* disprefer <noun,any>eisteddfod"+"s  { return(gstem(2,"au")); } */
<noun,any>ellipsis"+"s  { return(gstem(4,"es")); }
<noun,any>elf"+"s  { return(gstem(3,"ves")); }
<noun,any>emphasis"+"s  { return(gstem(4,"es")); }
<noun,any>epicentre"+"s  { return(gstem(3,"es")); }
<noun,any>epiglottis"+"s  { return(gstem(3,"des")); }
  /* disprefer <noun,any>epiglottis"+"s  { return(gstem(2,"es")); } */
<noun,any>erratum"+"s  { return(gstem(5,"ta")); }
<noun,any>exegesis"+"s  { return(gstem(4,"es")); }
<noun,any>eyetooth"+"s  { return(gstem(6,"eeth")); }
<noun,any>father-in-law"+"s  { return(gstem(9,"s-in-law")); }
<noun,any>foot"+"s  { return(gstem(5,"eet")); }
<noun,any>fellah"+"s  { return(gstem(2,"een")); }
  /* disprefer <noun,any>fellah"+"s  { return(gstem(2,"in")); } */
<noun,any>femur"+"s  { return(gstem(4,"ora")); }
  /* disprefer <noun,any>flagstaff"+"s  { return(gstem(4,"ves")); } */
<noun,any>flambeau"+"s  { return(gstem(3,"ux")); }
<noun,any>flatfoot"+"s  { return(gstem(5,"eet")); }
<noun,any>fleur-de-lis"+"s  { return(gstem(9,"s-de-lis")); }
<noun,any>fleur-de-lys"+"s  { return(gstem(9,"s-de-lys")); }
<noun,any>flyleaf"+"s  { return(gstem(3,"ves")); }
  /* disprefer <noun,any>forum"+"s  { return(gstem(5,"ra")); } */
<noun,any>forceps"+"s  { return(gstem(5,"ipes")); }
<noun,any>forefoot"+"s  { return(gstem(5,"eet")); }
<noun,any>fulcrum"+"s  { return(gstem(5,"ra")); }
<noun,any>gallows"+"s  { return(gstem(2,"es")); }
<noun,any>gas"+"s  { return(gstem(2,"es")); }
  /* disprefer <noun,any>gas"+"s  { return(gstem(2,"ses")); } */
<noun,any>gateau"+"s  { return(gstem(3,"ux")); }
<noun,any>goose"+"s  { return(gstem(6,"eese")); }
<noun,any>gemsbok"+"s  { return(gstem(6,"boks")); }
<noun,any>genus"+"s  { return(gstem(4,"era")); }
<noun,any>genesis"+"s  { return(gstem(4,"es")); }
<noun,any>gentleman-at-arms"+"s  { return(gstem(12,"en-at-arms")); }
  /* disprefer <noun,any>gestalt"+"s  { return(gstem(2,"en")); } */
<noun,any>glissando"+"s  { return(gstem(4,"di")); }
  /* disprefer <noun,any>glottis"+"s  { return(gstem(3,"des")); } */
<noun,any>glottis"+"s  { return(gstem(2,"es")); }
<noun,any>godchild"+"s  { return(gstem(2,"ren")); }
<noun,any>going-over"+"s  { return(gstem(7,"s-over")); }
<noun,any>grandchild"+"s  { return(gstem(2,"ren")); }
<noun,any>half"+"s  { return(gstem(3,"ves")); }
<noun,any>hanger-on"+"s  { return(gstem(5,"s-on")); }
<noun,any>helix"+"s  { return(gstem(3,"ces")); }
<noun,any>hoof"+"s  { return(gstem(3,"ves")); }
  /* disprefer <noun,any>hose"+"s  { return(gstem(3,"en")); } */
<noun,any>hypothesis"+"s  { return(gstem(4,"es")); }
<noun,any>iamb"+"s  { return(gstem(3,"bi")); }
  /* disprefer <noun,any>ibex"+"s  { return(gstem(4,"ices")); } */
  /* disprefer <noun,any>ibis"+"s  { return(gstem(2,"es")); } */
  /* disprefer <noun,any>impediment"+"s  { return(gstem(3,"ta")); } */
<noun,any>index"+"s  { return(gstem(4,"ices")); }
  /* disprefer <noun,any>intaglio"+"s  { return(gstem(5,"li")); } */
<noun,any>intermezzo"+"s  { return(gstem(4,"zi")); }
<noun,any>interregnum"+"s  { return(gstem(5,"na")); }
  /* disprefer <noun,any>iris"+"s  { return(gstem(3,"des")); } */
<noun,any>iris"+"s  { return(gstem(2,"es")); }
<noun,any>is"+"s  { return(gstem(4,"is")); }
<noun,any>jack-in-the-box"+"s  { return(gstem(13,"s-in-the-box")); }
<noun,any>kibbutz"+"s  { return(gstem(2,"im")); }
<noun,any>knife"+"s  { return(gstem(4,"ves")); }
<noun,any>kohlrabi"+"s  { return(gstem(2,"es")); }
  /* disprefer <noun,any>krone"+"s  { return(gstem(3,"en")); } */
<noun,any>krone"+"s  { return(gstem(3,"er")); }
<noun,any>krona"+"s  { return(gstem(3,"or")); }
  /* disprefer <noun,any>krona"+"s  { return(gstem(3,"ur")); } */
<noun,any>kylix"+"s  { return(gstem(3,"kes")); }
<noun,any>lady-in-waiting"+"s  { return(gstem(14,"ies-in-waiting")); }
  /* disprefer <noun,any>larynx"+"s  { return(gstem(3,"ges")); } */
<noun,any>latex"+"s  { return(gstem(4,"ices")); }
<noun,any>lex"+"s  { return(gstem(3,"ges")); }
<noun,any>libretto"+"s  { return(gstem(4,"ti")); }
<noun,any>louse"+"s  { return(gstem(6,"ice")); }
<noun,any>lira"+"s  { return(gstem(4,"re")); }
<noun,any>life"+"s  { return(gstem(4,"ves")); }
<noun,any>loaf"+"s  { return(gstem(3,"ves")); }
  /* disprefer <noun,any>loggia"+"s  { return(gstem(4,"ie")); } */
<noun,any>lustre"+"s  { return(gstem(4,"ra")); }
<noun,any>lying-in"+"s  { return(gstem(5,"s-in")); }
<noun,any>macaroni"+"s  { return(gstem(2,"es")); }
<noun,any>maestro"+"s  { return(gstem(4,"ri")); }
<noun,any>mantis"+"s  { return(gstem(4,"es")); }
  /* disprefer <noun,any>mantis"+"s  { return(gstem(2,"es")); } */
<noun,any>markka"+"s  { return(gstem(3,"aa")); }
<noun,any>marquis"+"s  { return(gstem(2,"es")); }
<noun,any>master-at-arms"+"s  { return(gstem(10,"s-at-arms")); }
<noun,any>matrix"+"s  { return(gstem(3,"ces")); }
<noun,any>matzo"+"s  { return(gstem(2,"th")); }
  /* disprefer <noun,any>mausoleum"+"s  { return(gstem(5,"ea")); } */
<noun,any>maximum"+"s  { return(gstem(5,"ma")); }
<noun,any>memorandum"+"s  { return(gstem(5,"da")); }
<noun,any>man-at-arms"+"s  { return(gstem(12,"en-at-arms")); }
  /* disprefer <noun,any>man-of-war"+"s  { return(gstem(11,"en-o'-war")); } */
<noun,any>man-of-war"+"s  { return(gstem(11,"en-of-war")); }
  /* disprefer <noun,any>manservant"+"s  { return(gstem(11,"enservants")); } */
<noun,any>mademoiselle"+"s  { return(gstem(13,"esdemoiselles")); }
<noun,any>monsieur"+"s  { return(gstem(9,"essieurs")); }
<noun,any>metathesis"+"s  { return(gstem(4,"es")); }
<noun,any>metropolis"+"s  { return(gstem(2,"es")); }
<noun,any>mouse"+"s  { return(gstem(6,"ice")); }
<noun,any>milieu"+"s  { return(gstem(3,"ux")); }
<noun,any>minimum"+"s  { return(gstem(5,"ma")); }
<noun,any>momentum"+"s  { return(gstem(5,"ta")); }
<noun,any>money"+"s  { return(gstem(4,"ies")); }
<noun,any>monsignor"+"s  { return(gstem(3,"ri")); }
<noun,any>mooncalf"+"s  { return(gstem(3,"ves")); }
<noun,any>mother-in-law"+"s  { return(gstem(9,"s-in-law")); }
<noun,any>naiad"+"s  { return(gstem(2,"es")); }
  /* disprefer <noun,any>necropolis"+"s  { return(gstem(4,"eis")); } */
<noun,any>necropolis"+"s  { return(gstem(2,"es")); }
<noun,any>nemesis"+"s  { return(gstem(4,"es")); }
<noun,any>novella"+"s  { return(gstem(4,"le")); }
<noun,any>oasis"+"s  { return(gstem(4,"es")); }
<noun,any>obloquy"+"s  { return(gstem(3,"ies")); }
<noun,any>{A}+hedron"+"s  { return(gstem(5,"ra")); }
<noun,any>optimum"+"s  { return(gstem(5,"ma")); }
<noun,any>os"+"s  { return(gstem(3,"ra")); }
  /* disprefer <noun,any>os"+"s  { return(gstem(2,"ar")); } */
  /* disprefer <noun,any>os"+"s  { return(gstem(2,"sa")); } */
<noun,any>ovum"+"s  { return(gstem(5,"va")); }
<noun,any>ox"+"s  { return(gstem(2,"en")); }
<noun,any>paralysis"+"s  { return(gstem(4,"es")); }
<noun,any>parenthesis"+"s  { return(gstem(4,"es")); }
<noun,any>pari-mutuel"+"s  { return(gstem(9,"s-mutuels")); }
  /* disprefer <noun,any>pastorale"+"s  { return(gstem(4,"li")); } */
<noun,any>paterfamilias"+"s  { return(gstem(12,"resfamilias")); }
  /* disprefer <noun,any>pea"+"s  { return(gstem(2,"se")); } */
  /* disprefer <noun,any>pekinese"+"s  { return(gstem(5,"gese")); } */
  /* disprefer <noun,any>pelvis"+"s  { return(gstem(4,"es")); } */
<noun,any>pelvis"+"s  { return(gstem(2,"es")); }
<noun,any>penny"+"s  { return(gstem(4,"ce")); }
  /* disprefer <noun,any>penis"+"s  { return(gstem(4,"es")); } */
<noun,any>penis"+"s  { return(gstem(2,"es")); }
<noun,any>penknife"+"s  { return(gstem(4,"ves")); }
<noun,any>perihelion"+"s  { return(gstem(5,"ia")); }
  /* disprefer <noun,any>pfennig"+"s  { return(gstem(3,"ge")); } */
<noun,any>pharynx"+"s  { return(gstem(3,"ges")); }
<noun,any>phenomenon"+"s  { return(gstem(5,"na")); }
<noun,any>philodendron"+"s  { return(gstem(5,"ra")); }
<noun,any>pied-a-terre"+"s  { return(gstem(10,"s-a-terre")); }
<noun,any>pinetum"+"s  { return(gstem(5,"ta")); }
<noun,any>plateau"+"s  { return(gstem(3,"ux")); }
<noun,any>plenum"+"s  { return(gstem(5,"na")); }
<noun,any>pocketknife"+"s  { return(gstem(4,"ves")); }
<noun,any>portmanteau"+"s  { return(gstem(3,"ux")); }
<noun,any>potbelly"+"s  { return(gstem(7,"lies")); }
  /* disprefer <noun,any>praxis"+"s  { return(gstem(4,"es")); } */
<noun,any>praxis"+"s  { return(gstem(2,"es")); }
  /* disprefer <noun,any>proboscis"+"s  { return(gstem(3,"des")); } */
<noun,any>proboscis"+"s  { return(gstem(2,"es")); }
<noun,any>prosthesis"+"s  { return(gstem(4,"es")); }
<noun,any>protozoan"+"s  { return(gstem(5,"oa")); }
<noun,any>pudendum"+"s  { return(gstem(5,"da")); }
<noun,any>putto"+"s  { return(gstem(4,"ti")); }
<noun,any>quantum"+"s  { return(gstem(5,"ta")); }
<noun,any>quarterstaff"+"s  { return(gstem(4,"ves")); }
  /* disprefer <noun,any>real"+"s  { return(gstem(2,"es")); } */
  /* disprefer <noun,any>rectum"+"s  { return(gstem(5,"ta")); } */
<noun,any>referendum"+"s  { return(gstem(5,"da")); }
  /* disprefer <noun,any>real"+"s  { return(gstem(4,"is")); } */
<noun,any>rondeau"+"s  { return(gstem(3,"ux")); }
<noun,any>rostrum"+"s  { return(gstem(5,"ra")); }
<noun,any>runner-up"+"s  { return(gstem(5,"s-up")); }
  /* disprefer <noun,any>sanctum"+"s  { return(gstem(5,"ta")); } */
<noun,any>sawbones"+"s  { return(gstem(2,"es")); }
<noun,any>scarf"+"s  { return(gstem(3,"ves")); }
  /* disprefer <noun,any>scherzo"+"s  { return(gstem(4,"zi")); } */
<noun,any>scrotum"+"s  { return(gstem(5,"ta")); }
<noun,any>secretary-general"+"s  { return(gstem(11,"ies-general")); }
<noun,any>self"+"s  { return(gstem(3,"ves")); }
  /* disprefer <noun,any>serum"+"s  { return(gstem(5,"ra")); } */
<noun,any>seraph"+"s  { return(gstem(2,"im")); }
<noun,any>sheaf"+"s  { return(gstem(3,"ves")); }
<noun,any>shelf"+"s  { return(gstem(3,"ves")); }
<noun,any>simulacrum"+"s  { return(gstem(5,"ra")); }
<noun,any>sister-in-law"+"s  { return(gstem(9,"s-in-law")); }
  /* disprefer <noun,any>solo"+"s  { return(gstem(4,"li")); } */
<noun,any>soliloquy"+"s  { return(gstem(3,"ies")); }
<noun,any>son-in-law"+"s  { return(gstem(9,"s-in-law")); }
<noun,any>spectrum"+"s  { return(gstem(5,"ra")); }
  /* disprefer <noun,any>sphinx"+"s  { return(gstem(3,"ges")); } */
<noun,any>splayfoot"+"s  { return(gstem(5,"eet")); }
<noun,any>sputum"+"s  { return(gstem(5,"ta")); }
  /* disprefer <noun,any>stamen"+"s  { return(gstem(4,"ina")); } */
<noun,any>stele"+"s  { return(gstem(3,"ae")); }
<noun,any>stepchild"+"s  { return(gstem(2,"ren")); }
<noun,any>sternum"+"s  { return(gstem(5,"na")); }
<noun,any>stratum"+"s  { return(gstem(5,"ta")); }
<noun,any>stretto"+"s  { return(gstem(4,"ti")); }
<noun,any>summons"+"s  { return(gstem(2,"es")); }
  /* disprefer <noun,any>swami"+"s  { return(gstem(2,"es")); } */
<noun,any>swath"+"s  { return(gstem(2,"es")); }
<noun,any>synopsis"+"s  { return(gstem(4,"es")); }
<noun,any>synthesis"+"s  { return(gstem(4,"es")); }
<noun,any>tableau"+"s  { return(gstem(3,"ux")); }
  /* disprefer <noun,any>taxi"+"s  { return(gstem(2,"es")); } */
<noun,any>tooth"+"s  { return(gstem(6,"eeth")); }
<noun,any>tempo"+"s  { return(gstem(4,"pi")); }
<noun,any>tenderfoot"+"s  { return(gstem(5,"eet")); }
<noun,any>testis"+"s  { return(gstem(4,"es")); }
<noun,any>thesis"+"s  { return(gstem(4,"es")); }
<noun,any>thief"+"s  { return(gstem(3,"ves")); }
<noun,any>thorax"+"s  { return(gstem(3,"ces")); }
<noun,any>titmouse"+"s  { return(gstem(6,"ice")); }
<noun,any>toots"+"s  { return(gstem(2,"es")); }
  /* disprefer <noun,any>torso"+"s  { return(gstem(4,"si")); } */
  /* disprefer <noun,any>triceps"+"s  { return(gstem(2,"es")); } */
<noun,any>triumvir"+"s  { return(gstem(3,"ri")); }
  /* disprefer <noun,any>trousseau"+"s  { return(gstem(3,"ux")); } */
<noun,any>turf"+"s  { return(gstem(3,"ves")); }
<noun,any>tympanum"+"s  { return(gstem(5,"na")); }
<noun,any>ultimatum"+"s  { return(gstem(5,"ta")); }
  /* disprefer <noun,any>vacuum"+"s  { return(gstem(5,"ua")); } */
<noun,any>vertex"+"s  { return(gstem(4,"ices")); }
<noun,any>vertigo"+"s  { return(gstem(3,"ines")); }
<noun,any>virtuoso"+"s  { return(gstem(4,"si")); }
<noun,any>vortex"+"s  { return(gstem(4,"ices")); }
<noun,any>wagon-lit"+"s  { return(gstem(6,"s-lits")); }
<noun,any>weirdie"+"s  { return(gstem(3,"es")); }
<noun,any>werewolf"+"s  { return(gstem(3,"ves")); }
<noun,any>wharf"+"s  { return(gstem(3,"ves")); }
<noun,any>whipper-in"+"s  { return(gstem(5,"s-in")); }
<noun,any>wolf"+"s  { return(gstem(3,"ves")); }
<noun,any>woodlouse"+"s  { return(gstem(6,"ice")); }
  /* disprefer <noun,any>yogi"+"s  { return(gstem(3,"in")); } */
<noun,any>zombie"+"s  { return(gstem(3,"es")); }
  /* disprefer <verb,any>cry"+"e[dn]  { return(gstem(4,"yed")); } */
<verb,any>forte"+"e[dn]  { return(gstem(5,"ted")); }
<verb,any>forte"+"ing  { return(gstem(5,"eing")); }
<verb,any>picknic"+"s  { return(gstem(2,"ks")); }
<verb,any>resell"+"e[dn]  { return(gstem(6,"old")); }
<verb,any>retell"+"e[dn]  { return(gstem(6,"old")); }
<verb,any>retie"+"ing  { return(gstem(6,"ying")); }
<verb,any>singe"+"e[dn]  { return(gstem(5,"ged")); }
<verb,any>singe"+"ing  { return(gstem(5,"eing")); }
<verb,any>trek"+"e[dn]  { return(gstem(4,"cked")); }
<verb,any>trek"+"ing  { return(gstem(5,"cking")); }
<noun,any>canvas"+"s  { return(gstem(2,"es")); }
<noun,any>carcase"+"s  { return(gstem(2,"s")); }
<noun,any>lens"+"s  { return(gstem(2,"es")); }
<verb,any>buffet"+"s  { return(gstem(2,"ts")); }
  /* disprefer <verb,any>plummet"+"s  { return(gstem(2,"ts")); } */
<verb,any>gunsling"+"e[dn]  { return(gstem(6,"ung")); }
<verb,any>gunsling"+"ing  { return(gstem(5,"ging")); }
<noun,any>bias"+"s  { return(gstem(2,"es")); }
<noun,any>biscotto"+"s  { return(gstem(4,"ti")); }
<noun,any>bookshelf"+"s  { return(gstem(3,"ves")); }
<noun,any>palazzo"+"s  { return(gstem(4,"zi")); }
<noun,any>dais"+"s  { return(gstem(2,"es")); }
<noun,any>regulo"+"s  { return(gstem(4,"li")); }
<noun,any>steppe"+"s  { return(gstem(3,"es")); }
<noun,any>obsequy"+"s  { return(gstem(3,"ies")); }
<verb,noun,any>bus"+"s  { return(gstem(2,"ses")); }
<verb,any>bus"+"e[dn]  { return(gstem(3,"sed")); }
<verb,any>bus"+"ing  { return(gstem(4,"sing")); }
<verb,noun,any>hocus-pocus"+"s  { return(gstem(2,"ses")); }
<verb,noun,any>hocus"+"s  { return(gstem(2,"ses")); }
<noun,any>corpse"+"s  { return(gstem(2,"s")); }

<verb,any>ache"+"{EDING}  { return(gsemi_reg_stem(1,"")); }
<verb,any>accustom"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>blossom"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>boycott"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>catalog"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>{PRE}*create"+"{EDING}  { return(gsemi_reg_stem(1,"")); }
<verb,any>finesse"+"{ESEDING}  { return(gsemi_reg_stem(1,"")); }
<verb,any>interfere"+"{EDING}  { return(gsemi_reg_stem(1,"")); }
<verb,any>{PRE}*route"+"{EDING}  { return(gsemi_reg_stem(1,"")); }
<verb,any>taste"+"{ESEDING}  { return(gsemi_reg_stem(1,"")); }
<verb,any>waste"+"{ESEDING}  { return(gsemi_reg_stem(1,"")); }
<verb,any>acquit"+"{EDING}  { return(gsemi_reg_stem(0,"t")); }
<verb,any>ante"+"{ESEDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>arc"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
  /* disprefer <verb,any>arc"+"{EDING}  { return(gsemi_reg_stem(0,"k")); } */
<verb,any>banquet"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>barrel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>bedevil"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>beguile"+"{EDING}  { return(gsemi_reg_stem(1,"")); }
<verb,any>bejewel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>bevel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>bias"+"{ESEDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>biass"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>bivouac"+"{EDING}  { return(gsemi_reg_stem(0,"k")); }
<verb,any>buckram"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>bushel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>canal"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
  /* disprefer <verb,any>cancel"+"{EDING}  { return(gsemi_reg_stem(0,"")); } */
<verb,any>carol"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>cavil"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>cbel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
  /* disprefer <verb,any>cbel"+"{EDING}  { return(gsemi_reg_stem(0,"l")); } */
<verb,any>channel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>chisel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>clepe"+"{EDING}  { return(gsemi_reg_stem(1,"")); }
<verb,any>clothe"+"{ESEDING}  { return(gsemi_reg_stem(1,"")); }
<verb,any>coif"+"{ESEDING}  { return(gsemi_reg_stem(0,"f")); }
<verb,any>concertina"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>conga"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>coquet"+"{EDING}  { return(gsemi_reg_stem(0,"t")); }
  /* disprefer <verb,any>counsel"+"{EDING}  { return(gsemi_reg_stem(0,"")); } */
<verb,any>croquet"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>cudgel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>cupel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>debus"+"{ESEDING}  { return(gsemi_reg_stem(0,"s")); }
<verb,any>degas"+"{ESEDING}  { return(gsemi_reg_stem(0,"s")); }
<verb,any>devil"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>dial"+"{EDING}  { return(gsemi_reg_stem(0,"l")); }
<verb,any>disembowel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>dishevel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>drivel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>duel"+"{EDING}  { return(gsemi_reg_stem(0,"l")); }
<verb,any>embus"+"{ESEDING}  { return(gsemi_reg_stem(0,"s")); }
<verb,any>empanel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>enamel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>equal"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
  /* disprefer <verb,any>equal"+"{EDING}  { return(gsemi_reg_stem(0,"l")); } */
<verb,any>equip"+"{EDING}  { return(gsemi_reg_stem(0,"p")); }
<verb,any>flannel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>frivol"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>frolic"+"{EDING}  { return(gsemi_reg_stem(0,"k")); }
<verb,any>fuel"+"{EDING}  { return(gsemi_reg_stem(0,"l")); }
<verb,any>funnel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>gambol"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>gas"+"{ESEDING}  { return(gsemi_reg_stem(0,"s")); }
<verb,any>gel"+"{EDING}  { return(gsemi_reg_stem(0,"l")); }
<verb,any>glace"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>gravel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>grovel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>gyp"+"{EDING}  { return(gsemi_reg_stem(0,"p")); }
<verb,any>hansel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>hatchel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>hocus-pocus"+"{EDING}  { return(gsemi_reg_stem(0,"s")); }
<verb,any>hocus"+"{EDING}  { return(gsemi_reg_stem(0,"s")); }
<verb,any>housel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>hovel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>impanel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>initial"+"{EDING}  { return(gsemi_reg_stem(0,"l")); }
<verb,any>jewel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>kennel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>kernel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>label"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>laurel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>level"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>libel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>marshal"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>marvel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>medal"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>metal"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>mimic"+"{EDING}  { return(gsemi_reg_stem(0,"k")); }
<verb,any>misspell"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
  /* disprefer <verb,any>model"+"{EDING}  { return(gsemi_reg_stem(0,"")); } */
<verb,any>nickel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>nonplus"+"{ESEDING}  { return(gsemi_reg_stem(0,"s")); }
<verb,any>outgas"+"{ESEDING}  { return(gsemi_reg_stem(0,"s")); }
<verb,any>outgeneral"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>overspill"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>pall"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>panel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>panic"+"{EDING}  { return(gsemi_reg_stem(0,"k")); }
<verb,any>parallel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>parcel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>pedal"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>pencil"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>physic"+"{EDING}  { return(gsemi_reg_stem(0,"k")); }
<verb,any>picnic"+"{EDING}  { return(gsemi_reg_stem(0,"k")); }
<verb,any>pistol"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>polka"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>pommel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
  /* disprefer <verb,any>precancel"+"{EDING}  { return(gsemi_reg_stem(0,"")); } */
<verb,any>prologue"+"{EDING}  { return(gsemi_reg_stem(2,"")); }
<verb,any>pummel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>quarrel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>quip"+"{EDING}  { return(gsemi_reg_stem(0,"p")); }
<verb,any>quit"+"{EDING}  { return(gsemi_reg_stem(0,"t")); }
<verb,any>ravel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>recce"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>refuel"+"{EDING}  { return(gsemi_reg_stem(0,"l")); }
<verb,any>revel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>rival"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>roquet"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>rowel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>samba"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>saute"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>shellac"+"{EDING}  { return(gsemi_reg_stem(0,"k")); }
<verb,any>shovel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>shrivel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>sic"+"{EDING}  { return(gsemi_reg_stem(0,"k")); }
  /* disprefer <verb,any>signal"+"{EDING}  { return(gsemi_reg_stem(0,"")); } */
<verb,any>ski"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>snafu"+"{ESEDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>snivel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>sol-fa"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>spancel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>spiral"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>squat"+"{EDING}  { return(gsemi_reg_stem(0,"t")); }
<verb,any>squib"+"{EDING}  { return(gsemi_reg_stem(0,"b")); }
<verb,any>squid"+"{EDING}  { return(gsemi_reg_stem(0,"d")); }
<verb,any>stencil"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>subpoena"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
  /* disprefer <verb,any>subtotal"+"{EDING}  { return(gsemi_reg_stem(0,"")); } */
<verb,any>swivel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>symbol"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
  /* disprefer <verb,any>symbol"+"{EDING}  { return(gsemi_reg_stem(0,"l")); } */
<verb,any>talc"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
  /* disprefer <verb,any>talc"+"{EDING}  { return(gsemi_reg_stem(0,"k")); } */
<verb,any>tassel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>taxi"+"{ESEDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>tinsel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
  /* disprefer <verb,any>total"+"{EDING}  { return(gsemi_reg_stem(0,"")); } */
<verb,any>towel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>traffic"+"{EDING}  { return(gsemi_reg_stem(0,"k")); }
<verb,any>tramel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
  /* disprefer <verb,any>tramel"+"{EDING}  { return(gsemi_reg_stem(0,"l")); } */
  /* disprefer <verb,any>travel"+"{EDING}  { return(gsemi_reg_stem(0,"")); } */
<verb,any>trowel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>tunnel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>unclothe"+"{ESEDING}  { return(gsemi_reg_stem(1,"")); }
<verb,any>unkennel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>unravel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>upswell"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>victual"+"{EDING}  { return(gsemi_reg_stem(0,"l")); }
<verb,any>vitriol"+"{EDING}  { return(gsemi_reg_stem(0,"l")); }
<verb,any>viva"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>yodel"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<verb,any>(di|ti|li|unti|beli|hogti|stymi)e"+"s  { return(gstem(3,"es")); }
<verb,any>(di|ti|li|unti|beli|hogti|stymi)e"+"e[dn]  { return(gstem(4,"ed")); }
<verb,any>(d|t|l|unt|bel|hogt|stym)ie"+"ing  { return(gstem(6,"ying")); }
  /* cnull <verb,any>bias  { return(cnull_stem()); } */
  /* cnull <verb,any>canvas  { return(cnull_stem()); } */
<verb,any>canvas"+"{ESEDING}  { return(gsemi_reg_stem(0,"")); }
  /* disprefer <verb,any>embed  { return(cnull_stem()); } */
<verb,any>focus"+"{ESEDING}  { return(gsemi_reg_stem(0,"s")); }
  /* cnull <verb,any>gas  { return(cnull_stem()); } */
<verb,any>picknic"+"{EDING}  { return(gsemi_reg_stem(0,"k")); }
<verb,any>(adher|ador|attun|bast|bor|can|centr|cit|compet|cop|complet|concret|condon|contraven|conven|cran|delet|delineat|dop|drap|dron|escap|excit|fort|gap|gazett|grop|hon|hop|ignit|ignor|incit|interven|inton|invit|landscap|manoeuvr|nauseat|normalis|outmanoeuvr|overaw|permeat|persever|pip|por|postpon|prun|rap|recit|reshap|rop|shap|shor|snor|snip|ston|tap|wip)e"+"{ESEDING}  { return(gsemi_reg_stem(1,"")); }
<verb,any>(ape|augur|belong|berth|burr|conquer|egg|forestall|froth|install|lacquer|martyr|mouth|murmur|pivot|preceed|prolong|purr|quell|recall|refill|remill|resell|retell|smooth|throng|twang|unearth)"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
<noun,any>(({A}*metr)|({A}*litr)|({A}+ett)|acr|Aussi|budgi|catastroph|centr|clich|commi|cooli|curi|demesn|employe|evacue|fibr|headach|hord|magpi|manoeuvr|moggi|moustach|movi|nighti|programm|queu|sabr|sorti|tast|theatr|timbr|titr|wiseacr)e"+"s  { return(gstem(2,"s")); }
<noun,any>burnurn"+"s  { return(gstem(2,"s")); }
<noun,any>carriageway"+"s  { return(gstem(2,"s")); }
<noun,any>cill"+"s  { return(gstem(2,"s")); }
<noun,any>(umbrell|utopi)a"+"s  { return(gstem(2,"s")); }
  /* cnull <noun,any>(({A}+itis)|abdomen|acacia|achimenes|alibi|alkali|ammonia|amnesia|anaesthesia|anesthesia|aria|arris|asphyxia|aspidistra|aubrietia|axis|begonia|bias|bikini|cannula|canvas|chili|chinchilla|Christmas|cornucopia|cupola|cyclamen|diabetes|diphtheria|dysphagia|encyclopaedia|ennui|escallonia|ferris|flotilla|forsythia|ganglia|gas|gondola|grata|guerrilla|haemophilia|hysteria|inertia|insignia|iris|khaki|koala|lens|macaroni|manilla|mania|mantis|martini|matins|memorabilia|metropolis|moa|morphia|nostalgia|omen|pantometria|parabola|paraphernalia|pastis|patella|patens|pelvis|peninsula|phantasmagoria|pneumonia|polyuria|portcullis|pyrexia|regalia|safari|salami|sari|saturnalia|spaghetti|specimen|subtopia|suburbia|syphilis|taxi|toccata|trellis|tutti|umbrella|utopia|villa|zucchini)  { return(cnull_stem()); } */
<noun,any>(acumen|Afrikaans|aphis|brethren|caries|confetti|contretemps|dais|debris|extremis|gallows|hors|hovis|hustings|innards|isosceles|maquis|minutiae|molasses|mortis|patois|pectoris|plumbites|series|tares|tennis|turps){SAFFS}  { return(gnull_stem()); }
<noun,any>(accoutrements|aerodynamics|aeronautics|aesthetics|algae|amends|annals|arrears|assizes|auspices|backwoods|bacteria|banns|battlements|bedclothes|belongings|billiards|binoculars|bitters|blandishments|bleachers|blinkers|blues|breeches|brussels|clothes|clutches|commons|confines|contents|credentials|crossbones|damages|dealings|dentures|depths|devotions|diggings|doings|downs|dues|dynamics|earnings|eatables|eaves|economics|electrodynamics|electronics|entrails|environs|equities|ethics|eugenics|filings|finances|folks|footlights|fumes|furnishings|genitals|glitterati|goggles|goods|grits|groceries|grounds|handcuffs|headquarters|histrionics|hostilities|humanities|hydraulics|hysterics|illuminations|italics|jeans|jitters|kinetics|knickers|latitudes|leggings|likes|linguistics|lodgings|loggerheads|mains|manners|mathematics|means|measles|media|memoirs|metaphysics|mockers|motions|multimedia|munitions|news|nutria|nylons|oats|odds|oils|oilskins|optics|orthodontics|outskirts|overalls|pants|pantaloons|papers|paras|paratroops|particulars|pediatrics|phonemics|phonetics|physics|pincers|plastics|politics|proceeds|proceedings|prospects|pyjamas|rations|ravages|refreshments|regards|reinforcements|remains|respects|returns|riches|rights|savings|scissors|seconds|semantics|shades|shallows|shambles|shorts|singles|slacks|specifics|spectacles|spoils|statics|statistics|summons|supplies|surroundings|suspenders|takings|teens|telecommunications|tenterhooks|thanks|theatricals|thermodynamics|tights|toils|trappings|travels|troops|tropics|trousers|tweeds|underpants|vapours|vicissitudes|vitals|wages|wanderings|wares|whereabouts|whites|winnings|withers|woollens|workings|writings|yes){SAFFS}  { return(gnull_stem()); }
<noun,any>(boati|bonhomi|clippi|creepi|deari|droppi|gendarmeri|girli|goali|haddi|kooki|kyri|lambi|lassi|mari|menageri|petti|reveri|snotti|sweeti)e"+"s  { return(gstem(2,"s")); }
<verb,any>(buffet|plummet)"+"{EDING}  { return(gsemi_reg_stem(0,"t")); }
  /* cnull <verb,any>gunsling  { return(cnull_stem()); } */
  /* cnull <verb,any>hamstring  { return(cnull_stem()); } */
  /* cnull <verb,any>shred  { return(cnull_stem()); } */
<verb,any>unfocus"+"{ESEDING}  { return(gsemi_reg_stem(0,"s")); }
<verb,any>(accret|clon|deplet|dethron|dup|excret|expedit|extradit|fet|finetun|gor|hing|massacr|obsolet|reconven|recreat|recus|reignit|swip|videotap|zon)e"+"{ESEDING}  { return(gsemi_reg_stem(1,"")); }
  /* disprefer <verb,any>(backpedal|bankroll|bequeath|blackball|bottom|clang|debut|doctor|eyeball|factor|imperil|landfill|margin|multihull|occur|overbill|pilot|prong|pyramid|reinstall|relabel|remodel|snowball|socall|squirrel|stonewall|wrong)"+"{EDING}  { return(gsemi_reg_stem(0,"")); } */
<noun,any>(beasti|browni|cach|cadr|calori|champagn|cologn|cooki|druggi|eateri|emigr|emigre|employe|freebi|genr|kiddi|massacr|mooni|neckti|nich|prairi|softi|toothpast|willi)e"+"s  { return(gstem(2,"s")); }
  /* cnull <noun,any>(({A}*phobia)|accompli|aegis|alias|anorexia|anti|artemisia|ataxia|beatlemania|blini|cafeteria|capita|cola|coli|deli|dementia|downstairs|upstairs|dyslexia|jakes|dystopia|encyclopedia|estancia|euphoria|euthanasia|fracas|fuss|gala|gorilla|GI|habeas|haemophilia|hemophilia|hoopla|hula|impatiens|informatics|intelligentsia|jacuzzi|kiwi|mafia|magnolia|malaria|maquila|marginalia|megalomania|mercedes|militia|mufti|muni|olympics|pancreas|paranoia|pastoris|pastrami|pepperoni|pepsi|pi|piroghi|pizzeria|pneumocystis|potpourri|proboscis|rabies|reggae|regimen|rigatoni|salmonella|sarsaparilla|semen|ski|sonata|spatula|stats|subtilis|sushi|tachyarrhythmia|tachycardia|tequila|tetris|thrips|timpani|tsunami|vaccinia|vanilla)  { return(cnull_stem()); } */
<noun,any>(acrobatics|athletics|basics|betters|bifocals|bowels|briefs|checkers|cognoscenti|denims|doldrums|dramatics|dungarees|ergonomics|genetics|gravitas|gymnastics|hackles|haves|hubris|ides|incidentals|ironworks|jinks|leavings|leftovers|logistics|makings|microelectronics|miniseries|mips|mores|oodles|pajamas|pampas|panties|payola|pickings|plainclothes|pliers|ravings|reparations|rudiments|scads|splits|stays|subtitles|sunglasss|sweepstakes|tatters|toiletries|tongs|trivia|tweezers|vibes|waterworks|woolens){SAFFS}  { return(gnull_stem()); }
<noun,any>(biggi|bourgeoisi|bri|camaraderi|chinoiseri|coteri|doggi|geni|hippi|junki|lingeri|moxi|preppi|rooki|yuppi)e"+"s  { return(gstem(2,"s")); }
<verb,any>(chor|sepulchr|silhouett|telescop)e"+"{ESEDING}  { return(gsemi_reg_stem(1,"")); }
<verb,any>(subpena|suds)"+"{EDING}  { return(gsemi_reg_stem(0,"")); }
  /* cnull <noun,any>(({A}+philia)|fantasia|Feis|Gras|Mardi)  { return(cnull_stem()); } */
<noun,any>(calisthenics|heroics|rheumatics|victuals|wiles){SAFFS}  { return(gnull_stem()); }
<noun,any>(aunti|anomi|coosi|quicki)e"+"s  { return(gstem(2,"s")); }
  /* cnull <noun,any>(absentia|bourgeois|pecunia|Syntaxis|uncia)  { return(cnull_stem()); } */
<noun,any>(apologetics|goings|outdoors){SAFFS}  { return(gnull_stem()); }
<noun,any>collie"+"s  { return(gstem(2,"s")); }
  /* cnull <verb,any>imbed  { return(cnull_stem()); } */
  /* cnull <verb,any>precis  { return(cnull_stem()); } */
<verb,any>precis"+"{ESEDING}  { return(gsemi_reg_stem(0,"")); }
  /* cnull <noun,any>(assagai|borzoi|calla|camellia|campanula|cantata|caravanserai|cedilla|cognomen|copula|corolla|cyclopaedia|dahlia|dhoti|dolmen|effendi|fibula|fistula|freesia|fuchsia|guerilla|hadji|hernia|houri|hymen|hyperbola|hypochondria|inamorata|kepi|kukri|mantilla|monomania|nebula|ovata|pergola|petunia|pharmacopoeia|phi|poinsettia|primula|rabbi|scapula|sequoia|sundae|tarantella|tarantula|tibia|tombola|topi|tortilla|uvula|viola|wisteria|zinnia)  { return(cnull_stem()); } */
  /* disprefer <noun,any>(tibi|nebul|uvul)a"+"s  { return(gstem(2,"e")); } */
<noun,any>(arras|clitoris|muggins)"+"s  { return(gstem(2,"es")); }
<noun,any>(alms|biceps|calends|elevenses|eurhythmics|faeces|forceps|jimjams|jodhpurs|menses|secateurs|shears|smithereens|spermaceti|suds|trews|triceps|underclothes|undies|vermicelli){SAFFS}  { return(gnull_stem()); }
  /* cnull <noun,any>(albumen|alopecia|ambergris|amblyopia|ambrosia|analgesia|aphasia|arras|asbestos|asia|assegai|astrophysics|aubrietia|aula|avoirdupois|beriberi|bitumen|broccoli|cadi|callisthenics|collywobbles|curia|cybernetics|cyclops|cyclopedia|dickens|dietetics|dipsomania|dyspepsia|epidermis|epiglottis|erysipelas|fascia|finis|fives|fleur-de-lis|geophysics|geriatrics|glottis|haggis|hara-kiri|herpes|hoop-la|ibis|insomnia|kleptomania|kohlrabi|kris|kumis|litchi|litotes|loggia|magnesia|man-at-arms|manila|marquis|master-at-arms|mattins|melancholia|minutia|muggins|mumps|mi|myopia|necropolis|neuralgia|nibs|numismatics|nymphomania|obstetrics|okapi|onomatopoeia|ophthalmia|paraplegia|patchouli|paterfamilias|penis|piccalilli|praxis|precis|prophylaxis|pyrites|raffia|revers|rickets|rounders|rubella|saki|salvia|sassafras|sawbones|scabies|schnapps|scintilla|scrofula|sepia|stamen|si|swami|testis|therapeutics|tiddlywinks|verdigris|wadi|wapiti|yogi)  { return(cnull_stem()); } */
<noun,any>(aeri|birdi|bogi|caddi|cock-a-leeki|colli|corri|cowri|dixi|eyri|faeri|gaucheri|gilli|knobkerri|laddi|mashi|meali|menageri|organdi|patisseri|pinki|pixi|stymi|talki)e"+"s  { return(gstem(2,"s")); }
<noun,any>human"+"s  { return(gstem(2,"s")); }
<noun,any>slum"+"s  { return(gstem(2,"s")); }
<verb,any>(({A}*-us)|abus|accus|amus|arous|bemus|carous|contus|disabus|disus|dous|enthus|excus|grous|misus|mus|overus|perus|reus|rous|sous|us|({A}*[hlmp]ous)|({A}*[af]us))e"+"{ESEDING}  { return(gsemi_reg_stem(1,"")); }
<noun,any>(({A}*-abus)|({A}*-us)|abus|burnous|cayus|chanteus|chartreus|chauffeus|crus|disus|excus|grous|hypotenus|masseus|misus|mus|Ous|overus|poseus|reclus|reus|rus|us|({A}*[hlmp]ous)|({A}*[af]us))e"+"s  { return(gstem(2,"s")); }
<noun,any>(ablutions|adenoids|aerobatics|afters|astronautics|atmospherics|bagpipes|ballistics|bell-bottoms|belles-lettres|blinders|bloomers|butterfingers|buttocks|bygones|cahoots|castanets|clappers|dodgems|dregs|duckboards|edibles|eurythmics|externals|extortions|falsies|fisticuffs|fleshings|fleur-de-lys|fours|gentleman-at-arms|geopolitics|giblets|gleanings|handlebars|heartstrings|homiletics|housetops|hunkers|hydroponics|kalends|knickerbockers|lees|lei|lieder|literati|loins|meanderings|meths|muniments|necessaries|nines|ninepins|nippers|nuptials|orthopaedics|paediatrics|phonics|polemics|pontificals|prelims|pyrotechnics|ravioli|rompers|ructions|scampi|scrapings|serjeant-at-arms|shires|smalls|steelworks|sweepings|vespers|virginals|waxworks){SAFFS}  { return(gnull_stem()); }
  /* cnull <noun,any>(cannabis|corgi|envoi|hi-fi|kwela|lexis|muesli|sheila|ti|yeti)  { return(cnull_stem()); } */

<noun,any>(mounti|brasseri|granni|koppi|rotisseri)e"+"s  { return(gstem(2,"s")); }

<noun,any>cantharide"+"s  { return(gstem(4,"s")); }
<noun,any>chamoix"+"s  { return(gstem(3,"s")); }
<noun,any>submatrix"+"s  { return(gstem(3,"ces")); }
<noun,any>mafioso"+"s  { return(gstem(3,"i")); }
<noun,any>pleuron"+"s  { return(gstem(4,"a")); }
<noun,any>vas"+"s  { return(gstem(2,"a")); }
<noun,any>antipasto"+"s  { return(gstem(3,"i")); }


<verb,any>(bastinado|bunco|bunko|carbonado|contango|crescendo|ditto|echo|embargo|fresco|hallo|halo|lasso|niello|radio|solo|stiletto|stucco|tally-ho|tango|torpedo|veto|zero)"+"e[dn]  { return(gstem(3,"ed")); }
<verb,any>ko"+"e[dn]  { return(gstem(4,"o'd")); }
<verb,any>ko"+"ing  { return(gstem(4,"'ing")); }
<verb,any>ko"+"s  { return(gstem(2,"'s")); }
  /* disprefer <verb,any>tally-h"+"e[dn]  { return(gstem(3,"o'd")); } */
<noun,any>(co|do|ko|no)"+"s  { return(gstem(2,"'s")); }

<noun,any>(aloe|archfoe|canoe|doe|felloe|floe|foe|hammertoe|hoe|icefloe|mistletoe|oboe|roe|({A}*shoe)|sloe|throe|tiptoe|toe|voe|woe)"+"s  { return(gstem(2,"s")); }
<verb,any>(canoe|hoe|outwoe|rehoe|({A}*shoe)|tiptoe|toe)"+"s  { return(gstem(2,"s")); }

<noun,any>(tornedos|throes){SAFFS}  { return(gnull_stem()); }


<noun,any>(antihero|buffalo|dingo|domino|echo|go|grotto|hero|innuendo|mango|mato|mosquito|mulatto|potato|peccadillo|pentomino|superhero|tomato|tornado|torpedo|veto|volcano)"+"s  { return(gstem(2,"es")); }
<verb,any>(echo|forego|forgo|go|outdo|overdo|redo|torpedo|undergo|undo|veto)"+"s  { return(gstem(2,"es")); }

  
<noun,any>(bathos|cross-purposes|kudos){SAFFS}  { return(gnull_stem()); }
  /* cnull <noun,any>cos  { return(cnull_stem()); } */

  /* cnull <noun,any>(chaos|cosmos|ethos|parados|pathos|rhinoceros|tripos|thermos|OS|reredos)  { return(cnull_stem()); } */
<noun,any>(chaos|cosmos|ethos|parados|pathos|rhinoceros|tripos|thermos|OS|reredos)"+"s  { return(gstem(2,"es")); }

<noun,any>(anastomos|apotheos|arterioscleros|asbestos|cellulos|dermatos|diagnos|diverticulos|exostos|hemicellulos|histocytos|hypnos|meios|metamorphos|metempsychos|mitos|neuros|prognos|psychos|salmonellos|symbios|scleros|stenos|symbios|synchondros|treponematos|zoonos)is"+"s  { return(gstem(4,"es")); }

  /* disprefer <noun,any>pharisee"+"s  { return(gstem(6,"oses")); } */


<noun,any>(adze|bronze)"+"s  { return(gstem(2,"s")); }
<noun,any>(fez|quiz)"+"s  { return(gstem(2,"zes")); }
  /* disprefer <noun,any>(fez|quiz)"+"s  { return(gstem(2,"es")); } */
<verb,any>(adz|bronz)e"+"{ESEDING}  { return(gsemi_reg_stem(1,"")); }
<verb,any>(quiz|whiz)"+"{ESEDING}  { return(gsemi_reg_stem(0,"z")); }
  /* disprefer <verb,any>(quiz|whiz)"+"{ESEDING}  { return(gsemi_reg_stem(0,"")); } */

<verb,noun,any>{A}+us"+"s  { return(gstem(2,"es")); }
<verb,any>{A}+us"+"e[dn]  { return(gstem(3,"ed")); }
<verb,any>{A}+us"+"ing  { return(gstem(4,"ing")); }

<noun,any>p".+"s  { return(gstem(3,"p.")); }
<noun,any>m"."p".+"s  { return(gstem(6,"m.p.s.")); }
  /* cnull <noun,any>(cons|miss|mrs|ms|n-s|pres|ss)"."  { return(cnull_stem()); } */
  /* cnull <noun,any>({A}|".")+"."s"."  { return(cnull_stem()); } */
  /* disprefer <noun,any>({A}|".")+".+"s  { return(gstem(3,".'s.")); } */
<noun,any>({A}|".")+".+"s  { return(gstem(3,"s.")); }

<noun,any>{A}*man"+"s  { return(gstem(4,"en")); }
<noun,any>{A}*wife"+"s  { return(gstem(4,"ves")); }
<noun,any>{A}+zoon"+"s  { return(gstem(4,"a")); }
  /* disprefer <noun,any>{A}+ium"+"s  { return(gstem(4,"ia")); } */
  /* cnull <noun,any>{A}+e[mn]ia  { return(cnull_stem()); } */
  /* disprefer <noun,any>{A}+ium"+"s  { return(gstem(4,"a")); } */
<noun,any>{A}+lum"+"s  { return(gstem(4,"a")); }
  /* disprefer <noun,any>{A}+us"+"s  { return(gstem(4,"i")); } */
  /* disprefer <noun,any>{A}+a"+"s  { return(gstem(3,"ae")); } */
  /* disprefer <noun,any>{A}+a"+"s  { return(gstem(3,"ata")); } */

  /* cnull <verb,noun,any>(his|hers|theirs|ours|yours|as|its|this|during|something|nothing|anything|everything)  { return(cnull_stem()); } */
  /* cnull <verb,noun,any>{A}*(us|ss|sis|eed)  { return(cnull_stem()); } */
<verb,noun,any>{A}*{V}se"+"s  { return(gstem(2,"s")); }
<verb,noun,any>{A}+{CXY}z"+"s  { return(gstem(2,"es")); }
<verb,noun,any>{A}*{VY}ze"+"s  { return(gstem(2,"s")); }
<verb,noun,any>{A}+{S2}"+"s  { return(gstem(2,"es")); }
<verb,noun,any>{A}+{V}rse"+"s  { return(gstem(2,"s")); }
<verb,noun,any>{A}+onse"+"s  { return(gstem(2,"s")); }
<verb,noun,any>{A}+{S}"+"s  { return(gstem(2,"es")); }
<verb,noun,any>{A}+the"+"s  { return(gstem(2,"s")); }
<verb,noun,any>{A}+{CXY}[cglsv]e"+"s  { return(gstem(2,"s")); }
<verb,noun,any>{A}+ette"+"s  { return(gstem(2,"s")); }
<verb,noun,any>{A}+{C}y"+"s  { return(gstem(3,"ies")); }
  /* disprefer <verb,noun,any>{A}*{CXY}o"+"s  { return(gstem(2,"es")); } */
<verb,noun,any>{A}+"+"s  { return(gstem(2,"s")); }

<verb,any>{A}+{CXY}z"+"e[dn]  { return(gstem(3,"ed")); }
<verb,any>{A}*{VY}ze"+"e[dn]  { return(gstem(3,"d")); }
<verb,any>{A}+{S2}"+"e[dn]  { return(gstem(3,"ed")); }
<verb,any>{A}+{CXY}z"+"ing  { return(gstem(4,"ing")); }
<verb,any>{A}*{VY}ze"+"ing  { return(gstem(5,"ing")); }
<verb,any>{A}+{S2}"+"ing  { return(gstem(4,"ing")); }
<verb,any>{C}+{V}ll"+"e[dn]  { return(gstem(3,"ed")); }
<verb,any>{C}+{V}ll"+"ing  { return(gstem(4,"ing")); }
<verb,any>{A}*{C}{V}{CXY}"+"e[dn]  { return(gcondub_stem(3,"ed")); }
<verb,any>{A}*{C}{V}{CXY}"+"ing  { return(gcondub_stem(4,"ing")); }

  /* cnull <verb,any>{CXY}+ed  { return(cnull_stem()); } */
<verb,any>{PRE}*{C}{V}ng"+"e[dn]  { return(gstem(3,"ed")); }
<verb,any>{A}+ick"+"e[dn]  { return(gstem(3,"ed")); }
<verb,any>{A}*{C}ine"+"e[dn]  { return(gstem(4,"ed")); }
  /* disprefer <verb,any>{A}*{C}{V}[npwx]"+"e[dn]  { return(gstem(3,"ed")); } */
<verb,any>{PRE}*{C}+ore"+"e[dn]  { return(gstem(4,"ed")); }
  /* disprefer <verb,any>{A}+ctor"+"e[dn]  { return(gstem(3,"ed")); } */
<verb,any>{A}*{C}[clnt]ore"+"e[dn]  { return(gstem(4,"ed")); }
<verb,any>{A}+[eo]r"+"e[dn]  { return(gstem(3,"ed")); }
<verb,any>{A}+{C}y"+"e[dn]  { return(gstem(4,"ied")); }
<verb,any>{A}*qu{V}{C}e"+"e[dn]  { return(gstem(4,"ed")); }
<verb,any>{A}+u{V}de"+"e[dn]  { return(gstem(4,"ed")); }
<verb,any>{A}*{C}lete"+"e[dn]  { return(gstem(4,"ed")); }
<verb,any>{PRE}*{C}+[ei]te"+"e[dn]  { return(gstem(4,"ed")); }
<verb,any>{A}+[ei]t"+"e[dn]  { return(gstem(3,"ed")); }
<verb,any>{PRE}({CXY}{2})eat"+"e[dn]  { return(gstem(3,"ed")); }
<verb,any>{A}*{V}({CXY}{2})eate"+"e[dn]  { return(gstem(4,"ed")); }
<verb,any>{A}+[eo]at"+"e[dn]  { return(gstem(3,"ed")); }
<verb,any>{A}+{V}ate"+"e[dn]  { return(gstem(4,"ed")); }
<verb,any>{A}*({V}{2})[cgsv]e"+"e[dn]  { return(gstem(4,"ed")); }
<verb,any>{A}*({V}{2}){C}"+"e[dn]  { return(gstem(3,"ed")); }
<verb,any>{A}+[rw]l"+"e[dn]  { return(gstem(3,"ed")); }
<verb,any>{A}+the"+"e[dn]  { return(gstem(4,"ed")); }
<verb,any>{A}+ue"+"e[dn]  { return(gstem(4,"ed")); }
<verb,any>{A}+{CXY}[cglsv]e"+"e[dn]  { return(gstem(4,"ed")); }
<verb,any>{A}+({CXY}{2})"+"e[dn]  { return(gstem(3,"ed")); }
<verb,any>{A}+({VY}{2})"+"e[dn]  { return(gstem(3,"ed")); }
<verb,any>{A}+e"+"e[dn]  { return(gstem(4,"ed")); }

  /* cnull <verb,any>{CXY}+ing  { return(cnull_stem()); } */
<verb,any>{PRE}*{C}{V}ng"+"ing  { return(gstem(4,"ing")); }
<verb,any>{A}+ick"+"ing  { return(gstem(4,"ing")); }
<verb,any>{A}*{C}ine"+"ing  { return(gstem(5,"ing")); }
  /* disprefer <verb,any>{A}*{C}{V}[npwx]"+"ing  { return(gstem(4,"ing")); } */
<verb,any>{A}*qu{V}{C}e"+"ing  { return(gstem(5,"ing")); }
<verb,any>{A}+u{V}de"+"ing  { return(gstem(5,"ing")); }
<verb,any>{A}*{C}lete"+"ing  { return(gstem(5,"ing")); }
<verb,any>{PRE}*{C}+[ei]te"+"ing  { return(gstem(5,"ing")); }
<verb,any>{A}+[ei]t"+"ing  { return(gstem(4,"ing")); }
<verb,any>{A}*{PRE}({CXY}{2})eat"+"ing  { return(gstem(4,"ing")); }
<verb,any>{A}*{V}({CXY}{2})eate"+"ing  { return(gstem(5,"ing")); }
<verb,any>{A}+[eo]at"+"ing  { return(gstem(4,"ing")); }
<verb,any>{A}+{V}ate"+"ing  { return(gstem(5,"ing")); }
<verb,any>{A}*({V}{2})[cgsv]e"+"ing  { return(gstem(5,"ing")); }
<verb,any>{A}*({V}{2}){C}"+"ing  { return(gstem(4,"ing")); }
<verb,any>{A}+[rw]l"+"ing  { return(gstem(4,"ing")); }
<verb,any>{A}+the"+"ing  { return(gstem(5,"ing")); }
<verb,any>{A}+{CXY}[cglsv]e"+"ing  { return(gstem(5,"ing")); }
<verb,any>{A}+({CXY}{2})"+"ing  { return(gstem(4,"ing")); }
<verb,any>{A}+ue"+"ing  { return(gstem(5,"ing")); }
<verb,any>{A}+({VY}{2})"+"ing  { return(gstem(4,"ing")); }
<verb,any>{A}+y"+"ing  { return(gstem(4,"ing")); }
<verb,any>{A}*{CXY}o"+"ing  { return(gstem(4,"ing")); }
<verb,any>{PRE}*{C}+ore"+"ing  { return(gstem(5,"ing")); }
  /* disprefer <verb,any>{A}+ctor"+"ing  { return(gstem(4,"ing")); } */
<verb,any>{A}*{C}[clt]ore"+"ing  { return(gstem(5,"ing")); }
<verb,any>{A}+[eo]r"+"ing  { return(gstem(4,"ing")); }
<verb,any>{A}+e"+"ing  { return(gstem(5,"ing")); }

<verb,noun,any>{G-}+"-"   { common_noun_stem(); return(yylex()); }
<verb,noun,any>{G-}+      { return(common_noun_stem()); }
<verb,noun,any>{SKIP}     { return(common_noun_stem()); }

<scan>be"+"ed/_VBDR  { return(gstem(5,"were")); }
<scan>be"+"ed/_VBDZ  { return(gstem(5,"was")); }
<scan>be"+"/_VBM  { return(gstem(3,"am")); }
<scan>be"+"/_VBR  { return(gstem(3,"are")); }
<scan>be"+"s/_VBZ  { return(gstem(4,"is")); }
  /* disprefer <scan>have"+"ed/_VH  { return(gstem(7,"'d")); } */
<scan>would"+"/_VM  { return(gstem(6,"'d")); }
  /* disprefer <scan>be"+"s/_VBZ  { return(gstem(4,"'s")); } */
  /* disprefer <scan>do"+"s/_VDZ  { return(gstem(4,"'s")); } */
  /* disprefer <scan>have"+"s/_VHZ  { return(gstem(6,"'s")); } */
<scan>'s"+"/_"$"  { return(gstem(3,"'s")); }
<scan>'s"+"/_POS  { return(gstem(3,"'s")); }
<scan>as"+"/_CSA  { return(gstem(3,"'s")); }
<scan>as"+"/_CJS  { return(gstem(3,"'s")); }
<scan>not"+"/_XX  { return(gstem(4,"not")); }
  /* disprefer <scan>be"+"/_VB  { return(gstem(3,"ai")); } */
  /* disprefer <scan>have"+"/_VH  { return(gstem(5,"ai")); } */
<scan>can"+"/_VM  { return(gstem(4,"ca")); }
<scan>shall"+"/_VM  { return(gstem(6,"sha")); }
  /* disprefer <scan>will"+"/_VM  { return(gstem(5,"wo")); } */
  /* disprefer <scan>not"+"/_XX  { return(gstem(4,"n't")); } */
<scan>he"+"/_PPHO1  { return(gstem(3,"him")); }
<scan>she"+"/_PPHO1  { return(gstem(4,"her")); }
<scan>they"+"/_PPHO2  { return(gstem(5,"them")); }
<scan>I"+"/_PPIO1  { return(gstem(2,"me")); }
<scan>we"+"/_PPIO2  { return(gstem(3,"us")); }
<scan>"I"/_PPIS1    { return(proper_name_stem()); }
<scan>he"+"/_PNP  { return(gstem(3,"him")); }
<scan>she"+"/_PNP  { return(gstem(4,"her")); }
<scan>they"+"/_PNP  { return(gstem(5,"them")); }
<scan>I"+"/_PNP  { return(gstem(2,"me")); }
<scan>we"+"/_PNP  { return(gstem(3,"us")); }
<scan>"I"/_PNP      { return(proper_name_stem()); }
<scan>{G}+/_N[^P] { BEGIN(noun); yyless(0); return(yylex()); }
<scan>{G}+/_NP    { return(proper_name_stem()); }
<scan>{G}+/_V     { BEGIN(verb); yyless(0); return(yylex()); }
<scan>{G}+/_      { return(common_noun_stem()); }
<scan>_{G}+       { if Option(tag_output) ECHO; return(1); }
<scan>{SKIP}      { return(common_noun_stem()); }

%%

void downcase( char *text, int len )
{int i;
 for ( i = 0; i<len; i++ )
    {if ( isupper(text[i]) )
      text[i] = 'a' + (text[i] - 'A');
    }
}

char *upcase( char *vanilla_text )
{int   i;
 char *text;

 text = malloc((strlen((char *)vanilla_text)+1)*sizeof(char));
 strcpy((char *)text, (char *)vanilla_text);
 for (i = 0; vanilla_text[i] != '\0'; i++)
    {if ( islower(vanilla_text[i]) )
	{text[i] = 'A' + (vanilla_text[i] - 'a');
	}
    else
	{text[i] = vanilla_text[i];
	}
    }
 return text;
}

char up8(char c)
{ if ('a' <= c && c <= 'z' || '\xE0' <= c && 
      c <= '\xFE' && c != '\xF7')
    return c-('a'-'A');
  else return c;
}

int scmp(const char *a, const char *b)
{ int i = 0, d = 0;
  while ((d=(int)up8(a[i])-(int)up8(b[i])) == 0 && 
	 a[i] != 0) i++;
  return d;
}

int vcmp(const void *a, const void *b)
{ return scmp(*((const char **)a), *((const char **)b));
}

int verbstem_n = 0;
char **verbstem_list = NULL;
 
int in_verbstem_list(char *a)
{ return verbstem_n > 0 &&
         bsearch(&a, verbstem_list, verbstem_n, sizeof(char*), 
		 &vcmp) != NULL;
}

int gstem(int del, char *add)
{int stem_length = yyleng - del;
 
 if Option(change_case) { downcase(yytext, stem_length); }

 if (del > 0) { yytext[stem_length] = '\0'; }

 if (!Option(change_case) && yyleng > 1 && isupper(yytext[2]))
   { printf("%s%s", upcase(yytext), upcase(add)); }
 else printf("%s%s", yytext, add); 

 return(1);
}

int gcondub_stem(int del, char *add)
{int stem_length = yyleng - del;
 char d;
 
 if Option(change_case) { downcase(yytext, stem_length); }

 d = yytext[stem_length - 1];
 if (del > 0) { yytext[stem_length] = '\0'; }

 if (!Option(change_case) && yyleng > 1 && isupper(yytext[2]))
   {if (in_verbstem_list(yytext)) printf("%s%c%s", upcase(yytext), up8(d), upcase(add)); 
    else printf("%s%s", upcase(yytext), upcase(add));
   }
 else
   {if (in_verbstem_list(yytext)) printf("%s%c%s", yytext, d, add); 
    else printf("%s%s", yytext, add);
   }

 return(1);
}

int gsemi_reg_stem(int del, char *add)
{int stem_length;
 char *aff;

 if Option(change_case) { downcase(yytext, yyleng); }

 if (yytext[yyleng-1]=='s'|yytext[yyleng-1]=='S') 
   {stem_length = yyleng - del - 2; aff = "s";} 
 else if (yytext[yyleng-1]=='d'|yytext[yyleng-1]=='D')
   {stem_length = yyleng - del - 3 ; aff = "ed";} 
 else if (yytext[yyleng-1]=='n'|yytext[yyleng-1]=='N')
   {stem_length = yyleng - del - 3 ; aff = "ed";} 
 else if (yytext[yyleng-1]=='g'|yytext[yyleng-1]=='G') 
   {stem_length = yyleng - del - 4 ; aff = "ing";} 
 else stem_length = yyleng;

 yytext[stem_length] = '\0';

 if (!Option(change_case) && yyleng > 1 && isupper(yytext[2]))
   { printf("%s%s%s", upcase(yytext), upcase(add), upcase(aff)); }
 else printf("%s%s%s", yytext, add, aff); 

 return(1);
}

void capitalise( char *text, int len )
{int i;
 if ( islower(text[0]) ) text[0] = 'A' + (text[0] - 'a');
 for ( i = 1; i<len; i++ )
   {if ( isupper(text[i]) )
     text[i] = 'a' + (text[i] - 'A');
   }
}

int proper_name_stem()
{
  if Option(change_case) { capitalise(yytext, yyleng); }
  ECHO;
  return(1);
}

int common_noun_stem()
{
  if Option(change_case) { downcase(yytext, yyleng); }
  ECHO;
  return(1);
}

  /* inflected form is the same as the stem, so just ignore any affix */

int gnull_stem()
{BOOL bool = 0;
 int stem_length;
 char *aff;

 if Option(change_case) { downcase(yytext, yyleng); }

 if (yytext[yyleng-1]=='s'|yytext[yyleng-1]=='S') 
   stem_length = yyleng - 2; 
 else if (yytext[yyleng-1]=='d'|yytext[yyleng-1]=='D')
   stem_length = yyleng - 3; 
 else if (yytext[yyleng-1]=='n'|yytext[yyleng-1]=='N')
   stem_length = yyleng - 3; 
 else if (yytext[yyleng-1]=='g'|yytext[yyleng-1]=='G') 
   stem_length = yyleng - 4; 
 else stem_length = yyleng;

 yytext[stem_length] = '\0';
 printf("%s", yytext);

 return(1);
}

  /* inflected form is the same as the stem, so just ignore any affix */

int nnull_stem()
{int i;
  if Option(change_case) { downcase(yytext, yyleng); }

  for ( i = 0; (yytext[i] != '+') && (yytext[i] != '\n'); i++ )
   {printf("%c", yytext[i]);
   }
  return(1);
}

char get_option(int argc, char *argv[], char *options, int *arg, 
		int *i)
{int   aa = *arg;
 int   ii = *i;
 char *opt, letter;

 if (aa > (argc - 1)) {
     *arg = aa;    
     *i = 0;
     return 0;}
  if (argv[aa][ii] == 0)
   {*arg = aa + 1;
    ii  = 0;
    return 0;
   }
  if (aa > (argc - 1)) {
    *arg = aa;    
    *i = 0;
    return 0; 
  }
 do
   {if (aa == 1 && ii == 0 && argv[aa][ii] == '-') ii += 1; 
    letter = argv[aa][ii++];
	if ((opt = strchr(options, letter)) == NULL)
	  {fprintf(stderr, "Unknown option '%c' ignored\n", letter);
	  }
	else
            {   
              break;
            }
    } while(forever); 
 *arg = aa; 
 *i   = ii; 
 return letter;
}

int read_verbstem(char *fn)
{ char w[64];
  int n = 0, i, j, fs;
  FILE *f = fopen(fn, "r");

  if (f == NULL) fprintf(stderr, "File with consonant doubling verb stems not found (\"%s\").\n", fn);
  else
  { while (1)
    { fs = fscanf(f, " %n%63s%n", &i, w, &j);
      if (fs == 0 || fs == EOF) break;
      if (verbstem_n == n)
        verbstem_list = (char **)realloc(verbstem_list, (n += 256) * sizeof(char*));
      verbstem_list[verbstem_n] = (char *)malloc(j-i+1);
      strcpy(verbstem_list[verbstem_n++], w);
    }
    fclose(f);
    qsort(verbstem_list, verbstem_n, sizeof(char*), &vcmp);
  }
}

BOOL read_verbstem_file(char *argv[], 
		    unsigned int maxbuff, int *arg, int *i)
{
 int ok = 1;

 if (strlen(argv[*arg]+(*i)) > maxbuff)
    {fprintf(stderr, "Argument to option f too long\n");
     ok = 0;
    }
   else read_verbstem(argv[*arg]);


 return ok;
}

void  set_up_options(int argc, char *argv[])
{char opt;
 int  arg = 1;
 int  i = 0;
 char *opt_string = "ctuf:"; /* don't need : now */

 /* Initialize options */
 SetOption(change_case);
 UnSetOption(tag_output);
 UnSetOption(fspec);

 state = scan;

 while ((opt = get_option(argc, argv, opt_string, &arg, &i)) != 0)
    {switch (opt)
	{case 'c': UnSetOption(change_case);
	           break;
	 case 't': SetOption(tag_output);
	           break;
	 case 'u': state = any;
	           break;
	 case 'f': SetOption(fspec);
	           break;
	}
    }

  if (Option(fspec))  {
	if (arg > (argc - 1)) fprintf(stderr, "File with consonant doubling verb stems not specified\n");
    	else {read_verbstem_file(argv, MAXSTR, &arg, &i);}}
  else read_verbstem("verbstem.list");
}

int main(int argc, char **argv) 
{ set_up_options(argc, argv);

  BEGIN(state);
  while ( yylex() ) { BEGIN(state); } ;
  }

 
