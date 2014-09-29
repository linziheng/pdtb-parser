require File.dirname(__FILE__)+'/../lib/stemmable'
require File.dirname(__FILE__)+'/corpus'

class Relation
    attr_accessor :raw_text, :id,
        :col, :word_pairs,
        :alls, :attrs, :arg1s, :attr1s, :sup1s, :arg2s, :attr2s, :sup2s,
        :conn_leaves, :long_conn_leaves, :conn_type, :arg1_leaves, :sup1_leaves, :arg2_leaves, :sup2_leaves,
        :prev_rel, :next_rel,
        :arg1_sid, :arg2_sid,
        :article

    def initialize(raw_text, id)
        @raw_text = raw_text
        @id = id
        @col = raw_text.force_encoding('iso-8859-1').split(/\|/, -1)
        @word_pairs = Hash.new(nil)
        @arg1_sid = -1
        @arg2_sid = -1
        @alls   = Hash.new
        @attrs  = Hash.new
        @arg1s  = Hash.new
        @attr1s = Hash.new
        @sup1s  = Hash.new
        @arg2s  = Hash.new
        @attr2s = Hash.new
        @sup2s  = Hash.new
        @conn_leaves = nil
        @long_conn_leaves = nil
        @conn_type = nil
        @arg1_leaves = nil
        @sup1_leaves = nil
        @arg2_leaves = nil
        @sup2_leaves = nil
        @prev_rel = @next_rel = nil
        @article = nil
        @arg1s['text']  = self[25]
        @attr1s['text'] = self[32]
        @sup1s['text']  = self[45]
        @arg2s['text']  = self[35]
        @attr2s['text'] = self[42]
        @sup2s['text']  = self[48]
        @arg1s['tokenized']  = Utils.tokenize(self[25].dup.downcase)
        @attr1s['tokenized'] = Utils.tokenize(self[32].dup.downcase)
        @sup1s['tokenized']  = Utils.tokenize(self[45].dup.downcase)
        @arg2s['tokenized']  = Utils.tokenize(self[35].dup.downcase)
        @attr2s['tokenized'] = Utils.tokenize(self[42].dup.downcase)
        @sup2s['tokenized']  = Utils.tokenize(self[48].dup.downcase)
        @arg1s['stemmed']  = @arg1s['tokenized'].dup.stem_sentence
        @attr1s['stemmed'] = @attr1s['tokenized'].dup.stem_sentence
        @sup1s['stemmed']  = @sup1s['tokenized'].dup.stem_sentence
        @arg2s['stemmed']  = @arg2s['tokenized'].dup.stem_sentence
        @attr2s['stemmed'] = @attr2s['tokenized'].dup.stem_sentence
        @sup2s['stemmed']  = @sup2s['tokenized'].dup.stem_sentence
        [self[12], self[13], self[14], self[15]].each {|a| a.gsub!(/ /, '_')}
    end

    def [](i)
        @col[i-1]
    end

    def []=(i, b)
        @col[i-1]= b
    end

    def first_leaf
        if @conn_leaves == nil
            leaves = [@arg1_leaves.first, @arg2_leaves.first]
        else
            leaves = [@arg1_leaves.first, @arg2_leaves.first, @conn_leaves.first]
        end
        leaves.sort {|a,b| a.article_order <=> b.article_order} .first
    end

    def get_sup_leaves
        nodes = @sup1s['parsed_tree']
        @sup1_leaves = Array.new
        nodes.each {|n|
            n.get_leaves(@sup1_leaves)
        }
        @sup1_leaves.sort! {|a,b| a.leaf_orig_id <=> b.leaf_orig_id}

        nodes = @sup2s['parsed_tree']
        @sup2_leaves = Array.new
        nodes.each {|n|
            n.get_leaves(@sup2_leaves)
        }
        @sup2_leaves.sort! {|a,b| a.leaf_orig_id <=> b.leaf_orig_id}
    end

    def get_arg_leaves
        nodes = @arg1s['parsed_tree']
        @arg1_leaves = Array.new
        nodes.each {|n|
            n.get_leaves(@arg1_leaves) if n != nil
        }
        @arg1_leaves.sort! {|a,b| a.article_order <=> b.article_order}

        nodes = @arg2s['parsed_tree']
        @arg2_leaves = Array.new
        nodes.each {|n|
            n.get_leaves(@arg2_leaves)
        }
        @arg2_leaves.sort! {|a,b| a.article_order <=> b.article_order}
    end

    def get_connective_leaves
        nodes = @article.gorns2nodes(self[5])
        ary = Array.new
        nodes.each {|n|
            n.get_leaves(ary)
        }

        @conn_leaves = Array.new
        ary2 = self[9].split
        i = 0
        ary.each {|l|
            break if ary2[i] == nil
            if l.value.downcase == ary2[i].downcase or
                (l.value.downcase == 'afterwards' and ary2[i].downcase == 'afterward')
                @conn_leaves.push(l)
                i += 1
            end
        }
    end

    def mark_attribution_spans
        (@attrs['parsed_tree'] + @attr1s['parsed_tree'] + @attr2s['parsed_tree']).each {|n|
            n.mark_attribution_leaves
        }
        @attrs['leaves'] = Array.new
        @attr1s['leaves'] = Array.new
        @attr2s['leaves'] = Array.new
        @attrs['parsed_tree'].each {|n| n.collect_attr_leaves(@attrs['leaves'])}
        @attr1s['parsed_tree'].each {|n| n.collect_attr_leaves(@attr1s['leaves'])}
        @attr2s['parsed_tree'].each {|n| n.collect_attr_leaves(@attr2s['leaves'])}
        unmark_punctuation_leaves(@attrs['leaves'])
        unmark_punctuation_leaves(@attr1s['leaves'])
        unmark_punctuation_leaves(@attr2s['leaves'])
    end

    def unmark_punctuation_leaves(leaves)
        leaves.each {|l|
            if $punctuations.include?(l.value)
                l.is_attr_leaf = false
            else
                break
            end
        }

        leaves.reverse.each {|l|
            if $punctuations.include?(l.value)
                l.is_attr_leaf = false
            else
                break
            end
        }
    end

    # return the gorn addresses in an array
    def gorn
        [self[5], self[21], self[24], self[31], self[34], self[41], self[44], self[47]]
    end

    def first_pos_in_article(i)
        range = self[i]
        first_pos = nil
        if range != ''
            first_pos = range[0...range.index("..")].to_i
        end
        first_pos
    end
  
    def gorn2sentences(i)
        gorn = self[i]
        dup_sents = gorn.gsub(/,\d+/, '').split(/;/, -1)
        dup_sents.uniq
    end
  
    def all_gorn_sentences
        [gorn2sentences(5)[0], gorn2sentences(21)[0],
            gorn2sentences(24)[0], gorn2sentences(31)[0],
            gorn2sentences(34)[0], gorn2sentences(41)[0],
            gorn2sentences(44)[0], gorn2sentences(47)[0]
        ]
    end

    def all_pos_sentences
        [first_pos_in_article(4), first_pos_in_article(20),
            first_pos_in_article(23), first_pos_in_article(30),
            first_pos_in_article(33), first_pos_in_article(40),
            first_pos_in_article(43), first_pos_in_article(46)
        ]
    end

    def in_same_sentence?
        id1, id2 = arg1_arg2_sentences2
        id1 == id2 ? true : false
    end

    def arg1_arg2_sentences2
        [@arg1_leaves.last.goto_tree.sent_id, @arg2_leaves.first.goto_tree.sent_id]
    end
    
    def arg1_arg2_sentences
        [gorn2sentences(24), gorn2sentences(34)]
    end

    def arg1_arg2_sentences_s
        args = arg1_arg2_sentences
        arg1 = args[0].join(",")
        arg2 = args[1].join(",")
        if arg1 == arg2
            res = arg1
        else
            res = arg1+"->"+arg2
        end
        
        # arg1 and arg2 are not adjacent
        if args[0][-1].to_i + 1 != args[1][0].to_i and args[0][-1].to_i != args[1][0].to_i + 1 and
                args[0][-1] != args[1][0]
            res = "(" + res + ")"
        end
        
        res
    end

    def share_argument?(rel2)
        return false if rel2 == nil
        arr1 = self[33].split(/\.\.|;/).map {|a| a.to_i}
        range1 = Range.new(arr1.min, arr1.max)
        arr2 = rel2[23].split(/\.\.|;/).map {|a| a.to_i}
        range2 = Range.new(arr2.min, arr2.max)

        len1 = range1.end - range1.begin
        len2 = range2.end - range2.begin
        if range1.include?(range2.begin) or range1.include?(range2.end)
            if len1 >= len2 and (len2.to_f / len1 >= 0.8)
                return true
            elsif len1 <= len2 and (len1.to_f / len2 >= 0.8)
                return true
            end
        end
        false
    end

    def embed_rel_in_arg1?(rel)
        return false if rel == nil
        arr = self[23].split(/\.\.|;/).map {|a| a.to_i}
        range = Range.new(arr.min, arr.max)
        arr1 = rel[23].split(/\.\.|;/).map {|a| a.to_i}
        arr2 = rel[33].split(/\.\.|;/).map {|a| a.to_i}
        
        if range.include?(arr1.min) and range.include?(arr1.max) and
            range.include?(arr2.min) and range.include?(arr2.max)
            return true
        end
        false
    end

    def embed_rel_in_arg2?(rel)
        return false if rel == nil
        arr = self[33].split(/\.\.|;/).map {|a| a.to_i}
        range = Range.new(arr.min, arr.max)
        arr1 = rel[23].split(/\.\.|;/).map {|a| a.to_i}
        arr2 = rel[33].split(/\.\.|;/).map {|a| a.to_i}
        
        if range.include?(arr1.min) and range.include?(arr1.max) and
            range.include?(arr2.min) and range.include?(arr2.max)
            return true
        end
        false
    end

    def arg1_before_arg2?
        relative_position(23, 33)
    end

    def relative_position(c1, c2) # 23, 33
        max = 0
        arg1_s = -1
        self[c1].split(';').each do |span|
            tokens = span.split('..')
            range = tokens[1].to_i - tokens[0].to_i
            if range > max
                max = range
                arg1_s = tokens[0].to_i
            end
        end

        max = 0
        arg2_s = -1
        self[c2].split(';').each do |span|
            tokens = span.split('..')
            range = tokens[1].to_i - tokens[0].to_i
            if range > max
                max = range
                arg2_s = tokens[0].to_i
            end
        end

        if arg1_s < arg2_s
            return true
        else
            return false
        end
    end

    def senses
        [self[12], self[13], self[14], self[15]].reject {|e| e == ''} .compact
    end

    def senses_sf
        t1 = short_form(self[1])
        tt =
        [self[12], self[13], self[14], self[15]].reject {|e| e == ''} .map {|e|
            t = e.split(/\./)
            t.map {|ee| short_form(ee)} .join('')
        } .uniq
        if not tt.empty? then
            tt.map {|t| t1+t}
        else
            [t1]
        end
    end

    def short_form(tag, level=2)
        case tag
        when 'Explicit'     then 'exp'
        when 'Implicit'     then 'imp'  
        when 'AltLex'       then 'alt'
        when 'EntRel'       then 'ent'
        when 'NoRel'        then 'nor'

        when 'Temporal'                     then 'Tem'
        when    'Synchrony'                 then level >= 2 ? 'Syn' : ''
        when    'Asynchronous'              then level >= 2 ? 'Asn' : ''
        when        'Precedence'            then level == 3 ? 'Prc' : ''
        when        'Succession'            then level == 3 ? 'Suc' : ''

        when 'Contingency'                  then 'Con'
        when    'Cause'                     then level >= 2 ? 'Cau' : ''
        when        'Reason'                then level == 3 ? 'Rsn' : ''
        when        'Result'                then level == 3 ? 'Rst' : ''
        when    'Pragmatic_cause'           then level >= 2 ? 'PCa' : ''
        when        'Justification'         then level == 3 ? 'Jus' : ''
        when    'Condition'                 then level >= 2 ? 'Cdn' : ''
        when        'Hypothetical'          then level == 3 ? 'Hyp' : ''
        when        'General'               then level == 3 ? 'Gnr' : ''
        when        'Unreal_present'        then level == 3 ? 'UPr' : ''
        when        'Unreal_past'           then level == 3 ? 'UPa' : ''
        when        'Factual_present'       then level == 3 ? 'FPr' : ''
        when        'Factual_past'          then level == 3 ? 'FPa' : ''
        when    'Pragmatic_condition'       then level >= 2 ? 'PCd' : ''
        when        'Relevance'             then level == 3 ? 'Rlv' : ''
        when        'Implicit_assertion'    then level == 3 ? 'IAs' : ''

        when 'Comparison'                   then 'Com'
        when    'Contrast'                  then level >= 2 ? 'Ctr' : ''
        when        'Juxtaposition'         then level == 3 ? 'Jux' : ''
        when        'Opposition'            then level == 3 ? 'Opp' : ''
        when    'Pragmatic_contrast'        then level >= 2 ? 'PCt' : ''
        when    'Concession'                then level >= 2 ? 'Ccs' : ''
        when        'Expectation'           then level == 3 ? 'Ept' : ''
        when        'Contra-expectation'    then level == 3 ? 'CEp' : ''
        when    'Pragmatic_concession'      then level >= 2 ? 'PCc' : ''

        when 'Expansion'                    then 'Exp'
        when    'Conjunction'               then level >= 2 ? 'Cjn' : ''
        when    'Instantiation'             then level >= 2 ? 'Ins' : ''
        when    'Restatement'               then level >= 2 ? 'Rsm' : ''
        when        'Specification'         then level == 3 ? 'Spn' : ''
        when        'Equivalence'           then level == 3 ? 'Eqv' : ''
        when        'Generalization'        then level == 3 ? 'Gnz' : ''
        when    'Alternative'               then level >= 2 ? 'Alt' : ''
        when        'Conjunctive'           then level == 3 ? 'Cjt' : ''
        when        'Disjunctive'           then level == 3 ? 'Djt' : ''
        when        'Chosen_alternative'    then level == 3 ? 'CAl' : ''
        when    'Exception'                 then level >= 2 ? 'Ecp' : ''
        when    'List'                      then level >= 2 ? 'Lst' : ''
        else 
            puts 'error!!!'
            puts tag
            exit
        end
    end

    def conns_and_types(full_types=false)
        arr = Array.new
        conns = discourse_connectives

        tmp_arr = Array.new
        tmp_arr.push(self[12]) if self[12] != ""
        tmp_arr.push(self[13]) if self[13] != ""
        types = full_types ? tmp_arr : level_1_types_for_conn1
        types.each do |type|
            arr.push([conns[0], type])
        end

        if conns[1]
            tmp_arr = Array.new
            tmp_arr.push(self[14]) if self[14] != ""
            tmp_arr.push(self[15]) if self[15] != ""
            types = full_types ? tmp_arr : level_1_types_for_conn2
            types.each do |type|
                arr.push([conns[1], type])
            end
        end

        arr
    end

    def conns_and_level_1_types(full_types=false)
        arr = Array.new
        conns = discourse_connectives

        tmp_arr = Array.new
        tmp_arr.push(self[12]) if self[12] != ""
        tmp_arr.push(self[13]) if self[13] != ""
        types = full_types ? tmp_arr : level_1_types_for_conn1
        types.each do |type|
            arr.push([conns[0], type])
        end

        if conns[1]
            tmp_arr = Array.new
            tmp_arr.push(self[14]) if self[14] != ""
            tmp_arr.push(self[15]) if self[15] != ""
            types = full_types ? tmp_arr : level_1_types_for_conn2
            types.each do |type|
                arr.push([conns[1], type])
            end
        end

        if arr.empty?
            nil
        else
            arr
        end
    end

    def conns_and_level_2_types(full_types=false)
        arr = Array.new
        conns = discourse_connectives

        tmp_arr = Array.new
        tmp_arr.push(self[12]) if self[12] != ""
        tmp_arr.push(self[13]) if self[13] != ""
        types = full_types ? tmp_arr : level_2_types_for_conn1
        types.each do |type|
            arr.push([conns[0], type])
        end

        if conns[1]
            tmp_arr = Array.new
            tmp_arr.push(self[14]) if self[14] != ""
            tmp_arr.push(self[15]) if self[15] != ""
            types = full_types ? tmp_arr : level_2_types_for_conn2
            types.each do |type|
                arr.push([conns[1], type])
            end
        end

        if arr.empty?
            nil
        else
            arr
        end
    end

    def discourse_connectives
        conns = Array.new
        conns.push(self[9].downcase)
        conns.push(self[10].downcase)
        conns.push(self[11].downcase)
        conns.delete('')
        conns.delete(nil)
        conns
    end

    def discourse_connectives2
        conns = Array.new
        conns.push(self[6]) # raw
        conns.push(self[10])
        conns.push(self[11])
        conns.delete('')
        conns.delete(nil)
        conns
    end

    def level_1_types_for_conn1
        level_1_types = Array.new
        types = self[12].split(/\./)
        level_1_types.push(types[0]) if not level_1_types.include?(types[0]) and types[0] != nil and types[0] != ''
        types = self[13].split(/\./)
        level_1_types.push(types[0]) if not level_1_types.include?(types[0]) and types[0] != nil and types[0] != ''
        level_1_types
    end

    def level_2_types_for_conn1
        level_2_types = Array.new
        types = self[12].split(/\./)
        level_2_types.push(types[1]) if not level_2_types.include?(types[1]) and types[1] != nil and types[1] != ''
        types = self[13].split(/\./)
        level_2_types.push(types[1]) if not level_2_types.include?(types[1]) and types[1] != nil and types[1] != ''
        level_2_types
    end

    def level_1_types_for_conn2
        level_1_types = Array.new
        types = self[14].split(/\./)
        level_1_types.push(types[0]) if not level_1_types.include?(types[0]) and types[0] != nil and types[0] != ''
        types = self[15].split(/\./)
        level_1_types.push(types[0]) if not level_1_types.include?(types[0]) and types[0] != nil and types[0] != ''
        level_1_types
    end

    def level_2_types_for_conn2
        level_2_types = Array.new
        types = self[14].split(/\./)
        level_2_types.push(types[1]) if not level_2_types.include?(types[1]) and types[1] != nil and types[1] != ''
        types = self[15].split(/\./)
        level_2_types.push(types[1]) if not level_2_types.include?(types[1]) and types[1] != nil and types[1] != ''
        level_2_types
    end

    def types_for_conn1
        types = Array.new
        types.push(self[12]) if self[12] != ''
        types.push(self[13]) if self[13] != ''
        types
    end

    def types_for_conn2
        types = Array.new
        types.push(self[14]) if self[14] != ''
        types.push(self[15]) if self[15] != ''
        types
    end
    
    # get `class'
    def level_1_types
        level_1_types = Array.new
        types = self[12].split(/\./)
        level_1_types.push(types[0]) if types[0] != nil and types[0] != ''
        types = self[13].split(/\./)
        level_1_types.push(types[0]) if types[0] != nil and types[0] != ''
        types = self[14].split(/\./)
        level_1_types.push(types[0]) if types[0] != nil and types[0] != ''
        types = self[15].split(/\./)
        level_1_types.push(types[0]) if types[0] != nil and types[0] != ''
        level_1_types.uniq!
        level_1_types
    end
    
    # get `type'
    def level_2_types
        level_2_types = Array.new
        types = self[12].split(/\./)
        level_2_types.push(types[1]) if types[1] != nil and types[1] != ''
        types = self[13].split(/\./)
        level_2_types.push(types[1]) if types[1] != nil and types[1] != ''
        types = self[14].split(/\./)
        level_2_types.push(types[1]) if types[1] != nil and types[1] != ''
        types = self[15].split(/\./)
        level_2_types.push(types[1]) if types[1] != nil and types[1] != ''
        level_2_types.uniq!
        level_2_types
    end

    # get `subtype'
    def level_3_type
        types = self[12].split(/\./)
        types[-1]
    end

    def get_production_rules(array, nary=-1, with_leaf=true)
        nodes = []
        nodes += @arg1s['parsed_tree'] if array.include?('arg1')
        nodes += @attr1s['parsed_tree'] if array.include?('attr1')
        nodes += @sup1s['parsed_tree'] if array.include?('sup1')
        nodes += @arg2s['parsed_tree'] if array.include?('arg2')
        nodes += @attr2s['parsed_tree'] if array.include?('attr2')
        nodes += @sup2s['parsed_tree'] if array.include?('sup2')

        rules = Hash.new(0)
        nodes.each do |node|
            node.get_production_rules(rules, nary, with_leaf)
            #node.get_production_dependency_rules(rules, nary)
        end
        rules
    end

    def get_dependency_rules(which, nary=-1, with_leaf=true, with_label=true, lemmatized=false)
        nodes = []
        nodes += @arg1s['parsed_tree'] if which.include?('arg1')
        nodes += @attr1s['parsed_tree'] if which.include?('attr1')
        nodes += @sup1s['parsed_tree'] if which.include?('sup1')
        nodes += @arg2s['parsed_tree'] if which.include?('arg2')
        nodes += @attr2s['parsed_tree'] if which.include?('attr2')
        nodes += @sup2s['parsed_tree'] if which.include?('sup2')

        rules = Hash.new(0)
        nodes.each do |node|
            node.get_dependency_rules(rules, nary, with_leaf, with_label, lemmatized)
        end
        rules
    end

    def get_tree_fragments(which, leaf_option, height=2)
        nodes = []
        nodes += @arg1s['parsed_tree'] if which.include?('arg1')
        nodes += @attr1s['parsed_tree'] if which.include?('attr1')
        nodes += @sup1s['parsed_tree'] if which.include?('sup1')
        nodes += @arg2s['parsed_tree'] if which.include?('arg2')
        nodes += @attr2s['parsed_tree'] if which.include?('attr2')
        nodes += @sup2s['parsed_tree'] if which.include?('sup2')

        cnt = Hash.new(0)
        nodes.each do |n|
            n.get_tree_fragments(cnt, leaf_option, height)
        end
        
        cnt
    end

    def check_subtrees(array, trees)
        nodes = []
        nodes += @arg1s['parsed_tree'] if array.include?('arg1')
        nodes += @attr1s['parsed_tree'] if array.include?('attr1')
        nodes += @sup1s['parsed_tree'] if array.include?('sup1')
        nodes += @arg2s['parsed_tree'] if array.include?('arg2')
        nodes += @attr2s['parsed_tree'] if array.include?('attr2')
        nodes += @sup2s['parsed_tree'] if array.include?('sup2')

        trees.each_key do |k|
            t = '( ' + k.gsub(/->/, '').gsub(/_+/, ' ').gsub(/\(([^ ]+?)\)/, '(\1 -ALL-)') + ' )'
            tree = Tree.new(t.dup, -1)

            trees[k] = false
            nodes.each do |n|
                subtree_root = n.has_subtree?(tree.root)
                if subtree_root
                    trees[k] = true
                    break
                end
            end
        end
    end

    def has_subtree?(which, tree)
        nodes =
            case which
            when 'arg1' then
                @arg1s['parsed_tree']
            when 'attr1' then
                @attr1s['parsed_tree']
            when 'sup1' then
                @sup1s['parsed_tree']
            when 'arg2' then
                @arg2s['parsed_tree']
            when 'attr2' then
                @attr2s['parsed_tree']
            when 'sup2' then
                @sup2s['parsed_tree']
            end

        nodes.each do |n|
            subtree_root = n.has_subtree?(tree.root)
            if subtree_root
                #tree2.print_tree
                return subtree_root
            end
        end

        false
    end

    def get_attribution_verbs
        attr_rel_nodes = @article.gorns2nodes(self[21])
        attr_arg1_nodes = @article.gorns2nodes(self[31])
        attr_arg2_nodes = @article.gorns2nodes(self[41])
        verbs = Array.new
        (attr_rel_nodes + attr_arg1_nodes + attr_arg2_nodes).each {|n|
            if ['VB', 'VBD', 'VBG', 'VBN', 'VBP', 'VBZ', 'VP', 'SBAR'].include?(n.value)
                n.find_head
                verbs << n.head_word
            end
        }
        verbs
    end

    def to_s1
        h = {23 => self[23], 30 => self[30], 33 => self[33], 40 => self[40], 43 => self[43], 46 => self[46]}
        h.each_key do |k|
            if h[k] != ""
                h[k] = h[k].split(/\.\.|;/)[0].to_i
            else
                h[k] = -1
            end
        end

        str = ''
        h.sort {|a,b| a[1] <=> b[1]} .each do |k,v|
            if v != -1
                case k
                when 23 then pref = 'arg1:  '+self[25]
                when 30 then pref = 'attr1: '+self[32]
                when 33 then pref = 'arg2:  '+self[35]
                when 40 then pref = 'attr2: '+self[42]
                when 43 then pref = 'sup1:  '+self[45]
                when 46 then pref = 'sup2:  '+self[48]
                end

                str += pref+"\n"
            end
        end
        str
    end

    def to_s
        "[" + col.join("] [") + "]"
    end
end
