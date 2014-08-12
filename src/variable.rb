class Variable
    $lib_dir = File.expand_path(File.dirname(__FILE__))+"/../lib/"
    STANFORD_PARSER  = "#{$lib_dir}/stanford-parser-2010-08-20/"
    MORPHA      = "#{$lib_dir}/morph/morpha"
    VERBSTEM    = "#{$lib_dir}/morph/verbstem.list"
    CLASSPATH   = ".:#{$lib_dir}/maxent-2.5.2/lib/trove.jar:#{$lib_dir}/maxent-2.5.2/output/maxent-2.5.2.jar:#{$lib_dir}/opennlp-tools-1.3.0/output/opennlp-tools-1.3.0.jar:#{$lib_dir}/opennlp-tools-1.3.0/lib/jwnl-1.3.3.jar"

    Level_1_types = %w/Comparison Contingency Expansion Temporal/
    Level_2_types = %w/Asynchronous Synchrony
        Cause Pragmatic_cause 
        Contrast Concession 
        Conjunction Instantiation Restatement Alternative List/
    Level_2_types_full = %w/Asynchronous Synchrony
        Cause Pragmatic_cause Condition Pragmatic_condition 
        Contrast Pragmatic_contrast Concession Pragmatic_concession 
        Conjunction Instantiation Restatement Alternative Exception List/
    Level_2_to_1 = Hash[*%w/Asynchronous Temporal Synchrony Temporal
        Cause Contingency Pragmatic_cause Contingency Condition Contingency Pragmatic_condition Contingency 
        Contrast Comparison Pragmatic_contrast Comparison Concession Comparison Pragmatic_concession Comparison 
        Conjunction Expansion Instantiation Expansion Restatement Expansion Alternative Expansion Exception Expansion List Expansion/]

    All_data    = %w/00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24/
    $train_data  = %w/02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21/
    $test_data   = %w/23/
    $dev_data    = %w/22/
    
    #Conn_group = ["accordingly", "additionally", "after", "afterward", "also", "alternatively", "although", "and", "as", "as a result", "as an alternative", "as if", "as long as", "as soon as", "as though", "as well", "because", "before", "before and after", "besides", "but", "by comparison", "by contrast", "by then", "consequently", "conversely", "earlier", "else", "except", "finally", "for", "for example", "for instance", "further", "furthermore", "hence", "however", "if", "if and when", "in addition", "in contrast", "in fact", "in other words", "in particular", "in short", "in sum", "in the end", "in turn", "indeed", "insofar as", "instead", "later", "lest", "likewise", "meantime", "meanwhile", "moreover", "much as", "nevertheless", "next", "nonetheless", "nor", "now that", "on the contrary", "on the other hand", "once", "or", "otherwise", "overall", "plus", "previously", "rather", "regardless", "separately", "similarly", "simultaneously", "since", "so", "so that", "specifically", "still", "then", "thereafter", "thereby", "therefore", "though", "thus", "till", "ultimately", "unless", "until", "when", "when and if", "whereas", "while", "yet"]
    #Conn_group = ["or", "so", "as", "if", "and", "but", "nor", "yet", "for", "next", "then", "when", "lest", "till", "also", "once", "else", "thus", "plus", "hence", "later", "until", "since", "after", "still", "as if", "while", "in sum", "unless", "before", "rather", "though", "except", "indeed", "so that", "instead", "however", "much as", "whereas", "because", "in turn", "besides", "in fact", "overall", "further", "earlier", "by then", "as well", "thereby", "finally", "moreover", "meantime", "likewise", "although", "now that", "in short", "afterward", "similarly", "as though", "therefore", "otherwise", "meanwhile", "conversely", "ultimately", "insofar as", "separately", "as soon as", "regardless", "as long as", "thereafter", "previously", "in the end", "nonetheless", "in contrast", "if and when", "in addition", "accordingly", "as a result", "by contrast", "furthermore", "when and if", "for example", "specifically", "consequently", "additionally", "for instance", "nevertheless", "alternatively", "in particular", "by comparison", "simultaneously", "in other words", "on the contrary", "before and after", "as an alternative", "on the other hand"]
    Conn_group = ["on the other hand", 
        "as a result", "as an alternative", "as long as", "as soon as", 
        "before and after", "if and when", "in other words", "in the end", "on the contrary", "when and if", 
        "as if", "as though", "as well", "by comparison", "by contrast", "by then", "for example", "for instance", 
        "in addition", "in contrast", "in fact", "in particular", "in short", "in sum", "in turn", "insofar as", 
        "much as", "now that", "so that", 
        "accordingly", "additionally", "after", "afterward", "also", "alternatively", "although", "and", "as", 
        "because", "before", "besides", "but", "consequently", "conversely", "earlier", "else", "except", 
        "finally", "for", "further", "furthermore", "hence", "however", "if", "indeed", "instead", "later", 
        "lest", "likewise", "meantime", "meanwhile", "moreover", "nevertheless", "next", "nonetheless", "nor", 
        "once", "or", "otherwise", "overall", "plus", "previously", "rather", "regardless", "separately", 
        "similarly", "simultaneously", "since", "so", "specifically", "still", "then", "thereafter", 
        "thereby", "therefore", "though", "thus", "till", "ultimately", "unless", "until", "when", "whereas", 
        "while", "yet"]
    Conn_intra = ["either..or", "if..then", "neither..nor"]
    Conn_inter = ["on the one hand..on the other hand"]

    Punctuations = %w/`` '' ` ' -LRB- -RRB- -LCB- -RCB- , . ! ? : ; ... --/
    Punc1 = %w/'' ' -RRB- -RCB-/
    Punc2 = %w/, . ! ? : ; ... --/
    Punc3 = %w/'' ' -RRB- -RCB- , . ! ? : ; ... --/
    Punctuation_tags = %w/# $ `` '' -LRB- -RRB- , . :/
    Verb_tags = %w/VB VBD VBG VBN VBP VBZ/
    Noun_tags = %w/NN NNP NNPS NNS PRP PRP$/
    #Event_tags = %w/NN NNS NNP NNPS VB VBD VBG VBN VBP VBZ/

    #Attr_verbs = %w/say accord note add believe think argue contend recall tell/

    PDTB_DIR    = "/home/linzihen/corpora/PDTB/converted-data/"
    PTB_DIR     = "/home/linzihen/corpora/PTB/combined/wsj/"
    PTB_DIR2    = "/home/linzihen/corpora/PTB/charniak/wsj/"
    DTREE_DIR   = "/home/linzihen/corpora/PTB/dtree/wsj"
    DTREE_DIR2  = "/home/linzihen/corpora/PTB/dtree2/wsj"
end
