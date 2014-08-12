#require File.dirname(__FILE__)+'/../lib/utils'
require File.dirname(__FILE__)+'/paragraph'
require File.dirname(__FILE__)+'/sentence'
require File.dirname(__FILE__)+'/relation'
require File.dirname(__FILE__)+'/tree'


class Article
    attr_accessor :filename, :pdtb_file, :ptb_file, :dtree_file, :id, :set_id,
        :edus, :edu_lengths, :edu_marked, :edu_in_relation, :edu_ary, :edu_nodes,
        :clauses, :clause_marked, :clause_in_relation, :clause_in_p_relation,
        :attr_edus, :attr_clauses,
        :paragraphs, :sentences, :leaves,
        :disc_connectives, :disc_connectives_p, 
        :long_disc_connectives,
        :exp_relations, :exp_relations_p,
        :nonexp_relations, :nonexp_relations_p,
        :disc_relations_p,
        :exp_level_1_types_p, :exp_level_2_types_p,
        :nonexp_level_1_types_p, :nonexp_level_2_types_p,
        :relations, :parsed_trees, :sid2tree, :length, :nonexp_hsh,
        :parsed_text, :rel_texts

    SPADE_BIN = '/home/linzihen/tools/SPADE/bin/'

    def initialize(filename, pdtb_file, ptb_file, dtree_file='', para_file='', lmt_file='', is_parse=false, replace_nil=true)
        @filename = filename
        @id = @filename.sub(/\.pipe/, '')
        @filename.match(/wsj_(\d\d)/)
        @set_id = $1
        @pdtb_file = pdtb_file
        @ptb_file = ptb_file
        @dtree_file = dtree_file
        @edus = Array.new
        @edu_lengths = Array.new
        @edu_marked = Array.new
        @edu_in_relation = Array.new
        @edu_ary = Array.new
        @edu_nodes = Array.new
        @clauses = Array.new
        @clause_marked = Array.new
        @clause_in_relation = Array.new
        @clause_in_p_relation = Array.new
        @attr_edus = Array.new
        @attr_clauses = Array.new
        @relations = Array.new
        @parsed_trees = Array.new
        @sid2tree = Hash.new
        @paragraphs = Array.new
        @sentences = Array.new
        @leaves = Array.new
        @disc_connectives = Array.new
        @disc_connectives_p = Array.new
        @long_disc_connectives = Array.new
        @exp_relations = Array.new
        @exp_relations_p = Array.new
        @nonexp_relations = Array.new
        @nonexp_relations_p = Array.new
        @disc_relations_p = Array.new
        @exp_level_1_types_p = Array.new
        @exp_level_2_types_p = Array.new
        @nonexp_level_1_types_p = Array.new
        @nonexp_level_2_types_p = Array.new
        @read_parse = true
        @process_attr = true
        @nonexp_hsh = Hash.new
        @parsed_text = nil
        @rel_texts = nil

        #puts "===================="+@filename+"===================="
        read_parsed_trees() if @read_parse
        read_dtrees(replace_nil) if @read_parse 
        @length = @parsed_trees.size

        file = File.new(pdtb_file, "r") if not is_parse
        count = 0

        if not $with_preprocess and not is_parse
        prev_rel = nil
        while line = file.gets #and line2 = lmt_file.gets
            count += 1
            line = line.chomp
            rel = Relation.new(line, count)
            rel.article = self
            @relations.push(rel)
            if prev_rel != nil
                rel.prev_rel = prev_rel
                prev_rel.next_rel = rel
            end

            rel.attrs['gorn_addr']  = rel[21]
            rel.arg1s['gorn_addr']  = rel[24]
            rel.attr1s['gorn_addr'] = rel[31]
            rel.sup1s['gorn_addr']  = rel[44]
            rel.arg2s['gorn_addr']  = rel[34]
            rel.attr2s['gorn_addr'] = rel[41]
            rel.sup2s['gorn_addr']  = rel[47]
            if @read_parse
                rel.long_conn_leaves = []
                gorns2nodes(rel[5]).each {|n| rel.long_conn_leaves += n.my_leaves}
                rel.attrs['parsed_tree']  = gorns2nodes(rel.attrs['gorn_addr'])
                rel.arg1s['parsed_tree']  = gorns2nodes(rel.arg1s['gorn_addr'])
                rel.arg2s['parsed_tree']  = gorns2nodes(rel.arg2s['gorn_addr'])
                rel.attr1s['parsed_tree'] = gorns2nodes(rel.attr1s['gorn_addr'])
                rel.attr2s['parsed_tree'] = gorns2nodes(rel.attr2s['gorn_addr'])
                rel.sup1s['parsed_tree']  = gorns2nodes(rel.sup1s['gorn_addr'])
                rel.sup2s['parsed_tree']  = gorns2nodes(rel.sup2s['gorn_addr'])
                rel.alls['parsed_tree'] = gorns2roots(rel.arg1s['gorn_addr']+";"+rel.arg2s['gorn_addr'])
            end
            
            rel.mark_attribution_spans if @read_parse and @process_attr

            rel.get_arg_leaves
            rel.get_sup_leaves

            if rel[1] == 'Explicit' then
                rel.get_connective_leaves
                @disc_connectives.push(rel.conn_leaves)
                @long_disc_connectives.push(rel.long_conn_leaves)
                @exp_relations.push(rel)
            else 
                @nonexp_relations.push(rel)
            end
            prev_rel = rel
        end
        end


        @disc_connectives.uniq!

        @disc_connectives.each {|conn_leaves|
            sid = conn_leaves[0].goto_tree.sent_id
            @sentences[sid].disc_connectives.push(conn_leaves)
            #conn_leaves[1...conn_leaves.size].each {|l|
                #sid2 = l.goto_tree.sent_id
                #if sid2 != sid
                    #@sentences[sid2].disc_connectives.push(conn_leaves)
                #end
            #}
        }

        file.close if file != nil
 
        @sentences.each {|sentence|
            sentence.clauses.each {|clause|
                @clauses.push(clause)
            }
        }

        if not is_parse then
            if ptb_file.match(/charniak/) then
                nonexp_file = ptb_file.sub(/charniak/, 'nonexp').sub(/mrg$/, 'nonexp')
                File.readlines(nonexp_file).each {|l|
                    t = l.chomp.split
                    @nonexp_hsh[t.shift.to_i] = t
                }
            end
        end

        if not is_parse then
            lmt_file = ptb_file.match(/combined/) ? 
                ptb_file.sub(/combined/, 'lemmatized').sub(/mrg$/, 'lmt') :
                ptb_file.sub(/charniak/, 'lemmatized2').sub(/mrg$/, 'lmt') 
            lmt_lines = File.readlines(lmt_file).map {|l| l.strip}
            @parsed_trees.each_index {|i|
                words = lmt_lines[i].split(/ /)
                curr = @parsed_trees[i].root.first_leaf
                begin
                    curr.lemmatized = words.shift
                end while curr = curr.next_leaf
            }
        end

        if not is_parse then
            para_file = ptb_file.match(/combined/) ? 
                ptb_file.sub(/combined/, 'paragraphed').sub(/mrg$/, 'para') :
                ptb_file.sub(/charniak/, 'paragraphed2').sub(/mrg$/, 'para')
            ary = File.readlines(para_file).map {|l| l.chomp.to_i}
            ary.push(@sentences.size)
            0.upto(ary.size - 2) {|i|
                para = Paragraph.new(@sentences, ary[i], ary[i+1], i)
                para.article = self
                @paragraphs.push(para)
            }
        else
            if para_file == '' then
                para_file = ptb_file.sub(/mrg$/, 'para') 
            end
            if lmt_file != '' then
                lmt_lines = File.readlines(lmt_file).map {|l| l.strip}
                @parsed_trees.each_index {|i|
                    words = lmt_lines[i].split(/ /)
                    curr = @parsed_trees[i].root.first_leaf
                    begin
                        curr.lemmatized = words.shift
                    end while curr = curr.next_leaf
                }
            end
            ary = File.readlines(para_file).map {|l| l.chomp.to_i}
            ary.push(@sentences.size)
            0.upto(ary.size - 2) {|i|
                para = Paragraph.new(@sentences, ary[i], ary[i+1], i)
                para.article = self
                @paragraphs.push(para)
            }
        end

        label_leaf_article_order
        label_node_size

        #ner_file = ptb_file.sub(/combined/, 'ner').sub(/mrg$/, 'ner')
        #ner_lines = File.readlines(ner_file).map {|l| l.strip}
        #ner_lines.shift
        #ner_lines.shift
        #@parsed_trees.each_index {|i|
            #curr = @parsed_trees[i].root.first_leaf
            #begin
                #tokens = ner_lines.shift.split
                #curr.ner_value = tokens.last
            #end while curr = curr.next_leaf
            #ner_lines.shift
        #}

    end

    def [](i)
        @relations[i-1]
    end

    def get_exp_relation(conn_leaves)
        @exp_relations.each do |rel|
            if rel.conn_leaves == conn_leaves then
                return rel
            end
        end
        nil
    end

    def find_DSOZ
        in_DSOZ = false
        new_DSOZ = nil
        all_DSOZ = Array.new
        sent2DSOZ = Hash.new
        @sentences.each_index do |i|
            sentence = @sentences[i]
            if not in_DSOZ then
                if sentence.leaves.first.v == "``" then
                    in_DSOZ = true
                    new_DSOZ = Array.new
                    new_DSOZ << sentence
                    sent2DSOZ[sentence.id] = new_DSOZ
                end
            end

            if in_DSOZ then
                if not new_DSOZ.include?(sentence) then
                    new_DSOZ << sentence
                    sent2DSOZ[sentence.id] = new_DSOZ
                end
                last_in_DSOZ = false
                sentence.leaves.each {|l| if l.v == "''" then last_in_DSOZ = true; break end}
                if last_in_DSOZ then
                    in_DSOZ = false
                    all_DSOZ << new_DSOZ
                end
            end
        end
        [all_DSOZ, sent2DSOZ]
    end

    def find_POZ
        in_POZ = false
        new_POZ = nil
        all_POZ = Array.new
        sent2POZ = Hash.new
        @sentences.each_index do |i|
            sentence = @sentences[i]
            if not in_POZ then
                if sentence.leaves.first.v == "-LRB-" then
                    in_POZ = true
                    new_POZ = Array.new
                    new_POZ << sentence
                    sent2POZ[sentence.id] = new_POZ
                end
            end

            if in_POZ then
                if not new_POZ.include?(sentence) then
                    new_POZ << sentence
                    sent2POZ[sentence.id] = new_POZ
                end
                last_in_POZ = false
                sentence.leaves.each {|l| if l.v == "-RRB-" then last_in_POZ = true; break end}
                if last_in_POZ then
                    in_POZ = false
                    all_POZ << new_POZ
                end
            end
        end
        [all_POZ, sent2POZ]
    end

    def position_in_para(sent)
        @paragraphs.each do |para|
            pos = para.sentences.index(sent)
            if pos != nil then
                return [para, pos]
            end
        end
        [nil, nil]
    end

    def get_relation_sequence
        hsh = Hash.new()
        @relations.each {|rel|
            arg1_sents = gorns2sentid(rel.arg1s['gorn_addr'])
            arg2_sents = gorns2sentid(rel.arg2s['gorn_addr'])
            senses = rel.senses_sf.join(' | ')
            s1 = arg1_sents.sort.last
            s2 = arg2_sents.sort.first
            if s1 == s2 then
                hsh["#{s1}"] = Array.new if not hsh.has_key?("#{s1}")
                hsh["#{s1}"].push([senses,rel])
            else
                hsh["#{s1} #{s2}"] = Array.new if not hsh.has_key?("#{s1} #{s2}")
                hsh["#{s1} #{s2}"].push([senses,rel])
            end
        }
        hsh.each {|k,v|
            if hsh[k].size > 1 then
                hsh[k].sort! {|a,b|
                    #a[1].conn_leaves.first.article_order <=> b[1].conn_leaves.first.article_order
                    a[1].arg2_leaves.last.article_order <=> b[1].arg2_leaves.last.article_order
                }
            end
        }
        seq = ''
        0.upto(@sentences.size-1) {|i|
            seq += '+ '
            print '+ '
            if hsh.has_key?(i.to_s) then
                seq += hsh[i.to_s].map {|ary| ary[0]} .join(' & ') + "\n"
                puts hsh[i.to_s].map {|ary| ary[0]} .join(' & ')
            else
                seq += "\n"
                puts
            end
            if i+1 <= @sentences.size-1 then
                seq += '| '
                print '| '
                if hsh.has_key?("#{i} #{i+1}") then
                    seq += hsh["#{i} #{i+1}"].map {|ary| ary[0]} .join(' & ') + "\n"
                    puts hsh["#{i} #{i+1}"].map {|ary| ary[0]} .join(' & ') 
                else
                    seq += "\n"
                    puts
                end
            end
        }
        seq
    end

    def label_attribution_spans(ary)
        edus2 = Array.new
        @edu_ary.each_index {|idx| 
            edus2.push(@edu_ary[idx]) if @edu_in_relation[idx]
        } 
        edus2.each_index {|i|
            @attr_edus.push(edus2[i]) if ary[i] == '1'
        }
    end

    def label_attribution_spans2(ary)
        #ary.each_index {|i|
            #puts i.to_s + ' ' + ary[i].to_s + ' ' +  @clause_in_p_relation[i].to_s + ' ' + @clauses[i].map {|l| l.v} .join(' ')
        #}
        #exit
        a_clauses = Array.new
        @clauses.each_index {|idx| 
            a_clauses.push(@clauses[idx]) if ary[idx] == '1' #and @clause_in_p_relation[idx]
        } 
        #@attr_clauses = a_clauses
        prev = a_clauses.shift if not a_clauses.empty?
        while not a_clauses.empty? do
            curr = a_clauses.shift
            if prev.last.next_leaf == curr.first then
                prev = prev + curr
            else
                @attr_clauses.push(prev)
                prev = curr
            end
        end
        if prev != nil then @attr_clauses.push(prev) end
        #@attr_clauses.each {|c|
            #puts c.map {|l| l.v} .join(' ')
        #}
        #exit
    end

    def process_attribution_clauses(which=nil)
        if which != 'parse'
            mark_in_relation        if @read_parse and @process_attr
        else
            mark_in_disc_relation   if @read_parse and @process_attr
        end
        mark_attribution_clauses   if @read_parse and @process_attr
    end

    def process_attribution_edus(which=nil)
        if which != 'parse'
            mark_in_relation        if @read_parse and @process_attr
        else
            mark_in_disc_relation   if @read_parse and @process_attr
        end
        edubreak                if @read_parse and @process_attr
        mark_attribution_edus   if @read_parse and @process_attr
    end

    def add_nonexp_relation(sentence1, sentence2)
        relation = Relation.new('|||||||||||||||||||||||||||||||||||||||||||||||', -1)
        relation.arg1s['parsed_tree'] = [sentence1.root]
        relation.arg2s['parsed_tree'] = [sentence2.root]
        relation.arg1_leaves = sentence1.leaves
        relation.arg2_leaves = sentence2.leaves
        relation.arg1_sid = sentence1.id
        relation.arg2_sid = sentence2.id
        @nonexp_relations_p.push(relation)
    end

    def split_paragraphs(pos_file, to_file)
        text = File.readlines(pos_file).join
        text = text.gsub(/\(/, '-LRB-').gsub(/\)/, '-RRB-').gsub(/\{/, '-LCB-').gsub(/\}/, '-RCB-')
        lid = 0
        paras = text.strip.sub(/\A======+/, '').sub(/======+\Z$/, '').strip.split(/======================================/)
        f = File.open(to_file, 'w')
        catch :OUTER do
            paras.each_index {|i|
                para = paras[i].strip
                ps = para.split.reject {|a| a == '[' or a == ']'}
                f.puts @leaves[lid].goto_tree.sent_id
                ps.each {|p|
                    w = p[0...p.rindex('/')]

                    puts w+"\t\t"+@leaves[lid].value
                    if w != @leaves[lid].value and @leaves[lid].value[-1, 1] != "."
                        puts 'error! '+@id.to_s
                        exit
                    end
                    lid += 1
                    throw :OUTER if @leaves[lid] == nil
                }
            }
        end
        f.close
    end

    def label_nonexp_types(level, ary)
        if level == 1
            nonexp_types = @nonexp_level_1_types_p
        elsif level == 2
            nonexp_types = @nonexp_level_2_types_p
        end

        @nonexp_relations_p.each_index {|i|
            nonexp_types[i] = ary[i]
            if ary[i] != 'EntRel' and ary[i] != 'NoRel'
                @disc_relations_p.push(@nonexp_relations_p[i])
            else
            end
        }
    end

    def label_exp_types(level, ary)
        if level == 1
            exp_types = @exp_level_1_types_p
        elsif level == 2
            exp_types = @exp_level_2_types_p
        end

        @disc_connectives_p.each_index {|i|
            exp_types[i] = ary[i]
            @disc_relations_p.push(@exp_relations_p[i])
        }
    end

    def label_exp_relations_types(ary)
        ary.each_index {|i|
            @exp_relations_p[i][12] = ary[i][0] 
            @exp_relations_p[i][13] = ary[i][1] if ary[i][1] != nil
        }
    end

    def label_exp_relations_types2(level, ary)
        if level == 2 then
            ary.each_index {|i|
                ary[i] = Variable::Level_2_to_1[ary[i]] + '.' + ary[i] if Variable::Level_2_to_1[ary[i]] != nil
            }
        end
        ary.each_index {|i|
            @exp_relations_p[i][12] = ary[i]
            if level == 2 then
                @exp_level_2_types_p[i] = ary[i]
            else
            end
        }
    end

    def label_nonexp_relation_type(level, sent1, sent2, type)
        relation = Relation.new('|||||||||||||||||||||||||||||||||||||||||||||||', -1)
        relation.arg1s['parsed_tree'] = [sent1.parsed_tree.root]
        relation.arg2s['parsed_tree'] = [sent2.parsed_tree.root]
        relation.arg1_leaves = sent1.leaves
        relation.arg2_leaves = sent2.leaves
        relation.arg1_sid = sent1.id
        relation.arg2_sid = sent2.id
        if level == 2 then
            type = Variable::Level_2_to_1[type] + '.' + type if Variable::Level_2_to_1[type] != nil
        end
        relation[12] = type
        @nonexp_relations_p.push(relation)
        if level == 2 then
            @nonexp_level_2_types_p.push(type)
        else
        end
        @disc_relations_p.push(relation) if type != 'EntRel' and type != 'NoRel'
    end

    def label_arguments(ary)
        @disc_connectives_p.each_index {|i|
            connective = @disc_connectives_p[i]

            conn_sids = Array.new
            conn_sids = [connective[0].goto_tree.sent_id]
            conn_str = connective[0].value
            check = false
            1.upto(connective.size - 1) {|j|
                if connective[j-1].next_leaf == connective[j]
                    conn_str += ' '+connective[j].value
                else
                    conn_str += '..'+connective[j].value
                    if not check and connective[j].goto_tree.sent_id != conn_sids.first
                        conn_sids.push(connective[j].goto_tree.sent_id)
                        check = true
                    end
                end
            }
            if Variable::Conn_group.include?(conn_str.downcase)
                conn_type = 'group'
            elsif Variable::Conn_intra.include?(conn_str.downcase)
                conn_type = 'intra'
            else
                conn_type = 'inter'
            end

            if conn_sids.size > 1
                puts 'conn in two sentences'
                exit
            end

            #label = ary[i]
            #puts connective.map {|l| l.value} .join(' ') + ' ' +label 
            #arg1_sid = arg2_sid = -1
            #if label == 'IPS'
                #arg1_sid = conn_sids.first - 1
                #arg2_sid = conn_sids.first
                #arg1_leaves = @sentences[arg1_sid].leaves
                #arg2_leaves = @sentences[conn_sids.first].leaves - connective
            #elsif label == 'NAPS'
                #arg1_sid = conn_sids.first - 2
                #arg2_sid = conn_sids.first
                #arg1_leaves = @sentences[arg1_sid].leaves
                #arg2_leaves = @sentences[conn_sids.first].leaves - connective
            #elsif label == 'SS_1<2'
                #clauses = @sentences[conn_sids.first].break_with(connective)
                #arg1_sid = arg2_sid = conn_sids.first
                #arg2_leaves = clauses.pop
                #arg1_leaves = clauses.flatten
            #elsif label == 'SS_2<1'
                #arg1_leaves, arg2_leaves = @sentences[conn_sids.first].break_with2(connective)
                #arg1_sid = arg2_sid = conn_sids.first
                #if arg1_leaves.size == 0 or arg2_leaves.size == 0
                    #arg1_leaves, arg2_leaves = @sentences[conn_sids.first].break_with2(connective, true)
                #end
            #end

            tmp = ary[i].split(' ## ')
            ttt = tmp.last.split
            ttt.shift
            ttt.shift
            conn1 = ttt.join(' ')
            if conn1 != conn_str
                puts 'error in labeling arguments: connective not matched'
                puts conn1
                puts conn_str
                exit
            end
            arg1_leaves = Array.new
            tmp[0].split.each {|e|
                ws = e.split('_')
                l = @leaves[ws[0].to_i - 1]
                if l.v == ws[2] and l.up.v == ws[1] then
                    arg1_leaves.push(l)
                else
                    puts 'error in labeling arguments'
                    #pp ws
                    puts l.v+' '+l.up.v
                    exit
                end
            }
            arg2_leaves = Array.new
            tmp[1].split.each {|e|
                ws = e.split('_')
                l = @leaves[ws[0].to_i - 1]
                if l.v == ws[2] and l.up.v == ws[1] then
                    arg2_leaves.push(l)
                else
                    puts 'error in labeling arguments'
                    #pp ws
                    puts l.v+' '+l.up.v
                    exit
                end
            }
            if not (arg1_leaves - arg2_leaves - connective) == [] then
                arg1_leaves = arg1_leaves - arg2_leaves - connective
            end
            if not (arg2_leaves - arg1_leaves - connective) == [] then 
                arg2_leaves = arg2_leaves - arg1_leaves - connective
            end
            if not (arg2_leaves - connective) == [] then
                arg2_leaves = arg2_leaves - connective
            end
            if arg1_leaves.size > 0 and Variable::Punctuations.include?(arg1_leaves.last.v) and not arg1_leaves.include?(arg1_leaves.last.prev_leaf) and
                arg2_leaves.include?(arg1_leaves.last.prev_leaf) then
                punc_leaf = arg1_leaves.pop
                arg2_leaves.push(punc_leaf)
            end
            if arg1_leaves.size > 0 and Variable::Punc2.include?(arg1_leaves.first.v) and arg2_leaves.last == arg1_leaves.first.prev_leaf then
                punc_leaf = arg1_leaves.shift
                arg2_leaves.push(punc_leaf)
            end

            if arg2_leaves.size == 0 then
                tmp1 = Array.new
                tmp2 = Array.new
                arg1_leaves.sort {|l1,l2| l1.article_order <=> l2.article_order} .each do |l|
                    if l.article_order < connective.first.article_order then
                        tmp1.push(l)
                    elsif l.article_order > connective.last.article_order then
                        tmp2.push(l)
                    end
                end
                arg1_leaves = tmp1
                arg2_leaves = tmp2
            elsif arg1_leaves.size == 0 then
                tmp1 = Array.new
                tmp2 = Array.new
                arg2_leaves.sort {|l1,l2| l1.article_order <=> l2.article_order} .each do |l|
                    if l.article_order < connective.first.article_order then
                        tmp1.push(l)
                    elsif l.article_order > connective.first.article_order then
                        tmp2.push(l)
                    end
                end
                arg1_leaves = tmp1
                arg2_leaves = tmp2
            end

            if arg1_leaves.size == 0 or arg2_leaves.size == 0 then
                # skip
            else
                relation = Relation.new('|||||||||||||||||||||||||||||||||||||||||||||||', -1)
                relation.arg1s['parsed_tree'] = find_common_nodes(arg1_leaves)
                relation.arg2s['parsed_tree'] = find_common_nodes(arg2_leaves)
                relation.arg1_leaves = arg1_leaves
                relation.arg2_leaves = arg2_leaves
                relation.conn_leaves = connective
                relation.conn_type = conn_type
                relation[9] = connective.map {|l| l.v} .join(' ')
                if arg1_leaves == [] then
                    relation.arg1_sid = []
                else
                    relation.arg1_sid = arg1_leaves.first.goto_tree.sent_id
                end
                relation.arg2_sid = arg2_leaves.first.goto_tree.sent_id
                @exp_relations_p.push(relation)
                @disc_relations_p.push(relation)
            end
        }
    end

    # 0:  node1 and node2 in the same path to root
    # 1:  node2 is at the rhs of node1's path to root
    # -1: node2 is at the lhs of node1's path to root
    def relative_position(node1, node2)
        root = node1.goto_tree.root
        return 0 if node1 == node2 or node2 == root
        curr = node1
        rsibs = []
        lsibs = []
        while curr != root do
            rsibs += curr.all_right_siblings
            lsibs += curr.all_left_siblings
            curr = curr.up
            return 0 if curr == node2
        end

        rsibs.each do |rsib|
            if rsib.get_all_nodes.include?(node2) then
                return 1
            end
        end

        lsibs.each do |lsib|
            if lsib.get_all_nodes.include?(node2) then
                return -1
            end
        end

        0
    end

    def find_head_words(leaves, remove_attr_verbs=true)
        if not remove_attr_verbs
            return find_common_nodes(leaves).map {|n| n.head_word_ptr} .reject {|n| n == nil}
        else
            hwords = Array.new
            find_common_nodes(leaves) .reject {|n| n.head_word_ptr == nil} .each {|n|
                if Variable::Attr_verbs.include?(n.head_word_ptr.lemmatized)
                    hwords += rec_find_head_words(n)
                else
                    hwords.push(n.head_word_ptr)
                end
            }
            return hwords.uniq.reject {|n| n == nil}
        end
    end

    def rec_find_head_words(node)
        if Variable::Attr_verbs.include?(node.head_word_ptr.lemmatized)
            hwords = Array.new
            node.child_nodes.each {|c|
                #if c.head_word_ptr != node.head_word_ptr
                    hwords += rec_find_head_words(c) if c.head_word_ptr != nil
                #end
            }
            return hwords.uniq
        else
            return [node.head_word_ptr]
        end
    end

    def find_path(node1, node2)
        lca = find_least_common_ancestor([node1, node2])
        n1_to_lca = find_upward_path(node1, lca)
        n2_to_lca = find_upward_path(node2, lca)
        if n1_to_lca[-1] == n2_to_lca[-1] and n2_to_lca[-1] != nil then
            n2_to_lca[-1] = ''
        end
        path = n1_to_lca.join('->') + n2_to_lca.reverse.join('<-')

        n1_to_lca2 = []
        prev = nil
        n1_to_lca.each do |a|
            if a != prev then n1_to_lca2 << a end
            prev = a
        end

        n2_to_lca2 = []
        prev = nil
        n2_to_lca.each do |a|
            if a != prev then n2_to_lca2 << a end
            prev = a
        end
        path2 = n1_to_lca2.join('->') + n2_to_lca2.reverse.join('<-')

        # shorten
        #remain_tags = %w/S SBAR SBARQ SQ SINV FRAG UCP PRN PP WHADVP ADVP/
        #n1_to_lca.delete_if {|t| not remain_tags.include?(t)}
        #n2_to_lca.delete_if {|t| not remain_tags.include?(t)}
        #path2 = n1_to_lca.join('->') + '*' + n2_to_lca.reverse.join('<-')
        
        [path, path2]
    end

    def find_upward_path(node1, node2)
        return [] if node1 == node2
        curr = node1
        path = []
        while curr != node2 and curr != nil do
            path << curr.v
            curr = curr.up
        end
        if curr == node2 and curr != nil then path << curr.v end
        if curr == nil then [] else path end
    end

    def find_least_common_ancestor(nodes, remove_punc_CC=false)
        if remove_punc_CC then
            nodes.delete_if {|n| Variable::Punctuation_tags.include?(n.v) or n.v == 'CC'}
        end
        root = nodes.first.goto_tree.root
        lca = nil
        queue = [root]
        while not queue.empty? do
            curr = queue.shift
            if (curr.get_all_nodes() & nodes).size == nodes.size then
                lca = curr
                curr.child_nodes.each {|c| queue << c}
            end
        end
        lca
    end

    def find_node_with_most_leaves(nodes)
        max = 0
        argmax = nil
        nodes.each do |n|
            size = n.my_leaves.size
            if size > max then
                max = size
                argmax = n
            end
        end
        argmax
    end

    def find_common_nodes(leaves)
        return [] if leaves == []

        leaves.each do |l| 
            if not l.is_NONE_leaf then
                l.travel_cnt = 1
                curr = l.parent_node
                while curr != nil do
                    curr.travel_cnt += 1
                    curr = curr.parent_node
                end
            end
        end
        common_nodes = Array.new
        leaves.first.goto_tree.root.find_common_nodes(common_nodes)
        leaves.first.goto_tree.root.reset_travel_cnt
        common_nodes.uniq
    end

    def flag_disc_connectives(ary)
        @sentences.each {|sentence|
            sentence.connectives.each_index {|i|
                flag = ary.shift == '1' ? true : false
                sentence.connective_flags[i] = flag
                if flag
                    sentence.disc_connectives_p.push(sentence.connectives[i])
                    @disc_connectives_p.push(sentence.connectives[i])
                end
            }
        }
        if ary.size != 0
            puts 'error: ary.size != 0'
            exit
        end
    end

    def label_leaf_article_order
        id = 0
        sentences.each {|s|
            s.leaves.each {|l|
                @leaves.push(l)
                id += 1
                l.article_order = id
            }
        }
    end

    def label_node_size
        sentences.each {|s|
            s.root.label_node_size
        }
    end

    def get_production_rules2(idx, nary=-1, with_leaf=true, global=false)
        clause_nodes = find_common_nodes(@clauses[idx])
        if not global
            rules = Hash.new(0)
            clause_nodes.each {|n|
                n.get_production_rules(rules, nary, with_leaf)
            }
            rules
        else
            root = clause_nodes.first
            while root.parent_node != nil
                root = root.parent_node
            end
            clause_nodes.each {|n|
                n.mark_subtree_included
                curr = n
                while curr.parent_node != nil
                    curr = curr.parent_node
                    curr.included = true
                end
            }
            rules = Hash.new(0)
            root.get_included_production_rules(rules, nary, with_leaf)
            root.unmark_subtree_included
            rules
        end
    end

    def get_production_rules(edu_idx, nary=-1, with_leaf=true, global=false)
        if not global
            rules = Hash.new(0)
            @edu_nodes[edu_idx].each {|n|
                n.get_production_rules(rules, nary, with_leaf)
            }
            rules
        else
            root = @edu_nodes[edu_idx].first
            while root.parent_node != nil
                root = root.parent_node
            end
            @edu_nodes[edu_idx].each {|n|
                n.mark_subtree_included
                curr = n
                while curr.parent_node != nil
                    curr = curr.parent_node
                    curr.included = true
                end
            }
            rules = Hash.new(0)
            root.get_included_production_rules(rules, nary, with_leaf)
            root.unmark_subtree_included
            rules
        end
    end

    def mark_in_p_relation
        @disc_relations_p.each_index {|i|
            rel = @disc_relations_p[i]
            if rel != nil then
                (rel.arg1s['parsed_tree'] + rel.arg2s['parsed_tree']).each {|n|
                    n.mark_in_p_relation
                }
            end
        }
    end

    def mark_in_relation
        @relations.each_index {|i|
            rel = @relations[i]
            if rel[1] == 'Explicit' or rel[1] == 'Implicit' or rel[1] == 'AltLex'
                (rel.attrs['parsed_tree'] + 
                 rel.arg1s['parsed_tree'] + rel.attr1s['parsed_tree'] + rel.sup1s['parsed_tree'] + 
                 rel.arg2s['parsed_tree'] + rel.attr2s['parsed_tree'] + rel.sup2s['parsed_tree']).each {|n|
                    n.mark_in_relation
                }
            end
        }
    end

    def mark_attribution_clauses(use_p_relation=false)
        @clauses.each_index {|i|
            clause = @clauses[i]
            in_rel = false
            clause_leaves = Array.new
            clause.each {|l|
                if l.is_attr_leaf
                    clause_leaves.push(l)
                end
                if use_p_relation then
                    in_rel = true if l.in_p_relation
                else
                    in_rel = true if l.in_relation
                end
            }
            all_punc = true
            clause_leaves.each {|e|
                all_punc = false if not $punctuations.include?(e.value)
            }
            if not clause_leaves.empty? and all_punc
                clause_leaves.each {|l| l.is_attr_leaf = false}
                clause_leaves = []
            end
            if not clause_leaves.empty?
                #edu_leaves.each {|n|
                    #n.is_attr_leaf = true
                #}
                @clause_marked[i] = true
            end
            
            if use_p_relation
                if in_rel then
                    @clause_in_p_relation[i] = true 
                else
                    @clause_in_p_relation[i] = false
                end
            else
                if in_rel then
                    @clause_in_relation[i] = true   
                else 
                    @clause_in_relation[i] = false
                end
            end
        }
    end

    def mark_attribution_edus
        @edus.each_index {|i|
            curr = @edus[i]
            in_rel = false
            edu_leaves = Array.new
            @edu_lengths[i].times {
                if curr.is_attr_leaf
                    edu_leaves.push(curr)
                end
                if curr.in_relation
                    in_rel = true
                end
                curr = curr.next_leaf
            }
            #if edu_leaves.size == 1 and 
                #not $verb_tags.include?(edu_leaves.first.parent_node.value)
                #edu_leaves.shift
            #end
            all_punc = true
            edu_leaves.each {|e|
                all_punc = false if not $punctuations.include?(e.value)
            }
            if not edu_leaves.empty? and all_punc
                edu_leaves.each {|e| e.is_attr_leaf = false}
                edu_leaves = []
            end
            if not edu_leaves.empty?
                #edu_leaves.each {|n|
                    #n.is_attr_leaf = true
                #}
                @edu_marked[i] = true
            end
            
            if in_rel
                @edu_in_relation[i] = true
            end
        }
    end

    def print_edu_with_index(idx)
        curr = @edus[idx]
        (@edu_lengths[idx] - 1).times {
            print curr.value+' '
            curr = curr.next_leaf
        }
        puts curr.value
    end

    def edubreak
        edu_file = @ptb_file.match(/combined/) ? 
            @ptb_file.sub(/combined/, 'edu').sub(/mrg$/, 'edu') :
            @ptb_file.sub(/charniak/, 'edu').sub(/mrg$/, 'edu')
        text = File.readlines(edu_file).join
        #text = `cd #{SPADE_BIN}; ./edubreak.pl #{@ptb_file} 2> /dev/null`
        #f = File.open(edu_file, 'w')
        #f.puts text
        #f.close
        text = text.gsub(/\(/, '-LRB-').gsub(/\)/, '-RRB-').gsub(/\{/, '-LCB-').gsub(/\}/, '-RCB-')
        text = text.gsub(/'''/, "' ''")
        text = text.gsub(/\n\n/, "\n")
        text = text.gsub(/<S>'/, "<S>\n'")
        sents = text.split("<S>\n")
        sents.each_index {|i|
            pref = nil
            curr = parsed_trees[i].root.first_leaf
            edus_tmp = sents[i].split("\n").map {|l| l.strip}
            edus = Array.new
            j = 0
            while j < edus_tmp.size
                ec = edus_tmp[j]
                e1 = j < (edus_tmp.size - 1) ? edus_tmp[j+1] : nil
                e2 = j < (edus_tmp.size - 2) ? edus_tmp[j+2] : nil

                e = ''
                #...
                #-LRB- ... -RRB-
                #...
                if e1 != nil and e1.match(/^-LRB- .* -RRB-$/)
                    if e2 != nil
                        e = ec+' '+e1+' '+e2
                        j += 3
                    else
                        e = ec+' '+e1
                        j += 2
                    end
                ##...
                ##-LRB- ... -RRB- ...
                #elsif e1 != nil and e1.match(/^-LRB- .* -RRB- .*$/)
                    #e = ec+' '+e1
                    #j += 2
                ##... -LRB- ... -RRB-
                ##...
                #elsif ec.match(/^.* -LRB- .* -RRB-$/) and
                    #e1 != nil
                    #e = ec+' '+e1
                    #j += 2
                #said|says|say ...
                #who|whose|which ...
                elsif ec.match(/^(said|says|say) .*$/) and
                    e1 != nil and e1.match(/^(who|whose|which) .*$/)
                    e = ec+' '+e1
                    j += 2
                #... 
                #said|says|say|saying[ ,| :]
                elsif e1 != nil and e1.match(/^(said|says|say|saying)(| ,| :)$/)
                    e = ec+' '+e1
                    j += 2
                #...
                #who|whose|which ... said|says|say
                elsif e1 != nil and e1.match(/^(who|whose|which) .* (said|says|say)$/)
                    e = ec+' '+e1
                    j += 2
                #...
                #who|whose|which ...
                #said|says|say[ ,| :| .]
                elsif e1 != nil and e1.match(/^(who|whose|which) .*$/) and
                    e2 != nil and e2.match(/^(said|says|say)(| ,| :| .)$/)
                    e = ec+' '+e1+' '+e2
                    j += 3
                ##In ... ,
                ##...
                #elsif ec.match(/^In .* ,$/) and
                    #e1 != nil
                    #e = ec+' '+e1
                    #j += 2
                ##But[ ,]|However[ ,]|..
                ##...
                #elsif j == 0 and ec.match(/^[A-Z][a-z]*(| ,)$/) and
                    #e1 != nil
                    #e = ec+' '+e1
                    #j += 2
                else
                    e = ec
                    j += 1
                end

                edus.push(e)
            end
            edus.each {|e|
                ws = e.split
                @edus.push(curr)
                @edu_lengths.push(ws.length)
                @edu_marked.push(false)
                @edu_in_relation.push(false)
                tmp_ary = Array.new
                ws.each {|w|
                    #exit if curr1.value != w
                    tmp_ary.push(curr)
                    pref = curr
                    curr = curr.next_leaf
                }
                @edu_ary.push(tmp_ary)
                @sentences[i].edus.push(tmp_ary)
                pref.edu_break = true
            }
        }
        #@edus.each_index {|i|
            #curr = @edus[i]
            #tmp = Array.new
            #@edu_lengths[i].times {
                #tmp.push(curr)
                #curr = curr.next_leaf
            #}
            #@edu_ary.push(tmp)
        #}
        @edu_ary.each_index {|i|
            first_leaf_id = @edu_ary[i].first.leaf_orig_id
            last_leaf_id = @edu_ary[i].last.leaf_orig_id
            tmp = Array.new
            @edu_ary[i].each {|l|
                curr = l.parent_node
                while not curr.is_root and 
                    not curr.parent_node.leaf_id_range.first < first_leaf_id and
                    not curr.parent_node.leaf_id_range.last > last_leaf_id
                    curr = curr.parent_node
                end
                tmp.push(curr)
            }
            tmp = tmp.uniq
            @edu_nodes.push(tmp)
        }
    end

    def gorns2sentid(gorn_addr)
        gorns = gorn_addr.split(';')
        ary = Array.new
        gorns.each do |g|
            idx = g.split(',')
            sentidx = idx.shift.to_i
            ary.push(sentidx) if not ary.include?(sentidx)
        end
        ary.sort
    end

    def gorns2roots(gorn_addr)
        gorns = gorn_addr.split(';')
        roots = Array.new
        gorns.each do |g|
            idx = g.split(',')
            sentidx = idx.shift.to_i
            tree = @parsed_trees[sentidx]
            root = tree.root
            roots.push(root) if not roots.include?(root)
        end
        roots
    end

    # return the tree of the given gorn addr, e.g, 10,1,1,1,1,1,2,1,1,0
    def gorns2nodes(gorn_addr)
        gorns = gorn_addr.split(';')
        #sentidx_to_tree = Hash.new
        nodes = Array.new
        gorns.each do |g|
            idx = g.split(',')
            sentidx = idx.shift.to_i
            #if not sentidx_to_tree.has_key?(sentidx)
            #    orig_tree = @parsed_trees[sentidx]
            #    tree = Marshal.load(Marshal.dump(orig_tree))
            #    sentidx_to_tree[sentidx] = tree
            #else
                tree = @parsed_trees[sentidx]
            #end
            node = tree.root
            #node.mark_as_included
            idx.each do |i|
                node = node.child_nodes[i.to_i]
            #    node.mark_as_included
            end
            #node.mark_child_nodes
            nodes.push(node)
        end
        #trees = Array.new
        #sentidx_to_tree.sort{|p1, p2| p1[0].to_i <=> p2[0].to_i}.each do |id, t|
        #    trees.push(t)
        #end
        #trees
        nodes
    end

    def read_parsed_trees
        file = File.open(@ptb_file, 'r')
        tree_text = ''
        sent_id = 0
        file.each_line do |line| 
            line.chomp!
            if line.match(/^\s*$/)
                # skip empty line
            elsif line.match(/^\( ?\(/)
                if tree_text != ''
                    tree = Tree.new(tree_text, sent_id)
                    tree.find_heads
                    @parsed_trees.push(tree)
                    sentence = Sentence.new(tree, sent_id)
                    @sentences.push(sentence)
                    @sid2tree[sent_id] = tree
                    sent_id += 1
                end
                tree_text = line
            else
                tree_text += "\n"+line
            end
        end
        if tree_text != ''
            tree = Tree.new(tree_text, sent_id)
            tree.find_heads
            @parsed_trees.push(tree)
            sentence = Sentence.new(tree, sent_id)
            @sentences.push(sentence)
            @sid2tree[sent_id] = tree
        end
        file.close
    end

    def read_dtrees(replace_nil=false)
        text = File.readlines(@dtree_file).join
        if replace_nil then
            if text[0..1] == "\n\n" then text[0..1] = "_nil_\n\n" end
            while text.match(/^\n^\n^\n/) do text.sub!(/^\n^\n^\n/, "\n_nil_\n\n") end        
        else
            while text.match(/^\n^\n/) do text.sub!(/^\n^\n/, "\n_nil_\n\n") end        
        end
        dtree_texts = text.split(/\n\n/)
        @parsed_trees.each_index {|i| 
            #puts @parsed_trees.map {||}
            @parsed_trees[i].build_dependency_tree(dtree_texts[i]) if dtree_texts[i] != nil
        }
    end

    def get_parsed_text(level=2, notext=false)
        @rel_texts = []
        @exp_relations_p.each_index {|i|
            rel = @exp_relations_p[i]
            type = level == 1 ? @exp_level_1_types_p[i] : @exp_level_2_types_p[i]

            rel_text = "<u>Exp #{i} #{type}</u><br>"
            tmp_ary = []

            tmp_ary << [rel.arg1_leaves.first.article_order, "<b>Arg1:</b> " + rel.arg1_leaves.map {|l| l.value} .join(" ") + "<br>"]
            rel.arg1_leaves.first.print_value = "{Exp_#{i}_Arg1 " + rel.arg1_leaves.first.print_value
            rel.arg1_leaves.last.print_value = rel.arg1_leaves.last.print_value + " Exp_#{i}_Arg1}"

            #tmp_ary << [rel.conn_leaves.first.article_order, "<b>Conn:</b> " + rel.conn_leaves.map {|l| l.value} .join(" ") + "<br>"]
            if rel.conn_type == 'group'
                rel.conn_leaves.first.print_value = "{Exp_#{i}_conn_#{type} " + rel.conn_leaves.first.print_value
                rel.conn_leaves.last.print_value = rel.conn_leaves.last.print_value + " Exp_#{i}_conn}"
            elsif rel.conn_type == 'intra'
                rel.conn_leaves.first.print_value = "{Exp_#{i}_conn_#{type} " + rel.conn_leaves.first.print_value + " Exp_#{i}_conn}"
                rel.conn_leaves.last.print_value = "{Exp_#{i}_conn_#{type} " + rel.conn_leaves.last.print_value + " Exp_#{i}_conn}"
            end

            arg2_words = (rel.arg2_leaves.map {|l| [l.article_order, l.value]} + rel.conn_leaves.map {|l| [l.article_order, "<b>" + l.value + "</b>"]}).sort {|a,b| a[0] <=> b[0]} .map {|a| a[1]}
            tmp_ary << [rel.arg2_leaves.first.article_order, "<b>Arg2:</b> " + arg2_words.join(" ") + "<br>"]
            rel.arg2_leaves.first.print_value = "{Exp_#{i}_Arg2 " + rel.arg2_leaves.first.print_value
            rel.arg2_leaves.last.print_value = rel.arg2_leaves.last.print_value + " Exp_#{i}_Arg2}"

            tmp_ary.sort {|a,b| a[0] <=> b[0]} .each {|a0, a1| rel_text += a1}
            @rel_texts << rel_text
        }

        @nonexp_relations_p.each_index {|i|
            rel = @nonexp_relations_p[i]
            type = level == 1 ? @nonexp_level_1_types_p[i] : @nonexp_level_2_types_p[i]

            rel_text = "<u>NonExp #{i} #{type}</u><br>"
            
            rel_text += "<b>Arg1:</b> " + rel.arg1_leaves.map {|l| l.value} .join(" ") + "<br>"
            rel.arg1_leaves.first.print_value = "{NonExp_#{i}_Arg1 " + rel.arg1_leaves.first.print_value
            rel.arg1_leaves.last.print_value = rel.arg1_leaves.last.print_value + " NonExp_#{i}_Arg1}"

            rel_text += "<b>Arg2:</b> " + rel.arg2_leaves.map {|l| l.value} .join(" ") + "<br>"
            rel.arg2_leaves.first.print_value = "{NonExp_#{i}_Arg2_#{type} " + rel.arg2_leaves.first.print_value
            rel.arg2_leaves.last.print_value = rel.arg2_leaves.last.print_value + " NonExp_#{i}_Arg2}"

            @rel_texts << rel_text
        }
        @attr_clauses.each_index {|i|
            clause = @attr_clauses[i]
            rel_text = "<u>Attr #{i}</u><br>"

            rel_text += clause.map {|l| l.value} .join(" ") + "<br>"
            clause.first.print_value = "{Attr_#{i} " + clause.first.print_value
            clause.last.print_value = clause.last.print_value + " Attr_#{i}}"

            @rel_texts << rel_text
        }

        text = ''
        @paragraphs.each_index {|i|
            para = @paragraphs[i]
            para.sentences.each_index {|j|
                if notext == false then
                    text += para.sentences[j].text3 + "\n"
                else
                    text += para.sentences[j].text4 + "\n"
                end
            }
            text += "\n"
        }
        @parsed_text = text
        text
    end

    def get_parsed_text2(level=2)
        ary = Array.new

        @exp_relations_p.each_index {|i|
            rel = @exp_relations_p[i]
            type = level == 1 ? @exp_level_1_types_p[i] : @exp_level_2_types_p[i]

            highlight_rel("Exp", i, rel, type, ary)
        }

        @nonexp_relations_p.each_index {|i|
            rel = @nonexp_relations_p[i]
            type = level == 1 ? @nonexp_level_1_types_p[i] : @nonexp_level_2_types_p[i]

            highlight_rel("NonExp", i, rel, type, ary)
        }

        ary = ary.sort { |a, b| get_tuple_maxint(a[1]) <=> get_tuple_maxint(b[1]) }

        ary
    end

    def get_tuple_maxint(tuples)
        arr = tuples.flatten
        arr2 = Array.new
        0.step(arr.length - 1, 4) {|i| arr2 << arr[i+2].to_i; arr2 << arr[i+3].to_i}
        arr2.sort.last
    end

    def highlight_rel(which, i, rel, type, ary)
        rel_ptr = "#{which} #{i} #{type}"
        tuples = Array.new

        if which == "Exp" then
            sent_ids = [rel.arg1_leaves.first.goto_tree.sent_id, rel.arg2_leaves.first.goto_tree.sent_id, rel.conn_leaves.first.goto_tree.sent_id].uniq
        else
            sent_ids = [rel.arg1_leaves.first.goto_tree.sent_id, rel.arg2_leaves.first.goto_tree.sent_id].uniq
        end

        @attr_clauses.each_index {|i|
            clause = @attr_clauses[i]
            clause_sent_id = clause.first.goto_tree.sent_id
            if clause != [] and sent_ids.include?(clause_sent_id) then
                tuples << ["span", "#B5E61D", clause.first.article_order, clause.last.article_order]
            end
        }

        tuples << ["font", "#FFFF66", rel.arg1_leaves.first.article_order, rel.arg1_leaves.last.article_order]

        if which == "Exp" then
            if rel.conn_type == 'group'
                tuples << ["font", "#FF7575", rel.conn_leaves.first.article_order, rel.conn_leaves.last.article_order]
            elsif rel.conn_type == 'intra'
                tuples << ["font", "#FF7575", rel.conn_leaves.first.article_order, rel.conn_leaves.first.article_order]
                tuples << ["font", "#FF7575", rel.conn_leaves.last.article_order, rel.conn_leaves.last.article_order]
            end
        end

        tuples << ["font", "#84C2FF", rel.arg2_leaves.first.article_order, rel.arg2_leaves.last.article_order]

        ary << [rel_ptr, tuples]
    end

    def get_plain_text(brk="\n")
        text = ''
        @paragraphs.each_index {|i|
            para = @paragraphs[i]
            para.sentences.each_index {|j|
                text += para.sentences[j].text3 + " " + brk
            }
            text += brk
        }
        text = text.strip
        @parsed_text = text
        text
    end

    def get_rel_sequence
        arr = Array.new
        @exp_relations_p.each_index do |i|
            rel  = @exp_relations_p[i]
            type = @exp_level_2_types_p[i].split(/\./).last.gsub(/_/, '-')
            arr << ["Exp.#{i}", type, 1, get_mid_idx(rel.arg1_leaves)]
            arr << ["Exp.#{i}", type, 2, get_mid_idx(rel.arg2_leaves)]
        end
        @nonexp_relations_p.each_index do |i|
            rel  = @nonexp_relations_p[i]
            type = @nonexp_level_2_types_p[i].split(/\./).last.gsub(/_/, '-')
            arr << ["NonExp.#{i}", type, 1, get_mid_idx(rel.arg1_leaves)]
            arr << ["NonExp.#{i}", type, 2, get_mid_idx(rel.arg2_leaves)]
        end
        arr.sort {|a,b| a[3] <=> b[3]} .map {|a| a[0]+'.'+a[1]+'.'+a[2].to_s} 
    end

    def get_rel_sequence_for_gs
        arr = Array.new
        @exp_relations.each_index do |i|
            rel  = @exp_relations[i]
            type = rel[12].split('.')[0]
            #next if type == nil
            arr << ["Exp.#{i}", type, 1, get_mid_idx(rel.arg1_leaves)]
            arr << ["Exp.#{i}", type, 2, get_mid_idx(rel.arg2_leaves)]
        end
        @nonexp_relations.each_index do |i|
            rel  = @nonexp_relations[i]
            if rel[1] == 'Implicit' or rel[1] == 'AltLex' then
                type = rel[12].split('.')[0]
            else
                type = rel[1]
            end
            #next if type == nil
            arr << ["NonExp.#{i}", type, 1, get_mid_idx(rel.arg1_leaves)]
            arr << ["NonExp.#{i}", type, 2, get_mid_idx(rel.arg2_leaves)]
        end
        arr.sort {|a,b| a[3] <=> b[3]} .map {|a| a[0]+'.'+a[1]+'.'+a[2].to_s} 
    end

    def get_mid_idx(leaves)
        leaves[leaves.size / 2].article_order
    end

    def get_sorted_rel_arg
        arr = Array.new
        @exp_relations_p.each_index do |i|
            rel  = @exp_relations_p[i]
            type = @exp_level_2_types_p[i].split(/\./).last.gsub(/_/, '-')
            arr << ["Exp", type, 1, get_mid_idx(rel.arg1_leaves), get_events(rel.arg1_leaves)]
            arr << ["Exp", type, 2, get_mid_idx(rel.arg2_leaves), get_events(rel.arg2_leaves)]
        end
        @nonexp_relations_p.each_index do |i|
            rel  = @nonexp_relations_p[i]
            type = @nonexp_level_2_types_p[i].split(/\./).last.gsub(/_/, '-')
            arr << ["NonExp", type, 1, get_mid_idx(rel.arg1_leaves), get_events(rel.arg1_leaves)]
            arr << ["NonExp", type, 2, get_mid_idx(rel.arg2_leaves), get_events(rel.arg2_leaves)]
        end
        arr.sort {|a,b| a[3] <=> b[3]} .map {|a| a[0]+'.'+a[1]+'.'+a[2].to_s+' '+a[3].to_s+' '+a[4].join(' ')} .join(' ### ')
    end

    def get_sent_term_types
        grid = Hash.new {|h,sid| h[sid] = Hash.new {|h1,t| h1[t] = Hash.new(0)}}
        @exp_relations_p.each_index do |i|
            rel  = @exp_relations_p[i]
            ss_ps = rel.in_same_sentence? ? 'SS' : 'PS'
            type = @exp_level_2_types_p[i].split(/\./).last.gsub(/_/, '-')
            rel.arg1_leaves.each do |l|
                sid = l.goto_tree.sent_id
                t = l.up.v+'_'+l.v
                grid[sid][t][ss_ps+".Exp.#{i}."+type+".1"] += 1
            end
            rel.arg2_leaves.each do |l|
                sid = l.goto_tree.sent_id
                t = l.up.v+'_'+l.v
                grid[sid][t][ss_ps+".Exp.#{i}."+type+".2"] += 1
            end
        end
        @nonexp_relations_p.each_index do |i|
            rel  = @nonexp_relations_p[i]
            type = @nonexp_level_2_types_p[i].split(/\./).last.gsub(/_/, '-')
            rel.arg1_leaves.each do |l|
                sid = l.goto_tree.sent_id
                t = l.up.v+'_'+l.v
                grid[sid][t]["PS.NonExp.#{i}."+type+".1"] += 1
            end
            rel.arg2_leaves.each do |l|
                sid = l.goto_tree.sent_id
                t = l.up.v+'_'+l.v
                grid[sid][t]["PS.NonExp.#{i}."+type+".2"] += 1
            end
        end
        PP.pp(grid, "").gsub(/\n/, ' ').gsub(/ +/, ' ').strip
    end

    def get_sent_term_types_for_gs
        grid = Hash.new {|h,sid| h[sid] = Hash.new {|h1,t| h1[t] = Hash.new(0)}}
        @exp_relations.each_index do |i|
            rel  = @exp_relations[i]
            type = rel[12].split('.')[0]
            rel.arg1_leaves.each do |l|
                sid = l.goto_tree.sent_id
                t = l.up.v+'_'+l.v
                grid[sid][t]["Exp.#{i}."+type+".1"] += 1
            end
            rel.arg2_leaves.each do |l|
                sid = l.goto_tree.sent_id
                t = l.up.v+'_'+l.v
                grid[sid][t]["Exp.#{i}."+type+".2"] += 1
            end
        end
        @nonexp_relations.each_index do |i|
            rel  = @nonexp_relations[i]
            if rel[1] == 'Implicit' or rel[1] == 'AltLex' then
                type = rel[12].split('.')[0]
            else
                type = rel[1]
            end
            rel.arg1_leaves.each do |l|
                sid = l.goto_tree.sent_id
                t = l.up.v+'_'+l.v
                grid[sid][t]["NonExp.#{i}."+type+".1"] += 1
            end
            rel.arg2_leaves.each do |l|
                sid = l.goto_tree.sent_id
                t = l.up.v+'_'+l.v
                grid[sid][t]["NonExp.#{i}."+type+".2"] += 1
            end
        end
        PP.pp(grid, "").gsub(/\n/, ' ').gsub(/ +/, ' ').strip
    end

    def get_event_trans(intra_inter=false, all_word=false)
        trans = Array.new
        @exp_relations_p.each_index do |i|
            rel  = @exp_relations_p[i]
            type = @exp_level_2_types_p[i].split(/\./).last.gsub(/_/, '-')
            events1 = get_events(rel.arg1_leaves, intra_inter, all_word)
            events2 = get_events(rel.arg2_leaves, intra_inter, all_word)
            events1.each do |e1|
                events2.each do |e2|
                    if not intra_inter then
                        trans << e1 + "_Exp.#{i}." + type + "_" + e2
                    else
                        trans << e1.join("_") + "_Exp.#{i}." + type + "_" + e2.join("_")
                    end
                end
            end
        end
        @nonexp_relations_p.each_index do |i|
            rel  = @nonexp_relations_p[i]
            type = @nonexp_level_2_types_p[i].split(/\./).last.gsub(/_/, '-')
            events1 = get_events(rel.arg1_leaves, intra_inter, all_word)
            events2 = get_events(rel.arg2_leaves, intra_inter, all_word)
            events1.each do |e1|
                events2.each do |e2|
                    if not intra_inter then
                        trans << e1 + "_NonExp.#{i}." + type + "_" + e2
                    else
                        trans << e1.join("_") + "_NonExp.#{i}." + type + "_" + e2.join("_")
                    end
                end
            end
        end
        trans
    end

    def get_events(leaves, get_sid=false, all_word=false)
        events = Array.new
        leaves.each do |l|
            if not all_word then
                if Variable::Event_tags.include?(l.up.v) then
                    if not get_sid then
                        events << l.up.v+'_'+l.v
                    else
                        events << [l.goto_tree.sent_id, l.up.v+'_'+l.v]
                    end
                end
            else
                if not get_sid then
                    events << l.up.v+'_'+l.v
                else
                    events << [l.goto_tree.sent_id, l.up.v+'_'+l.v]
                end
            end
        end
        events.uniq
    end
end

