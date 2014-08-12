require 'pp'
require File.dirname(__FILE__)+'/corpus'
require File.dirname(__FILE__)+'/variable'

class Implicit < Corpus
    attr_accessor :feature_on, :features_prule, :features_drule, :features_wp, :features_genre, :features_conn

    def initialize(num_prule, num_drule, num_wp, use_context)
        @feature_on = {
            :prule => true,                          # production rule 
            :drule => true,                         # dependency rule
            :word_pair => true,                     # word pair
            :context => false, :context2 => false,    # word pair
            :conn => false,                         # connective
            #:genre => true,                         # genre
            :arg2_word => true,
        }
        @feature_on[:prule] = false if num_prule == 0
        @feature_on[:drule] = false if num_drule == 0
        @feature_on[:word_pair] = false if num_wp == 0
        if use_context == false
            @feature_on[:context] = false
            @feature_on[:context2] = false
        end

        if @feature_on[:prule]
            @features_prule = Hash.new
            f = File.open($prule_file, 'r')
            count = 0
            while line = f.gets
                break if count == num_prule      #11_113  
                line.chomp!
                tokens = line.split
                rule = tokens[0]
                if not @features_prule.has_key?(rule)
                    @features_prule[rule] = tokens.last.to_f
                    count += 1
                end
            end
            f.close
        end

        if @feature_on[:drule]
            @features_drule = Hash.new
            f = File.open($drule_file, 'r')
            count = 0
            while line = f.gets
                break if count == num_drule
                line.chomp!
                tokens = line.split
                rule = tokens[0]
                if not @features_drule.has_key?(rule)
                    @features_drule[rule] = tokens.last.to_f
                    count += 1
                end
            end
            f.close
        end

        if @feature_on[:word_pair]
            features2 = Hash.new
            f = File.open($wordpair_file, 'r')
            count = 0
            while line = f.gets
                break if count == num_wp      #93_482  
                line.chomp!
                tokens = line.split
                pair = tokens[0]
                if not features2.has_key?(pair)
                    features2[pair] = tokens.last.to_f
                    count += 1
                end
            end
            f.close
            @features_wp = features2.keys
        end

        if @feature_on[:context]
            features_context = {
                '(rel)_()' => 1, '()_(rel)' => 1,
                '_(()_())' => 1, '(()_())_' => 1,
                '_()_()' => 1, '()_()_' => 1    
            }
        end

        if @feature_on[:context2]
            features_context2 = Array.new 
            Connectives.each {|c| features_context2 << "prev_conn="+c.gsub(/ /,'_')}
            features_context2 << 'prev_conn=Implicit'
            Connectives.each {|c| features_context2 << "next_conn="+c.gsub(/ /,'_')}
            features_context2 << 'next_conn=Implicit'
        end

        if @feature_on[:conn]
            @features_conn = Array.new
            Connectives.each {|c| features_conn << "curr_conn="+c.gsub(/ /,'_')}
        end

        if @feature_on[:genre]
            @features_genre = Hash.new
            File.open(File.dirname(__FILE__)+'/../lib/genre.txt', 'r') {|f|
                while line = f.gets
                    line2 = f.gets
                    line.chomp!
                    line2.chomp.split.each {|e|
                        @features_genre[e] = line
                    }
                end
            }
        end
    end

    def prepare_data(prefix, train_only=false)
        if train_only then
            output_files = [File.dirname(__FILE__)+'/../data/'+prefix+'.train']
        else
            output_files = [File.dirname(__FILE__)+'/../data/'+prefix+'.train', 
                File.dirname(__FILE__)+'/../data/'+prefix+'.test',
                File.dirname(__FILE__)+'/../data/'+prefix.sub(/\.nep\./, '.ep.')+'.test',
                File.dirname(__FILE__)+'/../data/'+prefix.sub(/\.nep\./, '.ep.').sub(/\.npp$/, '.pp')+'.test',
                #File.dirname(__FILE__)+'/../data/'+prefix+'.dev',
            ]
        end

        which2 = 'disc-adj'

        class_attr_in_train = Hash.new
        Level_2_types.each {|t| class_attr_in_train[t] = false}

        cnt_tmp = Hash.new(0)
        output_files.each do |filename|
            #print_feature = filename.match(/test/) ? true : false;

            to_file = File.open(filename, 'w')

            if filename.match(/train/)
                which = 'train'
                some_sections = $train_data
            elsif filename.match(/test/)
                which = 'test'
                some_sections = $test_data
                if filename.match(/\.ep\./)
                    $error_propagate = true
                end
                if filename.match(/\.pp/) then 
                    $with_preprocess = true 
                end
            else 
                which = 'dev'
                some_sections = Variable::Dev_data
            end

            reset_files

            if which == 'test' and $error_propagate then
                argpos_res = File.readlines($argpos_res_file) .map {|e| e.chomp.split.last}
                argext_res = File.readlines($argext_res_file) .map {|e| e.chomp}
                exp_res = File.readlines($exp_res_file) .map {|e| e.chomp}
                f2 = File.open(filename+'.f2', 'w')
                arg_ext_f1 = File.open(filename+'.argext.f1', 'w')
                arg_ext_f2 = File.open(filename+'.argext.f2', 'w')
            end

            if $with_preprocess then
                $arg_ext_f1_hsh = Hash.new
                File.readlines(filename.sub(/\.pp/, '.npp')+'.argext.f1').each {|l|
                    l.chomp!
                    next if /xxxxx ## xxxxx/.match(l)
                    tmp = l.split(' ## ')
                    tmp2 = tmp.last.split(' !! ')
                    if tmp2[1] != nil then
                        $arg_ext_f1_hsh[tmp2[0]] = [tmp[0], tmp[1], tmp2[1]]
                    end
                }
            end

            expected_filename = ''
            if which == 'test'
                expected_filename = filename+'.expected'
                expected_file = File.open(expected_filename, 'w')
            else
                expected_file = nil
            end

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
                    puts "  article: "+article.id
                    if which == 'test' and $error_propagate then
                        print_features2(article, to_file, which, f2, expected_file, nil, argpos_res, argext_res, exp_res, arg_ext_f1, arg_ext_f2)
                    else
                        print_features(article, to_file, expected_file, which, which2)
                    end
                end
            end

            if which == 'test' and $error_propagate then
                f2.close
                arg_ext_f1.close
                arg_ext_f2.close
            end
            expected_file.close if which == 'test'
            to_file.close
        end
    end

    def print_features2(article, to_file, which, f2, expected_file, conn_res, argpos_res, argext_res, exp_res, arg_ext_f1, arg_ext_f2)
        #STDERR.puts 'print imp features...'

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
        else
            #article.flag_disc_connectives(conn_res)
            #article.label_arguments(argext_res)
            #disc_connectives = article.disc_connectives_p
            #article.label_exp_relations_types2(2, exp_res)
            #exp_relations = article.exp_relations_p
        end

        tags = Variable::Verb_tags + %w/RB UH/
        article.paragraphs.each {|paragraph|
            0.upto(paragraph.length - 2) {|i|
                sentence1 = paragraph.sentences[i]
                sentence2 = paragraph.sentences[i+1]

                if which != 'parse' then
                arg_ext_f2.puts sentence1.leaves.map {|l| l.article_order.to_s+'_'+l.up.v+'_'+l.v} .join(' ') + ' ## ' +
                    sentence2.leaves.map {|l| l.article_order.to_s+'_'+l.up.v+'_'+l.v} .join(' ') + ' ## '
                if $with_preprocess then
                    tmp = $arg_ext_f1_hsh[article.id.to_s + ' ' + paragraph.id.to_s + ' ' + i.to_s]
                    if tmp == nil then
                        types = ['xxxxx']
                        arg_ext_f1.puts 'xxxxx ## ' + 'xxxxx ## ' 
                    else
                        types = tmp.last.split
                        arg_ext_f1.puts tmp[0] + ' ## ' + tmp[1] + ' ## '  
                    end
                    #t = article.nonexp_hsh[sentence1.id]
                    #if t != nil then
                    #    types = t
                    #else
                    #    types = ['xxxxx']
                    #end
                else
                    if (relation = paragraph.has_nonexp_relation?(i)) != false then 
                        if relation[1] == "Implicit" or relation[1] == "AltLex" then
                            types = relation.level_2_types
                            types.each {|t|
                                if not Variable::Level_2_types.include?(t) then
                                    types.delete(t)
                                end
                            }
                            types.uniq!
                        elsif relation[1] == "EntRel"
                            types = ['EntRel']
                        elsif relation[1] == "NoRel"
                            types = ['NoRel']
                        end

                        arg_ext_f1.puts relation.arg1_leaves.map {|l| l.article_order.to_s+'_'+l.up.v+'_'+l.v} .join(' ') + ' ## ' +
                            relation.arg2_leaves.map {|l| l.article_order.to_s+'_'+l.up.v+'_'+l.v} .join(' ') + ' ## ' + 
                            article.id.to_s + ' ' + paragraph.id.to_s + ' ' + i.to_s + ' !! ' + types.join(' ')
                    else
                        relation = nil
                        types = ['xxxxx']
                        arg_ext_f1.puts 'xxxxx ## ' + 'xxxxx ## ' 
                    end
                end

                f2.print article.id.to_s+' '+paragraph.id.to_s+' ' 
                if paragraph.has_exp_relation?(i) then
                    f2.puts 'exp'
                    next
                else
                    f2.puts 'non-exp'
                end

                if relation != nil or $with_preprocess then
                    types.each do |type|
                        expected_file.print type+' '
                    end
                    expected_file.puts "%%% Implicit "+article.filename
                else
                    expected_file.print 'xxxxx '
                    expected_file.puts "%%% Implicit "+article.filename
                end
                end

                if paragraph.has_exp_relation?(i) then
                    next
                else
                    article.add_nonexp_relation(sentence1, sentence2)
                end

                #prev_rel = relation.prev_rel
                #next_rel = relation.next_rel


                to_file_line = ''

                ##############
                if @feature_on[:prule]
                    arg1_features = sentence1.get_production_rules(-1, true).keys.map {|e| e.gsub(/ /, '_')}
                    arg2_features = sentence2.get_production_rules(-1, true).keys.map {|e| e.gsub(/ /, '_')}

                    args_features = (arg1_features + arg2_features).uniq
                    @features_prule.sort {|a,b| b[1] <=> a[1]} .each {|k,v|
                        next if not args_features.include?(k)

                        a1 = arg1_features.include?(k)
                        a2 = arg2_features.include?(k)
                        if a1
                            to_file_line += k+":1 "
                        end
                        if a2
                            to_file_line += k+":2 "
                        end
                        if a1 and a2
                            to_file_line += k+":12 "
                        end
                    }
                end
                
                ##############
                if @feature_on[:drule]
                    arg1_features = sentence1.get_dependency_rules(-1, false, true, false).keys.map {|e| e.gsub(/ /, '_')}
                    arg2_features = sentence2.get_dependency_rules(-1, false, true, false).keys.map {|e| e.gsub(/ /, '_')}
                    args_features = (arg1_features + arg2_features).uniq
                    @features_drule.sort {|a,b| b[1] <=> a[1]} .each {|k,v|
                        next if not args_features.include?(k)

                        a1 = arg1_features.include?(k)
                        a2 = arg2_features.include?(k)
                        if a1
                            to_file_line += k+":1 "
                        end
                        if a2
                            to_file_line += k+":2 "
                        end
                        if a1 and a2
                            to_file_line += k+":12 "
                        end
                    }
                end

                ##############
                if @feature_on[:word_pair]
                    #pairs = relation.word_pair([25, 32, 45], [35, 42, 48])
                    #pairs = relation.word_pair2
                    #text1 = Relation.normalize_time_patterns(Relation.normalize_number_patterns(relation.arg1s['lemmatized'])).split
                    #text2 = Relation.normalize_time_patterns(Relation.normalize_number_patterns(relation.arg2s['lemmatized'])).split
                    text1 = sentence1.stemmed_text.split
                    text2 = sentence2.stemmed_text.split
                    pairs = Array.new
                    text1.each {|w1|
                        text2.each {|w2|
                            pairs << w1+'_'+w2
                        }
                    }
                    pairs = pairs & @features_wp
                    pairs.each {|e|
                        to_file_line += e+" "
                    }
                end

                ###############
                #if @feature_on[:genre]
                    #if features_genre.has_key?(article.id)
                        #to_file_line += 'genre='+@features_genre[article.id]+' '
                    #end
                #end
#
                ##############
                if @feature_on[:arg2_word]
                    phrase_len = 3
                    #ary = relation[35].downcase.split
                    ary = sentence2.leaves.map {|l| l.v.downcase} 
                    ary[0,phrase_len].each {|e| to_file_line += 'arg2_start_uni_'+e+' '}
                end
#
                
                to_file.puts to_file_line+'xxxxx'
            }
        }
    end

    def print_features(article, to_file, expected_file, which, which2)
        article.relations.each do |relation|
            next if relation[1] != "Implicit" and relation[1] != "AltLex" and 
                relation[1] != "EntRel" and relation[1] != "NoRel"  

            sid1 = relation.arg1_leaves.last.goto_tree.sent_id
            sid2 = relation.arg2_leaves.first.goto_tree.sent_id

            prev_rel = relation.prev_rel
            next_rel = relation.next_rel

            if which2 == 'disc-imp'
                types = relation.level_2_types
                types.each do |t|
                    if not Level_2_types.include?(t)
                        types.delete(t)
                    end
                end
                types.uniq!
            elsif which2 == 'disc-rel'
                if relation[1] == "Implicit" or relation[1] == "AltLex"
                    types = ['disc-rel']
                else
                    types = ['non-disc-rel']
                end
            elsif which2 == 'disc-adj'
                if relation[1] == "Implicit" or relation[1] == "AltLex"
                    types = relation.level_2_types
                    types.each {|t|
                        if not Level_2_types.include?(t)
                            types.delete(t)
                        end
                    }
                    types.uniq!
                elsif relation[1] == "EntRel"
                    types = ['EntRel']
                elsif relation[1] == "NoRel"
                    types = ['NoRel']
                end
            end

            #types = relation.level_2_types
            #types = types.select {|t| Level_2_types.include?(t)} .uniq
            #types.map! {|t| t.gsub(/ /, '_')}
            #types.uniq!

            to_file_line = ''

            ##############
            if @feature_on[:prule]
                arg1_features = relation.get_production_rules(%w/arg1/, -1, true).keys.map {|e| e.gsub(/ /, '_')}
                arg2_features = relation.get_production_rules(%w/arg2/, -1, true).keys.map {|e| e.gsub(/ /, '_')}

                args_features = (arg1_features + arg2_features).uniq
                @features_prule.sort {|a,b| b[1] <=> a[1]} .each {|k,v|
                    next if not args_features.include?(k)

                    a1 = arg1_features.include?(k)
                    a2 = arg2_features.include?(k)
                    if a1
                        to_file_line += k+":1 "
                    end
                    if a2
                        to_file_line += k+":2 "
                    end
                    if a1 and a2
                        to_file_line += k+":12 "
                    end
                }
            end
            
            ##############
            if @feature_on[:drule]
                arg1_features = relation.get_dependency_rules(%w/arg1/, -1, false, true, false).keys.map {|e| e.gsub(/ /, '_')}
                arg2_features = relation.get_dependency_rules(%w/arg2/, -1, false, true, false).keys.map {|e| e.gsub(/ /, '_')}
                args_features = (arg1_features + arg2_features).uniq
                @features_drule.sort {|a,b| b[1] <=> a[1]} .each {|k,v|
                    next if not args_features.include?(k)

                    a1 = arg1_features.include?(k)
                    a2 = arg2_features.include?(k)
                    if a1
                        to_file_line += k+":1 "
                    end
                    if a2
                        to_file_line += k+":2 "
                    end
                    if a1 and a2
                        to_file_line += k+":12 "
                    end
                }
            end

            ##############
            if @feature_on[:word_pair]
                #pairs = relation.word_pair([25, 32, 45], [35, 42, 48])
                #pairs = relation.word_pair2
                #text1 = Relation.normalize_time_patterns(Relation.normalize_number_patterns(relation.arg1s['lemmatized'])).split
                #text2 = Relation.normalize_time_patterns(Relation.normalize_number_patterns(relation.arg2s['lemmatized'])).split
                text1 = relation.arg1s['stemmed'].split
                text2 = relation.arg2s['stemmed'].split
                pairs = Array.new
                text1.each {|w1|
                    text2.each {|w2|
                        pairs << w1+'_'+w2
                    }
                }
                pairs = pairs & @features_wp
                pairs.each {|e|
                    to_file_line += e+" "
                }
            end

            ##############
            if @feature_on[:genre]
                if features_genre.has_key?(article.id)
                    to_file_line += 'genre='+@features_genre[article.id]+' '
                end
            end

            ##############
            if @feature_on[:arg2_word]
                phrase_len = 3
                ary = relation[35].downcase.split
                ary[0,phrase_len].each {|e| to_file_line += 'arg2_start_uni_'+e+' '}
            end

            ##############
            if @feature_on[:context]
                arr = Array.new
                if relation.embed_rel_in_arg1?(prev_rel)
                    arr << '(rel)_()'
                end
                if relation.embed_rel_in_arg2?(next_rel)
                    arr << '()_(rel)'
                end
                if prev_rel != nil and prev_rel.embed_rel_in_arg2?(relation)
                    arr << '_(()_())'
                end
                if next_rel != nil and next_rel.embed_rel_in_arg1?(relation)
                    arr << '(()_())_'
                end
                if prev_rel != nil and prev_rel.share_argument?(relation)
                    arr << '_()_()'
                end
                if relation.share_argument?(next_rel)
                    arr << '()_()_'
                end

                arr.uniq!
                arr.each {|a| a.gsub!(/ /, '_')}

                arr.each {|a|
                    to_file_line += a+" "
                }
            end

            ##############
            if @feature_on[:context2]
                if prev_rel == nil
                    #prev_conn = 'prev_conn=nil'
                elsif prev_rel[1] == 'Implicit' 
                    to_file_line += 'prev_conn=Implicit ' 
                elsif prev_rel[1] == 'Explicit'
                    to_file_line += 'prev_conn='+prev_rel.discourse_connectives.first.gsub(/ /,'_')+' '
                else
                    #prev_conn = 'prev_conn=nil'
                end

                if next_rel == nil
                    #next_conn = 'next_conn=nil'
                elsif next_rel[1] == 'Implicit' 
                    to_file_line += 'next_conn=Implicit ' 
                elsif next_rel[1] == 'Explicit'
                    to_file_line += 'next_conn='+next_rel.discourse_connectives.first.gsub(/ /,'_')+' '
                else
                    #next_conn = 'next_conn=nil'
                end
            end
            
            if relation[1] == 'Explicit'
                if @feature_on[:conn]
                    conn = relation[9].downcase.gsub(/ /, '_')
                    @features_conn.each {|f|
                        if f == "curr_conn=" + conn
                            to_file_line += 'y,'
                        else
                            to_file_line += 'n,'
                        end
                    }
                end
                if which == 'train'
                    types.each do |type|
                        if Level_2_types_full.include?(type)
                            to_file.puts to_file_line+type+" \t%%% Explicit "+article.filename+' '+relation.id.to_s
                            class_attr_in_train[type] = true
                        end
                    end
                else
                    type = types[0]
                    if Level_2_types_full.include?(type)
                        to_file.puts to_file_line+type+" \t%%% Explicit "+article.filename+' '+relation.id.to_s
                    end
                    types.each do |type|
                        if Level_2_types_full.include?(type)
                            expected_file.print type+' '
                        end
                    end
                    expected_file.puts "%%% Explicit "+article.filename+' '+relation.id.to_s
                end
            else #if relation[1] == 'Implicit'
                if types != []
                    if which == 'train'
                        types.each do |type|
                            to_file.puts to_file_line+type #+" \t%%% Implicit "+article.filename+' '+relation.id.to_s
                        end
                    else
                        type = types[0]
                        to_file.puts to_file_line+type #+" \t%%% Implicit "+article.filename+' '+relation.id.to_s
                        types.each do |type|
                            expected_file.print type+' '
                        end
                        expected_file.puts "%%% Implicit "+article.filename+' '+relation.id.to_s
                    end
                end
            end
        end
    end

end
