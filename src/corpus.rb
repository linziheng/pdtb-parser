require File.dirname(__FILE__)+'/section'
require File.dirname(__FILE__)+'/relation'
require File.dirname(__FILE__)+'/variable'
require 'pp'

class Corpus
    attr_accessor :sections, :dev_sections, :test_sections,
        :train_data, :dev_data, :all_data, :vo

    $prule_file  = File.dirname(__FILE__)+"/../lib/rule-mi-Freq5-adj-args-13type-leaf.txt"
    $drule_file  = File.dirname(__FILE__)+"/../lib/dtree-mi-Freq5-adj-args-13type.txt"
    $wordpair_file = File.dirname(__FILE__)+"/../lib/word-pair-mi-Freq5-adj-args-13type-stemmed.txt"

    $punctuations = %w/`` '' ` ' -LRB- -RRB- -LCB- -RCB- , . ! ? : ; ... --/
    $punctuation_tags = %w/# $ `` '' ( ) , . :/
    $verb_tags = %w/VB VBD VBG VBN VBP VBZ/

    POS_tags = %w/# $ `` '' ( ) , . : CC CD DT EX FW IN JJ JJR JJS LS MD NN NNP NNPS NNS 
        PDT POS PRP PRP$ RB RBR RBS RP SYM TO UH VB VBD VBG VBN VBP VBZ WDT WP WP$ WRB/
    Non_terminals = %w/NP VP S ADJP QP PP ADVP PRN FRAG SINV UCP SBAR NX WHNP SQ X SBARQ 
        NAC INTJ WHADVP RRC WHADJP PRT CONJP LST WHPP/
    Level_1_types = %w/Comparison Contingency Expansion Temporal/
    Level_2_types = %w/Asynchronous Synchrony
        Cause Pragmatic_cause 
        Contrast Concession 
        Conjunction Instantiation Restatement Alternative List/
    Level_2_types_full = %w/Asynchronous Synchrony
        Cause Pragmatic_cause Condition Pragmatic_condition 
        Contrast Pragmatic_contrast Concession Pragmatic_concession 
        Conjunction Instantiation Restatement Alternative Exception List/
    Connectives = [
        "but", "and", "also", "if", "when", "because", "while", "as", "after", "however", 
        "although", "then", "though", "before", "so", "meanwhile", "for example", "still", "since", 
        "until", "in addition", "instead", "thus", "yet", "moreover", "indeed", "unless", "later", 
        "for instance", "or", "once", "in fact", "as a result", "separately", "previously", 
        "if then", "nevertheless", "finally", "on the other hand", "in turn", "by contrast", "nor", 
        "otherwise", "nonetheless", "therefore", "so that", "as long as", "now that", "as soon as", 
        "ultimately", "in other words", "as if", "rather", "besides", "in particular", "similarly", 
        "meantime", "thereby", "thereafter", "in contrast", "furthermore", "afterward", "earlier", 
        "consequently", "overall", "except", "in the end", "likewise", "by comparison", "specifically", 
        "as well", "additionally", "further", "by then", "alternatively", "much as", "next", "in short", 
        "as though", "simultaneously", "neither nor", "whereas", "on the contrary", "for", "till", 
        "lest", "either or", "hence", "conversely", "accordingly", "as an alternative", "regardless", 
        "in sum", "plus", "else", "if and when", "insofar as", "before and after", "when and if",
        "on the one hand on the other hand"
    ]

    def initialize
        @sections = Array.new()
        @dev_sections = Array.new()
        @test_sections = Array.new()

        @all_data   = %w/00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24/
        @train_data = %w/02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21/
        @test_data  = %w/23/
        @dev_data   = %w/22/

        @train2_data= %w/02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20/
        @test2_data = %w/21 22/
        @dev2_data  = %w/00 01/
    end

    def reset_files
        $conn_human_res_file    = File.dirname(__FILE__)+'/../data/human.conn.test'
        $argpos_human_res_file  = File.dirname(__FILE__)+'/../data/human.argpos.test'
        $argext_human_res_file  = File.dirname(__FILE__)+'/../data/human.argext.test'
        $exp_human_res_file     = File.dirname(__FILE__)+'/../data/human.exp.test'
        $argpos_res_file2       = File.dirname(__FILE__)+'/../data/100726c.argpos.nep.npp.test.predicted.res'
        if not $with_preprocess then
            $conn_res_file          = File.dirname(__FILE__)+'/../data/100726b.conn.nep.npp.test.predicted'
            $argpos_res_file        = File.dirname(__FILE__)+'/../data/100726c.argpos.ep.npp.test.predicted.res'
            $argext_res_file        = File.dirname(__FILE__)+'/../data/100726e.argext.ep.npp.test.res'
            $exp_res_file           = File.dirname(__FILE__)+'/../data/100726f.exp.ep.npp.test.predicted.res'
            $nonexp_res_file        = File.dirname(__FILE__)+'/../data/100726g.nonexp.ep.npp.test.res'
        else
            $conn_res_file          = File.dirname(__FILE__)+'/../data/100726b.conn.nep.pp.test.predicted'
            $argpos_res_file        = File.dirname(__FILE__)+'/../data/100726c.argpos.ep.pp.test.predicted.res'
            $argext_res_file        = File.dirname(__FILE__)+'/../data/100726e.argext.ep.pp.test.res'
            $exp_res_file           = File.dirname(__FILE__)+'/../data/100726f.exp.ep.pp.test.predicted.res'
            $nonexp_res_file        = File.dirname(__FILE__)+'/../data/100726g.nonexp.ep.pp.test.res'
        end
    end

    def find_conn_type(conn_str)
        if Variable::Conn_group.include?(conn_str.downcase)
            'group'
        elsif Variable::Conn_intra.include?(conn_str.downcase)
            'intra'
        else
            'inter'
        end
    end

    def find_argpos(arg1_sids, conn_sids)
        if arg1_sids.last + 1 == conn_sids.first
            'IPS'
        elsif arg1_sids.last + 1 < conn_sids.first
            'NAPS'
        elsif conn_sids.first + 1 <= arg1_sids.first
            'FS'
        else 
            'SS'
        end
    end

    # input: connective leaves
    # output: conn str, conn sid
    def get_conn_str(connective)
        conn_sids = Array.new
        conn_sids = [connective[0].goto_tree.sent_id]
        conn_str = connective[0].value
        check = false
        1.upto(connective.size - 1) {|i|
            if connective[i-1].next_leaf == connective[i] then
                conn_str += ' '+connective[i].value
            else
                conn_str += '..'+connective[i].value
                if not check and connective[i].goto_tree.sent_id != conn_sids.first
                    conn_sids.push(connective[i].goto_tree.sent_id)
                    check = true
                end
            end
        }

        [conn_str, conn_sids]
    end

    # '2399', 2
    def get_relation(article_id, rel_id, print_tree=false)
        section_id = article_id[0,2]
        filename = 'wsj_'+article_id+'.pipe'
        parsed_filename = filename.sub('.pipe', '.mrg')
        dtree_filename = filename.sub('.pipe', '.dtree')
        article = Article.new(filename, PDTB_DIR+"/"+section_id+"/"+filename,
            PTB_DIR+"/"+section_id+"/"+parsed_filename, DTREE_DIR+"/"+section_id+"/"+dtree_filename)

        article.get_relation_sequence

    end

    def get_sentence(article_id, sent_id)
        section_id = article_id[0,2]
        filename = 'wsj_'+article_id+'.pipe'
        parsed_filename = filename.sub('.pipe', '.mrg')
        dtree_filename = filename.sub('.pipe', '.dtree')
        article = Article.new(filename, PDTB_DIR+"/"+section_id+"/"+filename,
            PTB_DIR+"/"+section_id+"/"+parsed_filename, DTREE_DIR+"/"+section_id+"/"+dtree_filename)
        article.sentences[sent_id].parsed_tree.print_tree
    end

    def iterate_relations
        hsh = Hash.new(0)
        $tags = Hash.new(0)
        arg1_in_2 = 0
        arg2_in_1 = 0
        @all_data.each do |section_id|
            section = Section.new(section_id, Variable::PDTB_DIR+"/"+section_id.to_s,
                            Variable::PTB_DIR+"/"+section_id.to_s, Variable::DTREE_DIR+"/"+section_id.to_s)
            puts "processing section "+section.section_id
            section.articles.each do |article|
                puts "  article "+article.filename
                article.exp_relations.each do |rel|
                    arg1_sid, arg2_sid = rel.arg1_arg2_sentences2
                    next if arg1_sid != arg2_sid
                    arg1_ids = rel.arg1_leaves.map {|n| n.leaf_orig_id}
                    arg2_ids = rel.arg2_leaves.map {|n| n.leaf_orig_id}
                    arg1_mid = rel.arg1_leaves[rel.arg1_leaves.size / 2].leaf_orig_id
                    arg2_mid = rel.arg2_leaves[rel.arg2_leaves.size / 2].leaf_orig_id
                    
                    if arg1_ids.include?(arg2_mid) then
                        puts "arg2 in 1"
                        arg2_in_1 += 1
                    end
                    if arg2_ids.include?(arg1_mid) then
                        puts "arg1 in 2"
                        arg1_in_2 += 1
                    end
                end
            end
            puts arg1_in_2
            puts arg2_in_1
        end

        puts 'done!'
    end

    def collect_feature_relation_stat(file, feature_type, frequency=5, data_set=@train_data)
        n1_ = Hash.new(0)
        n_1 = Hash.new(0)
        n11 = Hash.new(0)
        n   = 0

        # disc-imp, disc-rel, disc-adj
        which = 'disc-adj'

        count = 0
        conn2type = Hash.new(0)
        share_arg_cnt = Hash.new(0)
        data_set.each do |section_id|
            section = Section.new(section_id, PDTB_DIR+"/"+section_id.to_s,
                            PTB_DIR+"/"+section_id.to_s, DTREE_DIR+"/"+section_id.to_s)
            puts "processing section "+section.section_id
            section.articles.each do |article|
                puts "  article "+article.filename
                article.relations.each do |relation|
                    if which == 'disc-imp'
                        next if relation[1] != "Implicit"
                    elsif which == 'disc-rel'
                        next if relation[1] != "Implicit" and relation[1] != "AltLex" and relation[1] != "EntRel" and relation[1] != "NoRel"  
                    elsif which == 'disc-adj'
                        next if relation[1] != "Implicit" and relation[1] != "AltLex" and relation[1] != "EntRel" and relation[1] != "NoRel"  
                    end

                    prev_rel = relation.prev_rel
                    next_rel = relation.next_rel
                    puts relation.id
                    
                    if which == 'disc-imp'
                        types = relation.level_2_types
                        types.each do |t|
                            if not Level_2_types.include?(t)
                                types.delete(t)
                            end
                        end
                        #types = Level_2_types
                        types.uniq!
                    elsif which == 'disc-rel'
                        if relation[1] == "Implicit" or relation[1] == "AltLex"
                            types = ['disc-rel']
                        else
                            types = ['non-disc-rel']
                        end
                    elsif which == 'disc-adj'
                        if relation[1] == "Implicit" or relation[1] == "AltLex"
                            types = relation.level_2_types
                            types.each do |t|
                                if not Level_2_types.include?(t)
                                    types.delete(t)
                                end
                            end
                            types.uniq!
                        elsif relation[1] == "EntRel"
                            types = ['EntRel']
                        elsif relation[1] == "NoRel"
                            types = ['NoRel']
                        end
                    end

                    ## word pairs
                    if feature_type == 'word-pair' then
                        text1 = relation.arg1s['stemmed'].split
                        text2 = relation.arg2s['stemmed'].split
                        pairs = Array.new
                        text1.each {|w1|
                            text2.each {|w2|
                                pairs << w1+'_'+w2
                            }
                        }
                        pairs.uniq!
                        all = pairs
                    # production rules
                    elsif feature_type == 'rule' then
                        tree_cnts = relation.get_production_rules(%w/arg1 arg2/, -1, true)
                        all = tree_cnts.keys
                    # dependency rules
                    elsif feature_type == 'dtree' then
                        tree_cnts = relation.get_dependency_rules(%w/arg1 arg2/, -1, false, true, false)
                        all = tree_cnts.keys
                    else
                        puts 'error: not correct feature type'
                        exit
                    end

                    all.map! {|a| a.gsub(/ /, '_')}
                    all.uniq!
                    types.each do |type|
                        type = type.gsub(/ /, '_')
                        count += 1

                        #type = relation.level_2_type
                        #next if type == nil
                        n += 1
                        n_1[type] += 1

                        all.each do |a|
                            n1_[a] += 1
                            n11[a+' '+type] += 1
                        end
                    end
                end
            end
        end

        puts "n   size: " + n.to_s
        puts "n_1 size: " + n_1.size.to_s
        puts "n1_ size: " + n1_.size.to_s
        puts "n11 size: " + n11.size.to_s
        puts "count:    " + count.to_s
        
        @hash = Hash.new(0)
        n1_.each_key do |p|
            next if n1_[p] < frequency
            nn1_ = n1_[p]
            n_1.each_key do |r|
                nn_1 = n_1[r]
                nn11 = n11[p+" "+r]

                nn01 = nn_1 - nn11
                nn0_ = n - nn1_
                nn_0 = n - nn_1
                nn10 = nn1_ - nn11
                nn00 = nn0_ - nn01
                
                a = (nn11+1) * 1.0 / (n+4) * Math.log((n+4) * (nn11+1) * 1.0 / (nn1_+2) / (nn_1+2)) / Math.log(2)
                b = (nn01+1) * 1.0 / (n+4) * Math.log((n+4) * (nn01+1) * 1.0 / (nn0_+2) / (nn_1+2)) / Math.log(2)
                c = (nn10+1) * 1.0 / (n+4) * Math.log((n+4) * (nn10+1) * 1.0 / (nn1_+2) / (nn_0+2)) / Math.log(2)
                d = (nn00+1) * 1.0 / (n+4) * Math.log((n+4) * (nn00+1) * 1.0 / (nn0_+2) / (nn_0+2)) / Math.log(2)
                
                if which == 'disc-rel'
                    if r == 'disc-rel'
                        @hash["#{p} #{r} #{n1_[p]} #{nn11} #{nn10} #{nn01} #{nn00}"] = a + b + c +d
                    end
                else
                    @hash["#{p} #{r} #{n1_[p]} #{nn11} #{nn10} #{nn01} #{nn00}"] = a + b + c +d
                end
            end
        end
        
        to_file = File.open(file, "w")
        @hash.sort {|a,b| b[1] <=> a[1]} .each {|k,v|
            to_file.puts k+" "+v.to_s
        }
        to_file.close
    end


    def separate_files(class_attr_in_train, *files)
        if class_attr_in_train.has_value?(false)
            arr = class_attr_in_train.map {|a,b| a if b == true}
            arr.delete(nil)
            files.each do |filename|
                File.open(filename, 'r+') do |f|
                    lines = f.readlines
                    lines.each do |line|
                        if line.match(/^@attribute relation/)
                            line.sub!(/\{.*\}/, '{'+arr.join(', ')+'}')
                        end
                    end
                    f.pos = 0
                    f.print lines
                    f.truncate(f.pos)
                end
            end
        end

        files.each do |filename|
            file = File.open(filename, 'r')
            expl_filename = filename.sub(/all/, 'exp')
            impl_filename = filename.sub(/all/, 'imp')
            expl_file = File.open(expl_filename, 'w')
            impl_file = File.open(impl_filename, 'w')
            
            while line = file.gets
                line.chomp!
                if line.match(/%%% Explicit/)
                    expl_file.puts line
                elsif line.match(/%%% Implicit/)
                    impl_file.puts line
                else
                    expl_file.puts line
                    impl_file.puts line
                end
            end

            expl_file.close
            impl_file.close
        end
    end

    def collect_feature_attribution_stat(file, frequency=5)
        n1_ = Hash.new(0)
        n_1 = Hash.new(0)
        n11 = Hash.new(0)
        n   = 0

        count = 0
        @train_data.each do |section_id|
            section = Section.new(section_id, PDTB_DIR+"/"+section_id.to_s,
                            PTB_DIR+"/"+section_id.to_s, DTREE_DIR+"/"+section_id.to_s)
            puts "processing section "+section.section_id
            section.articles.each do |article|
                puts "  article "+article.filename
                article.edu_ary.each_index {|idx|
                    next if not article.edu_in_relation[idx]
                    curr = article.edu_ary[idx]
                    label = article.edu_marked[idx] ? '1' : '0'

                    ary = Array.new
                    curr.each {|l|
                        ary.push(l.lemmatized) if $verb_tags.include?(l.parent_node.value)
                    }
                    ary.uniq!

                    if not ary.empty?
                        n += 1
                        n_1[label] += 1

                        ary.each {|a|
                            n1_[a] += 1
                            n11[a+' '+label] += 1
                        }
                    end
                }
            end
        end

        puts "n   size: " + n.to_s
        puts "n_1 size: " + n_1.size.to_s
        puts "n1_ size: " + n1_.size.to_s
        puts "n11 size: " + n11.size.to_s
        puts "count:    " + count.to_s
        
        @hash = Hash.new(0)
        n1_.each_key do |p|
            next if n1_[p] < frequency
            nn1_ = n1_[p]
            n_1.each_key do |r|
                nn_1 = n_1[r]
                nn11 = n11[p+" "+r]

                nn01 = nn_1 - nn11
                nn0_ = n - nn1_
                nn_0 = n - nn_1
                nn10 = nn1_ - nn11
                nn00 = nn0_ - nn01
                
                a = (nn11+1) * 1.0 / (n+4) * Math.log((n+4) * (nn11+1) * 1.0 / (nn1_+2) / (nn_1+2)) / Math.log(2)
                b = (nn01+1) * 1.0 / (n+4) * Math.log((n+4) * (nn01+1) * 1.0 / (nn0_+2) / (nn_1+2)) / Math.log(2)
                c = (nn10+1) * 1.0 / (n+4) * Math.log((n+4) * (nn10+1) * 1.0 / (nn1_+2) / (nn_0+2)) / Math.log(2)
                d = (nn00+1) * 1.0 / (n+4) * Math.log((n+4) * (nn00+1) * 1.0 / (nn0_+2) / (nn_0+2)) / Math.log(2)
                
                if r == '1'
                    @hash["#{p} #{r} #{n1_[p]} #{nn11} #{nn10} #{nn01} #{nn00}"] = a + b + c +d 
                end
            end
        end
        
        to_file = File.open(file, "w")
        @hash.sort {|a,b| b[1] <=> a[1]} .each {|k,v|
            to_file.puts k+" "+v.to_s
        }
        to_file.close
    end


    def training_and_evaluation(prefix)
        `java CreateModel ../data/#{prefix}.train`
        `java Predict ../data/#{prefix}.test > ../data/#{prefix}.test.predicted`
    end
end
