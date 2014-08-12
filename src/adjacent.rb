require 'corpus'

class Adjacent < Corpus
    def prepare_train_test_data(prefix, num_prule, num_drule, num_wp, use_context)
        feature_on = {
            :rule => true,                          # production rule 
            :dtree => true,                         # dependency rule
            :word_pair => true,                     # word pair
            :context => true, :context2 => true,    # word pair
            :conn => false,                         # connective
            :genre => true,                         # genre
        }
        feature_on[:rule] = false if num_prule == 0
        feature_on[:dtree] = false if num_drule == 0
        feature_on[:word_pair] = false if num_wp == 0
        if use_context == false
            feature_on[:context] = false
            feature_on[:context2] = false
        end

        if feature_on[:rule]
            features_rule = Hash.new
            f = File.open(PRULE_FILE, 'r')
            count = 0
            while line = f.gets
                break if count == num_prule      #11_113  
                line.chomp!
                tokens = line.split
                rule = tokens[0]
                if not features_rule.has_key?(rule)
                    features_rule[rule] = tokens.last.to_f
                    count += 1
                end
            end
            f.close
        end

        if feature_on[:dtree]
            features_dtree = Hash.new
            f = File.open(DRULE_FILE, 'r')
            count = 0
            while line = f.gets
                break if count == num_drule
                line.chomp!
                tokens = line.split
                rule = tokens[0]
                if not features_dtree.has_key?(rule)
                    features_dtree[rule] = tokens.last.to_f
                    count += 1
                end
            end
            f.close
        end

        if feature_on[:word_pair]
            features2 = Hash.new
            f = File.open(WORDPAIR_FILE, 'r')
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
            features_wp = features2.keys
        end

        if feature_on[:context]
            features_context = {
                '(rel)_()' => 1, '()_(rel)' => 1,
                '_(()_())' => 1, '(()_())_' => 1,
                '_()_()' => 1, '()_()_' => 1    
            }
        end

        if feature_on[:context2]
            features_context2 = Array.new 
            Connectives.each {|c| features_context2 << "prev_conn="+c.gsub(/ /,'_')}
            features_context2 << 'prev_conn=Implicit'
            Connectives.each {|c| features_context2 << "next_conn="+c.gsub(/ /,'_')}
            features_context2 << 'next_conn=Implicit'
        end

        if feature_on[:conn]
            features_conn = Array.new
            Connectives.each {|c| features_conn << "curr_conn="+c.gsub(/ /,'_')}
        end

        if feature_on[:genre]
            features_genre = Hash.new
            File.open('../lib/genre.txt', 'r') {|f|
                while line = f.gets
                    line2 = f.gets
                    line.chomp!
                    line2.chomp.split.each {|e|
                        features_genre[e] = line
                    }
                end
            }
        end

        conns = Connectives

        cnt_tmp = Hash.new(0)
        ['../data/'+prefix+'.train', 
            '../data/'+prefix+'.test',
            #'../data/'+prefix+'.dev',
        ].each do |filename|
            
            print_feature = filename.match(/test/) ? true : false;
            is_train = filename.match(/train/) ? true : false;

            expected_filename = ''
            if not is_train
                expected_filename = filename.match(/test/) ? '../data/'+prefix+'.test.expected' : '../data/'+prefix+'.dev.expected'
                expected_file = File.open(expected_filename, 'w')
            end

            to_file = File.open(filename, 'w')
            count = 1

            if filename.match(/train/)
                some_sections = @train_data
            elsif filename.match(/test/)
                some_sections = @test_data
            else 
                some_sections = @dev_data
            end

            some_sections.each do |section_id|
                section = Section.new(section_id, PDTB_DIR+"/"+section_id.to_s,
                                PTB_DIR+"/"+section_id.to_s, DTREE_DIR+"/"+section_id.to_s)
                puts "section: "+section.section_id
                section.articles.each do |article|
                    puts "  article: "+article.id
                    article.relations.each do |relation|
                        next if relation[1] != "Implicit" and relation[1] != "AltLex" and relation[1] != "EntRel" and relation[1] != "NoRel"  

                        prev_rel = relation.prev_rel
                        next_rel = relation.next_rel

                        if which == 'disc-imp'
                            types = relation.level_2_types
                            types.each do |t|
                                if not Level_2_types.include?(t)
                                    types.delete(t)
                                end
                            end
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

                        #types = relation.level_2_types
                        #types = types.select {|t| Level_2_types.include?(t)} .uniq
                        #types.map! {|t| t.gsub(/ /, '_')}
                        #types.uniq!

                        to_file_line = ''

                        ##############
                        if feature_on[:rule]
                            arg1_features = relation.get_production_rules(%w/arg1/, -1, true).keys.map {|e| e.gsub(/ /, '_')}
                            arg2_features = relation.get_production_rules(%w/arg2/, -1, true).keys.map {|e| e.gsub(/ /, '_')}

                            args_features = (arg1_features + arg2_features).uniq
                            features_rule.sort {|a,b| b[1] <=> a[1]} .each {|k,v|
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
                        if feature_on[:dtree]
                            arg1_features = relation.get_dependency_rules(%w/arg1/, -1, false, true, false).keys.map {|e| e.gsub(/ /, '_')}
                            arg2_features = relation.get_dependency_rules(%w/arg2/, -1, false, true, false).keys.map {|e| e.gsub(/ /, '_')}
                            args_features = (arg1_features + arg2_features).uniq
                            features_dtree.sort {|a,b| b[1] <=> a[1]} .each {|k,v|
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
                        if feature_on[:word_pair]
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
                            pairs = pairs & features_wp
                            pairs.each {|e|
                                to_file_line += e+" "
                            }
                        end

                        ##############
                        if feature_on[:genre]
                            if features_genre.has_key?(article.id)
                                to_file_line += 'genre='+features_genre[article.id]+' '
                            end
                        end

                        ##############
                        if feature_on[:context]
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
                        if feature_on[:context2]
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
                            if feature_on[:conn]
                                conn = relation[9].downcase.gsub(/ /, '_')
                                features_conn.each {|f|
                                    if f == "curr_conn=" + conn
                                        to_file_line += 'y,'
                                    else
                                        to_file_line += 'n,'
                                    end
                                }
                            end
                            if is_train
                                types.each do |type|
                                    if Level_2_types_full.include?(type)
                                        to_file.puts to_file_line+type+" \t%%% Explicit "+article.filename+' '+relation.id.to_s
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
                                if is_train
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
            expected_file.close if not is_train
            to_file.close
        end
    end
end
