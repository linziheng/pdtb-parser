require 'pp'
require File.dirname(__FILE__)+'/corpus'
require File.dirname(__FILE__)+'/variable'

class Attribution < Corpus
    attr_accessor :feature_on, :pronouns, :attr_verbs

    def initialize
        @feature_on = {
            :unigram    => true,
            :verb       => true,
            :attr_verb  => true,
            :pronoun    => true,
            :collocation=> true,
            :position   => true,
            :length     => true,
            :negation   => true,
            :rule       => true,
        }
        @pronouns = %w/i he she they we/
        @attr_verbs = 
            %w/say add accord note think believe tell argue expect report 
            contend estimate recall suggest explain acknowledge predict warn agree write 
            claim point indicate concede declare complain show conclude announce
            insist cite know observe assert advise allege caution hope admit figure
            worry feel fear emphasize disclose confirm speculate suspect plan/
    end

    def prepare_data(prefix, train_only=false)
        if train_only then
            output_files = [File.dirname(__FILE__)+'/../data/'+prefix+'.train']
        else
            output_files = [File.dirname(__FILE__)+'/../data/'+prefix+'.train', 
                File.dirname(__FILE__)+'/../data/'+prefix+'.test',
                File.dirname(__FILE__)+'/../data/'+prefix.sub(/\.nep\./, '.ep.')+'.test',
                File.dirname(__FILE__)+'/../data/'+prefix.sub(/\.nep\./, '.ep.').sub(/\.npp$/, '.pp')+'.test'
            ]
        end
        
        output_files.each do |filename|
            if filename.match(/train/) 
                which = 'train'
                some_sections = $train_data
            elsif filename.match(/test/)
                which = 'test'
                some_sections = $test_data
                if filename.match(/\.ep\./) then 
                    $error_propagate = true 
                end
                if filename.match(/\.pp/) then 
                    $with_preprocess = true 
                end
            else
                which = 'dev'
                some_sections = Variable::Dev_data
            end
            
            print_feature = which == 'test' ? true : false;
            equal_pos_neg = false

            if which == 'test'
                f1 = File.open(filename+'.f1', 'w')
                f2 = File.open(filename+'.f2', 'w')
                f4 = File.open(filename+'.f4', 'w')
            end

            reset_files

            if which == 'test' and $error_propagate then
                argpos_res  = File.readlines($argpos_res_file) .map {|e| e.chomp.split.last}
                argext_res  = File.readlines($argext_res_file) .map {|e| e.chomp}
                exp_res     = File.readlines($exp_res_file) .map {|e| e.chomp}
                nonexp_res  = File.readlines($nonexp_res_file) .map {|e| e.chomp}
                ep          = File.open(filename+'.ep', 'w')
            end

            to_file = File.open(filename, 'w')

            train_neg_id = File.open('../data/'+prefix+'.neg', 'w') if equal_pos_neg
            pos_lines = Array.new
            neg_lines = Array.new

            some_sections.each do |section_id|
                if $with_preprocess and which != 'train'
                    section = Section.new(section_id, Variable::PDTB_DIR+"/"+section_id.to_s,
                                          Variable::PTB_DIR2+"/"+section_id.to_s, Variable::DTREE_DIR2+"/"+section_id.to_s)
                else
                    section = Section.new(section_id, Variable::PDTB_DIR+"/"+section_id.to_s,
                                          Variable::PTB_DIR+"/"+section_id.to_s, Variable::DTREE_DIR+"/"+section_id.to_s)
                end
                puts "section: "+section.section_id
                section.articles.each do |article|
                    puts "  article: "+article.filename
                    if which == 'test' and $error_propagate then
                        print_features2(article, to_file, f1, f2, f4, ep, which, argpos_res, argext_res, exp_res, nonexp_res)
                    else
                        print_features(article, to_file, f1, f2, f4, which)
                    end
                end
            end

            train_neg_id.close if equal_pos_neg
            to_file.close
            ep.close if which == 'test' and $error_propagate
            if which != 'train'
                f1.close
                f2.close
                f4.close
            end
        end
    end

    def remove_puncs(str)
        puncs = %w/`` '' ` ' , . ! ? : ; - \/ \\ $ %/
        str.split(//).map {|c| if not puncs.include?(c) then c end} .compact.join
    end

    def print_features2(article, to_file, f1, f2, f4, ep, which, argpos_res, argext_res, exp_res, nonexp_res)

        if which != 'parse' then
            conn_size = 0
            article.sentences.each {|sentence| 
                sentence.check_connectives
                conn_size += sentence.connectives.size
            }
            res = argpos_res.slice!(0, conn_size) .map {|e| e != 'xxxxx' ? '1' : '0'}
            res1 = res.dup
            article.flag_disc_connectives(res)

            disc_conn_size = article.disc_connectives_p.size
            res2 = argext_res.slice!(0, disc_conn_size)
            article.label_arguments(res2)

            disc_connectives = article.disc_connectives_p
            res3 = exp_res.slice!(0, conn_size)

            res4 = Array.new
            res3.each_index {|i| if res1[i] == '1' then res4.push(res3[i]) end}
            
            article.label_exp_relations_types2(2, res4)
            exp_relations = article.exp_relations_p

            article.paragraphs.each {|paragraph|
                0.upto(paragraph.length - 2) {|i|
                    sentence1 = paragraph.sentences[i]
                    sentence2 = paragraph.sentences[i+1]
                    type = nonexp_res.shift
                    next if type == 'xxxxx'
                    article.label_nonexp_relation_type(2, sentence1, sentence2, type)
                }
            }
        else
            disc_connectives = article.disc_connectives_p
            exp_relations = article.exp_relations_p
        end

        article.mark_in_p_relation
        article.mark_attribution_clauses(true)

        if $with_preprocess and which != 'parse' then
            ary = File.readlines("/home/linzihen/corpora/PTB/clause_in_relation/wsj/23/"+article.id+".inrel").map {|l| l.chomp}

            ary.each_index {|i|
                t = ary[i].split
                if m = t[0].match(/([A-Z]+)'([A-Z]\w*)/) or m = t[0].match(/(.+)%(.+)/) then 
                    ary[i] = m[1]+' '+t[1]+' '+t[2] 
                    ary.insert(i+1, m[2]+' '+t[1]+' '+t[2]) 
                end
            }

            catch :OUT do
            article.leaves.each {|l|
                w1 = remove_puncs(l.v)
                next if w1 == '' or w1 == 'START'
                break if ary.empty?
                t = ary.shift.split
                w2 = remove_puncs(t.first)
                while w2 == '' do
                    throw :OUT if ary.empty?
                    t = ary.shift.split
                    w2 = remove_puncs(t.first)
                end
                if w1 == 'can' and w2 == 'ca' then w2 = 'can' end
                if w1 == 'will' and w2 == 'wo' then w2 = 'will' end
                if w1 == 'cannot' and w2 == 'can' then
                    t = ary.shift.split
                    w2 = 'cannot'
                end
                if w1 == 'tradeethnic' and w2 == 'trade' then
                    ary.shift
                    t = ary.shift.split
                    w2 = 'tradeethnic'
                end
                if w1 == 'bethat' and w2 == 'be' then
                    ary.shift
                    t = ary.shift.split
                    w2 = 'bethat'
                end

                if w1 != w2 then
                    puts 'wawa'
                    puts article.id
                    exit
                end
                if t[1] == 'true'
                    l.is_attr_leaf = true
                else
                    l.is_attr_leaf = false
                end
                if t[2] == 'true'
                    l.in_relation = true
                else
                    l.in_relation = false
                end
            }
            end
        else
            article.mark_in_relation
        end
        article.mark_attribution_clauses

        article.clauses.each_index {|idx|
            curr = article.clauses[idx]
            label = article.clause_marked[idx] ? '1' : '0'

            has_attr_verb = false
            curr.each {|l|
                if @attr_verbs.include?(l.lemmatized)
                    has_attr_verb = true
                    break
                end
            }

            if which != 'parse' then
                if not article.clause_in_relation[idx] and article.clause_in_p_relation[idx] then
                    ep.puts 'not_in_rel-->in_rel'
                elsif article.clause_in_relation[idx] and not article.clause_in_p_relation[idx] then
                    ep.puts 'in_rel-->not_in_rel'
                elsif not article.clause_in_relation[idx] and not article.clause_in_p_relation[idx] then
                    ep.puts 'not_in_rel-->not_in_rel'
                else
                    ep.puts
                end
            end

            to_file_line = 'dummy '
            if idx > 0
                prv         = article.clauses[idx-1]
                prv_label   = article.clause_marked[idx-1] ? '1' : '0'
            else
                prv         = nil
                prv_label   = nil
            end

            if idx < (article.clauses.size-1)
                nxt         = article.clauses[idx+1]
                nxt_label   = article.clause_marked[idx+1] ? '1' : '0'
            else
                nxt         = nil
                nxt_label   = nil
            end

            if @feature_on[:unigram]
                # all unigrams
                tmp = Hash.new(0)
                curr.each {|l|
                    tmp[l.downcased] += 1
                }
                tmp.keys.each {|k| to_file_line += 'uni_'+k + ' '}
            end

            has_verb = false
            if @feature_on[:verb]
                # verbs
                curr.each {|l|
                    if $verb_tags.include?(l.parent_node.value)
                        has_verb = true
                        to_file_line += 'dc_'+l.downcased + ' '
                        to_file_line += 'lmt_'+l.lemmatized + ' '
                    end
                }
            end

            if @feature_on[:attr_verb]
                curr.each {|l|
                    if @attr_verbs.include?(l.lemmatized)
                        to_file_line += 'attr_verb_'+l.lemmatized + ' '
                    end
                }
            end

            if @feature_on[:pronoun]
                # pronoun: I, he, she, they, we
                tmp = Array.new
                curr.each {|l|
                    if @pronouns.include?(l.downcased) and l.parent_node.value == 'PRP'
                        tmp.push(l.downcased)
                    end
                }
                tmp.uniq.each {|w| to_file_line += 'pronoun_'+w + ' '}
            end

            if @feature_on[:collocation]
                # first term of curr clause
                to_file_line += 'curr_1st_'+curr[0].downcased + ' '

                # last term of curr clause
                to_file_line += 'curr_last_'+curr[-1].downcased + ' '

                if prv != nil
                    # last term of prev clause
                    to_file_line += 'prev_last_'+prv[-1].downcased + ' '
                    ## second last term of prev clause
                    #if prv.size >= 2
                    #to_file_line += 'prev_2nd_last_'+prv[-2].downcased + ' '
                    #end

                    # prev_last + curr_1st
                    to_file_line += 'prev_last_curr_1st_'+prv[-1].downcased+'_'+curr[0].downcased + ' '
                end

                if nxt != nil
                    # first term of next clause
                    to_file_line += 'next_1st_'+nxt[0].downcased + ' '
                    ## second term of next clause
                    #if nxt.size >= 2
                    #to_file_line += 'next_2nd_'+nxt[1].downcased + ' '
                    #end

                    # curr_last + next_1st
                    to_file_line += 'curr_last_next_1st_'+curr[-1].downcased+'_'+nxt[0].downcased + ' '
                end
            end

            if @feature_on[:position]
                # position in sentence
                if curr[0].prev_leaf == nil and curr[-1].next_leaf == nil
                    to_file_line += 'pos_whole '
                elsif curr[0].prev_leaf == nil
                    to_file_line += 'pos_start '
                elsif curr[-1].next_leaf == nil
                    to_file_line += 'pos_end '
                else
                    to_file_line += 'pos_mid '
                end
            end

            if @feature_on[:length]
                # length of prev/curr/next clauses
                to_file_line += 'len_prev_=2 ' if prv != nil and prv.length == 2
                to_file_line += 'len_curr_=2 ' if curr.length == 2
                to_file_line += 'len_next_=2 ' if nxt != nil and nxt.length == 2 

                to_file_line += 'len_prev_=1 ' if prv != nil and prv.length == 1
                to_file_line += 'len_curr_=1 ' if curr.length == 1
                to_file_line += 'len_next_=1 ' if nxt != nil and nxt.length == 1 
            end

            if @feature_on[:negation]
                # negation
                curr.each {|l|
                    if l.parent_node.value == 'RB' and (l.downcased == "n't" or l.downcased == "not")
                        to_file_line += 'negated '
                        break
                    end
                }
            end

            if @feature_on[:rule]
                rules = article.get_production_rules2(idx,  -1, false, true).keys.map {|e| e.gsub(/ /, '_')}
                rules.each {|r|
                    to_file_line += r+' '
                }
            end

            if which != 'parse' then
                f4.puts article.id.to_s+' '+curr.first.goto_tree.sent_id.to_s
                curr.each {|l|
                    if which == 'test'
                        if l.is_attr_leaf
                            f1.print l.up.v+'_'+l.v+' '
                        else
                            f1.print '_ '
                        end
                        f2.print l.up.v+'_'+l.v+' '
                    end
                }
                if which == 'test'
                    f1.puts
                    f2.puts
                end
            end

            if which != 'parse'
                to_file.puts to_file_line+label 
            else
                to_file.puts to_file_line+'xxxxx' 
            end
        }
    end

    def print_features(article, to_file, f1, f2, f4, which)
        article.mark_in_relation
        article.mark_attribution_clauses

        article.clauses.each_index {|idx|
            curr = article.clauses[idx]
            if which != 'parse'
                label = article.clause_marked[idx] ? '1' : '0'
            end
            has_attr_verb = false
            curr.each {|l|
                if @attr_verbs.include?(l.lemmatized)
                    has_attr_verb = true
                    break
                end
            }

            next if not article.clause_in_relation[idx]

            to_file_line = 'dummy '
            if idx > 0
                prv         = article.clauses[idx-1]
                prv_label   = article.clause_marked[idx-1] ? '1' : '0'
            else
                prv         = nil
                prv_label   = nil
            end

            if idx < (article.clauses.size-1)
                nxt         = article.clauses[idx+1]
                nxt_label   = article.clause_marked[idx+1] ? '1' : '0'
            else
                nxt         = nil
                nxt_label   = nil
            end

            if @feature_on[:unigram]
                # all unigrams
                tmp = Hash.new(0)
                curr.each {|l|
                    tmp[l.downcased] += 1
                }
                tmp.keys.each {|k| to_file_line += 'uni_'+k + ' '}
            end

            has_verb = false
            if @feature_on[:verb]
                # verbs
                curr.each {|l|
                    if $verb_tags.include?(l.parent_node.value)
                        has_verb = true
                        to_file_line += 'dc_'+l.downcased + ' '
                        to_file_line += 'lmt_'+l.lemmatized + ' '
                    end
                }
            end

            if @feature_on[:attr_verb]
                curr.each {|l|
                    if @attr_verbs.include?(l.lemmatized)
                        to_file_line += 'attr_verb_'+l.lemmatized + ' '
                    end
                }
            end

            if @feature_on[:pronoun]
                # pronoun: I, he, she, they, we
                tmp = Array.new
                curr.each {|l|
                    if @pronouns.include?(l.downcased) and l.parent_node.value == 'PRP'
                        tmp.push(l.downcased)
                    end
                }
                tmp.uniq.each {|w| to_file_line += 'pronoun_'+w + ' '}
            end

            if @feature_on[:collocation]
                # first term of curr clause
                to_file_line += 'curr_1st_'+curr[0].downcased + ' '

                # last term of curr clause
                to_file_line += 'curr_last_'+curr[-1].downcased + ' '

                if prv != nil
                    # last term of prev clause
                    to_file_line += 'prev_last_'+prv[-1].downcased + ' '
                    ## second last term of prev clause
                    #if prv.size >= 2
                    #to_file_line += 'prev_2nd_last_'+prv[-2].downcased + ' '
                    #end

                    # prev_last + curr_1st
                    to_file_line += 'prev_last_curr_1st_'+prv[-1].downcased+'_'+curr[0].downcased + ' '
                end

                if nxt != nil
                    # first term of next clause
                    to_file_line += 'next_1st_'+nxt[0].downcased + ' '
                    ## second term of next clause
                    #if nxt.size >= 2
                    #to_file_line += 'next_2nd_'+nxt[1].downcased + ' '
                    #end

                    # curr_last + next_1st
                    to_file_line += 'curr_last_next_1st_'+curr[-1].downcased+'_'+nxt[0].downcased + ' '
                end
            end

            if @feature_on[:position]
                # position in sentence
                if curr[0].prev_leaf == nil and curr[-1].next_leaf == nil
                    to_file_line += 'pos_whole '
                elsif curr[0].prev_leaf == nil
                    to_file_line += 'pos_start '
                elsif curr[-1].next_leaf == nil
                    to_file_line += 'pos_end '
                else
                    to_file_line += 'pos_mid '
                end
            end

            if @feature_on[:length]
                # length of prev/curr/next clauses
                to_file_line += 'len_prev_=2 ' if prv != nil and prv.length == 2
                to_file_line += 'len_curr_=2 ' if curr.length == 2
                to_file_line += 'len_next_=2 ' if nxt != nil and nxt.length == 2 

                to_file_line += 'len_prev_=1 ' if prv != nil and prv.length == 1
                to_file_line += 'len_curr_=1 ' if curr.length == 1
                to_file_line += 'len_next_=1 ' if nxt != nil and nxt.length == 1 
            end

            if @feature_on[:negation]
                # negation
                curr.each {|l|
                    if l.parent_node.value == 'RB' and (l.downcased == "n't" or l.downcased == "not")
                        to_file_line += 'negated '
                        break
                    end
                }
            end

            if @feature_on[:rule]
                rules = article.get_production_rules2(idx,  -1, false, true).keys.map {|e| e.gsub(/ /, '_')}
                rules.each {|r|
                    to_file_line += r+' '
                }
            end

            f4.puts article.id.to_s+' '+curr.first.goto_tree.sent_id.to_s if f4 != nil
            curr.each {|l|
                if which == 'test'
                    if l.is_attr_leaf
                        f1.print l.up.v+'_'+l.v+' '
                    else
                        f1.print '_ '
                    end
                    f2.print l.up.v+'_'+l.v+' '
                end
            }
            if which == 'test'
                f1.puts
                f2.puts
            end

            if which != 'parse'
                to_file.puts to_file_line+label 
            else
                to_file.puts to_file_line+'xxxxx' 
            end
        }
    end
end
