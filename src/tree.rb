require File.dirname(__FILE__)+'/../lib/utils'
require File.dirname(__FILE__)+'/../lib/stemmable'
require File.dirname(__FILE__)+'/variable'
require 'pp'

class Tree
    attr_accessor :tree_text, :sent_id, :root, :dtree_root

    alias sid sent_id

    def initialize(tree_text, sent_id)
        @tree_text = tree_text
        @sent_id = sent_id
        @tree_text.gsub!(/\s+/, ' ')
        @tree_text.sub!(/^\(\s*\(\s*/, '')
        @tree_text.sub!(/\s*\)\s*\)$/, '')
        tokens = @tree_text.gsub('(', ' ( ').gsub(')', ' ) ').split()
        stack = Array.new()
        while not tokens.empty?
            token = tokens.shift()
            if token != ')'
                stack.push(token)
            else
                nodes = Array.new()
                while (popped = stack.pop()) != '('
                    nodes.unshift(popped)
                end
                node = Node.new(nodes.shift, nodes)
                node.tree = self
                stack.push(node)
            end
        end
        @root = Node.new(stack.shift, stack)
        @root.is_root = true
        @root.tree = self
        @root.post_order
        @root.travel_leaf_nodes
        @root.find_head
        lemmatize_leaves if $lemmatize
    end

    def lemmatize_leaves
        leaves = @root.my_leaves
        text = leaves.map {|l| l.v+'_'+l.up.v} .join("\n")
        tmp = '.lemmatize.'+rand.to_s
        File.open($tmp_prefix+tmp, 'w') {|f| f.puts text}
        arr = `#{Variable::MORPHA} -f #{Variable::VERBSTEM} < #{$tmp_prefix+tmp}` .split(/\n/)
        if arr.size != leaves.size then 
            puts 'lematize error!'
            puts leaves.map {|l| l.v} .join(' ')
            puts arr.join(' ')
            exit
        end
        leaves.each_index {|i| leaves[i].lemmatized = arr[i]}
    end

    def build_dependency_tree(dtree_text)
        pos_nodes = @root.get_all_pos_nodes
        pos_nodes.unshift(nil) # set pos_nodes[0] = nil, so that first pos is at idx 1
        rels = dtree_text.chomp.split("\n").map {|a| 
            if a != '_nil_' then
                label,w1,w2 = a.split(/\(|\)|, /);
                [w1[0...w1.rindex('-')], w1[w1.rindex('-')+1 ..-1].to_i,
                    w2[0...w2.rindex('-')], w2[w2.rindex('-')+1 ..-1].to_i, label]
            end
        } .compact
        p_nodes = Array.new
        rels.each { |rel| 
            p = pos_nodes[rel[1]].leaf_node
            c = pos_nodes[rel[3]].leaf_node
            label = rel.last
            p.dependents.push(c)
            c.depends_on = p
            c.dependency = label
            p_nodes << p
        }
        p_nodes.uniq.each {|p| @dtree_root = p if p.depends_on == nil}
    end

    def find_heads
        @root.find_head
    end

    def print_text
        text = ''
        print_text_r(root, text)
        text.gsub!(/\s+/, ' ')
        text
    end

    def print_text_r(node, text)
        if node.is_pos and not node.value.match(/-NONE-/)
            text << node.child_nodes[0].value << ' '
        else
            node.child_nodes.each do |n|
                print_text_r(n, text)
            end
        end
    end

    def print_tree
        print_tree_r('', @root)
    end

    def print_tree_r(prefix, node)
        if node.is_pos
            print prefix+node.value+' ('+node.head_word+')'
            puts ' '+node.child_nodes[0].value
        elsif not node.is_pos and not node.is_leaf
            puts prefix+node.value+' ('+node.head_word+')'
            node.child_nodes.each do |n|
                print_tree_r(prefix+'  ', n)
            end
        end
    end
end

class Node
    attr_accessor :child_nodes, :parent_node, :order_label, :range,
        :is_root, :is_pos, :is_leaf, :marked, :is_NONE_leaf, :is_attr_leaf, :in_relation, :in_p_relation, :is_conn, 
        :value, :orig_value, :fun_tag, :head_word, :head_word_idx, :head_word_ptr, :leaf_node,  
        :replace_value, :print_value,
        :first_leaf, :prev_leaf, :next_leaf, :edu_break,
        :leaf_orig_id, :article_order, :leaf_id_range,
        :included, :travel_cnt, :size,
        :lemmatized, :downcased, :normalized, :stemmed, :ner_value, 
        :span, :span_nodes, :tree,
        :dependents, :depends_on, :dependency,
        :sbar_1st_leaf

    alias up parent_node
    alias v value

    def initialize(value, child_nodes)
        @value = value
        @fun_tag = nil
        @replace_value = nil
        @print_value = @value
        @orig_value = value
        @child_nodes = child_nodes
        @parent_node = nil
        @head_word = ''
        @marked = false
        @is_root = false
        @is_pos = false
        @is_leaf = false
        @is_NONE_leaf = false
        @is_attr_leaf = false
        @in_relation = false
        @in_p_relation = false
        @is_conn = false
        @leaf_node = nil
        @pref_leaf = nil
        @next_leaf = nil
        @edu_break = false
        @leaf_orig_id = -1
        @article_order = -1
        @leaf_id_range = nil
        @included = false
        @travel_cnt = 0
        @size = 0
        @ner_value = 'O'
        @span = Array.new
        @span_nodes = Array.new
        @tree = nil
        @order_label = -1
        @range = nil
        @dependents = nil
        @depends_on = nil
        @dependency = nil
        @sbar_1st_leaf = false
        if @child_nodes.size == 1 and @child_nodes.first.class != Node
            @is_pos = true
            leaf_node = @child_nodes[0] = Node.new(@child_nodes.first, [])
            leaf_node.is_leaf = true
            leaf_node.value.gsub!(/_/, '-') if leaf_node.value.match(/_/)
            leaf_node.dependents = []
            leaf_node.downcased = leaf_node.value.downcase
            @leaf_node = @child_nodes[0]
            if @value.match(/-NONE-/)
                @leaf_node.is_NONE_leaf = true
            end
            leaf_node.stemmed = leaf_node.downcased.stem
        end

        if not @is_pos and @child_nodes.size > 0 #a non-terminal node
            @value.gsub!(/=\d+/, '')
            if @value.match('|')
                tokens = @value.split('|')
                @value = tokens[0]
            end
            if @value.match(/.-./) then
                @fun_tag = @value[@value.index('-')+1..-1]
                @fun_tag = @fun_tag.gsub(/\b\d+\b/,'').gsub(/--+/,'-').gsub(/^-|-$/,'')
                @fun_tag = nil if @fun_tag == ''
                @value = @value[0...@value.index('-')]
            end
        end

        if @is_pos
            @span.push(@child_nodes[0].downcased)
            @span_nodes.push(@child_nodes[0])
        elsif not @is_leaf
            @child_nodes.each do |node|
                next if node.value.match(/-NONE-/)
                @span.push(node.span)
                @span_nodes.push(node.span_nodes)
            end
            @span.flatten!
            @span_nodes.flatten!
        end
        if not @is_leaf
            @child_nodes.each {|n| n.parent_node = self}
        end
    end

    def get_all_nodes(with_leaves=false)
        all_nodes = []
        get_all_nodes_rec(all_nodes, with_leaves) 
        all_nodes
    end

    def get_all_nodes_rec(nodes, with_leaves=false)
        if @is_leaf then 
            nodes << self if with_leaves 
        else
            nodes << self
        end
        @child_nodes.each {|c| c.get_all_nodes_rec(nodes, with_leaves)}
    end

    def mark_edge_1st_leaves
        if (@value == 'SBAR' and @parent_node != nil and @parent_node.value == 'VP') or
              (@value == 'SINV' and @parent_node != nil and @parent_node.value == 'S') or
              (@value == 'S' and @parent_node != nil and @parent_node.value == 'S') or
              (@value == 'S' and @parent_node != nil and @parent_node.value == 'SINV') or
              (@value == 'SBAR' and @parent_node != nil and @parent_node.value == 'S')
            ary = Array.new
            get_leaves(ary)
            if not ary.empty?
                ary.first.sbar_1st_leaf = true 
                ary.last.next_leaf.sbar_1st_leaf = true if ary.last.next_leaf != nil
            end
            ary = nil
        end
        @child_nodes.each {|c|
            c.mark_edge_1st_leaves
        }
    end

    def left_sibling
        if @parent_node != nil
            i = @parent_node.child_nodes.index(self)
            if i > 0
                return @parent_node.child_nodes[i-1]
            end
        end
        nil
    end

    def all_left_siblings(remove_punc=false)
        if @parent_node != nil
            i = @parent_node.child_nodes.index(self)
            if i > 0 then
                if remove_punc then
                    return @parent_node.child_nodes[0 .. i-1].find_all {|n| not Variable::Punctuation_tags.include?(n.v)}
                else
                    return @parent_node.child_nodes[0 .. i-1]
                end
            end
        end
        []
    end

    def right_sibling
        if @parent_node != nil
            i = @parent_node.child_nodes.index(self)
            if i < @parent_node.child_nodes.size - 1
                return @parent_node.child_nodes[i+1]
            end
        end
        nil
    end

    def all_right_siblings(remove_punc=false)
        if @parent_node != nil
            i = @parent_node.child_nodes.index(self)
            if i < @parent_node.child_nodes.size - 1 then
                if remove_punc then
                    return @parent_node.child_nodes[i+1 ... @parent_node.child_nodes.size].find_all {|n| not Variable::Punctuation_tags.include?(n.v)}
                else
                    return @parent_node.child_nodes[i+1 ... @parent_node.child_nodes.size]
                end
            end
        end
        []
    end

    def right_siblings_contain(ary)
        all_right_siblings.each {|n|
            if ary.include?(n.v)
                return true
            end
        }
        false
    end

    def find_first_node_with(ary)
        return nil if @parent_node == nil
        ok = false
        ary.each {|v| 
            if @parent_node.value == v
                ok = true
                break
            end
        }
        if ok
            return @parent_node
        else
            return @parent_node.find_first_node_with(ary)
        end
    end

    def find_common_nodes(ary)
        if @travel_cnt < @size
            @child_nodes.each {|c| c.find_common_nodes(ary)}
        elsif @travel_cnt == @size and @size != 0
            ary.push(self)
        elsif @travel_cnt > @size
            puts "error: can't be @travel_cnt > @size"
            exit
        end
    end

    def label_node_size
        if @is_leaf and @is_NONE_leaf
            @size = 0
        elsif @is_leaf and not @is_NONE_leaf
            @size = 1
        else
            @size = @child_nodes.inject(0) {|sum, c| sum += c.label_node_size}
        end
        @size
    end

    def goto_tree
        if not @is_root
            @parent_node.goto_tree
        else
            @tree
        end
    end

    def replace_value_with(v)
        if @is_leaf
            @replace_value = v
        else
            @child_nodes.each {|n| n.replace_value_with(v)}
        end
    end

    def contains_node_with_value?(v)
        if @value == v
            return true
        else
            @child_nodes.each {|n|
                if n.contains_node_with_value?(v)
                    return true
                end
            }
            return false
        end
    end

    def contains_trace?
        if @is_NONE_leaf and @value.match(/^\*T\*-/)
            return true
        else
            @child_nodes.each {|n|
                if n.contains_trace?
                    return true
                end
            }
            return false
        end
    end

    def reset_travel_cnt
        if @travel_cnt != 0
            @travel_cnt = 0
            @child_nodes.each {|n| n.reset_travel_cnt}
        end
    end

    def my_leaves
        ary = Array.new
        get_leaves(ary)
        ary
    end

    def get_leaves(ary)
        if @is_leaf and not @is_NONE_leaf
            ary.push(self)
        else
            @child_nodes.each {|n| n.get_leaves(ary)}
        end
    end

    def mark_subtree_included
        @included = true
        @child_nodes.each {|n| n.mark_subtree_included}
    end

    def unmark_subtree_included
        @included = false
        @child_nodes.each {|n| n.unmark_subtree_included}
    end

    def collect_attr_leaves(ary)
        if @is_leaf
            if not @is_NONE_leaf
                ary.push(self)
            end
        else
            @child_nodes.each {|n| n.collect_attr_leaves(ary)}
        end
    end

    def mark_in_relation
        if @is_leaf 
            if not @is_NONE_leaf 
                @in_relation = true
            end
        else
            @child_nodes.each {|n| n.mark_in_relation}
        end
    end

    def mark_in_p_relation
        if @is_leaf 
            if not @is_NONE_leaf 
                @in_p_relation = true
            end
        else
            @child_nodes.each {|n| n.mark_in_p_relation}
        end
    end

    def mark_attribution_leaves
        if @is_leaf 
            if not @is_NONE_leaf 
                @is_attr_leaf = true
            end
        else
            @child_nodes.each {|n| n.mark_attribution_leaves}
        end
    end

    def get_curr_edu
        if @is_leaf and not @is_NONE_leaf
            if @edu_break
                @value
            else
                @value + ' ' +@next_leaf.get_curr_edu
            end
        end
    end

    def travel_leaf_nodes
        if @is_root
            $prev_leaf = nil
            $root = self
        end
        if @is_leaf
            if not @is_NONE_leaf
                if $prev_leaf != nil
                    $prev_leaf.next_leaf = self
                    self.prev_leaf = $prev_leaf
                else
                    $root.first_leaf = self
                end
                $prev_leaf = self
            end
        else
            @child_nodes.each {|n| n.travel_leaf_nodes}
        end
    end

    def post_order
        $order_label = 0 if @is_root
        $curr_id = 0 if @is_root
        if @is_pos
            if not @value.match(/-NONE-/)
                $order_label += 1
                @order_label = $order_label
                @range = Range.new(@order_label, @order_label)
            end
            $curr_id += 1
            @leaf_node.leaf_orig_id = $curr_id
            @leaf_id_range = Range.new($curr_id, $curr_id)
        else
            @order_label = @child_nodes.inject(0) {|sum,n| n.post_order; sum += n.order_label} .to_f / @child_nodes.size
            @range = Range.new(@child_nodes.first.order_label, @child_nodes.last.order_label)

            @leaf_id_range = Range.new(@child_nodes.first.leaf_id_range.first, @child_nodes.last.leaf_id_range.last)
        end
    end

    def include?(node)
        if self.tree.send_id == node.tree.send_id
            self.range.include?(node.range.first) and self.range.include?(node.range.last)
        else
            false
        end
    end

    def get_unmarked_nodes(nodes)
        if @marked
            return false
        else
            arr = @child_nodes.map {|n| n.get_unmarked_nodes(nodes)}
            if arr.include?(false)
                arr.each {|n| nodes << n if n != false}
                return false
            else
                if @is_root
                    nodes << self
                else
                    return self
                end
            end
        end
    end

    def get_all_pos_nodes
        if not @is_pos
            @child_nodes.map {|n| n.get_all_pos_nodes} .flatten.compact
        else
            if not @value.match(/-NONE-/)
                [self]
            else
                []
            end
        end
    end

    # pos and words are arrays
    def get_words_by_POS(pos, words)
        if not @is_pos
            @child_nodes.each do |n|
                n.get_words_by_POS(pos, words)
            end
        elsif pos.include?(@value)
            words.push([@child_nodes[0].value, @value])
        end
    end

    # leaf_option: 
    # 1 - combine leaf in tree; 
    # 2 - only in POS->leaf rules;
    # 3 - no leaf
    def get_tree_fragments(tree_cnts, leaf_option, height=2)
        if not @is_pos
            my_trees = ['('+@value+')']
            arr_arr = @child_nodes.select {|c| not c.value.match(/-NONE-/)} .map { 
                |c| c.get_tree_fragments(tree_cnts, leaf_option, height) 
            }
            #if arr_arr.size <= width
            combis = Utils.cartesian_product(*arr_arr).map { |arr| arr.compact } .uniq
            combis.each do |arr|
                c = arr.join(' ')
                if c != ''
                    t = '(' + @value + ' -> ' + c + ')'
                    max = 0
                    t.split(//).inject(0) { |cnt, a| 
                        if a == '(' 
                            cnt += 1 
                        elsif a == ')' 
                            cnt -= 1 
                        end
                        max = cnt if cnt > max
                        cnt
                    }
                    if height == -1
                        tree_cnts[t] += 1
                        my_trees.push(t)
                    else
                        if max <= height + 1
                            tree_cnts[t] += 1
                        end
                        if max < height + 1
                            my_trees.push(t)
                        end
                    end
                end
            end
            my_trees
        else
            case leaf_option  
            when 1 then 
                tree_cnts['('+@value+' -> ('+@leaf_node.value+'))'] += 1
                ['('+@value+')', '('+@value+' -> ('+@leaf_node.value+'))']
            when 2 then 
                tree_cnts['('+@value+' -> ('+@leaf_node.value+'))'] += 1
                ['('+@value+')']
            when 3 then 
                ['('+@value+')']
            end
        end
    end

    def get_dependency_rules(rule_cnts, nary=2, with_leaf=true, with_label=true, lemmatized=false)
        leaf_nodes = get_all_pos_nodes.map {|pn| pn.leaf_node}
        leaf_nodes.each {|n|
            rule = (lemmatized ? n.lemmatized : n.value)+' <-'
            #rule = '* <-'
            n_dependents = n.dependents.select {|d| leaf_nodes.include?(d)}
            if nary != -1 and n_dependents.size > nary
                for i in (0 .. n_dependents.size-nary)
                    rule2 = rule+' '+
                        case [with_leaf, with_label]
                        when [true,true] then 
                            n_dependents[i ... i+nary].map {|n1| '<'+n1.dependency+'>'+n1.value} .join(' ')
                        when [true,false] then
                            n_dependents[i ... i+nary].map {|n1| n1.value} .join(' ')
                        when [false,true] then
                            n_dependents[i ... i+nary].map {|n1| '<'+n1.dependency+'>'} .join(' ')
                        end
                    rule_cnts[rule2] += 1
                end
            else
                rule2 = rule+' '+
                    case [with_leaf, with_label]
                    when [true,true] then 
                        n_dependents.map {|n1| '<'+n1.dependency+'>'+n1.value} .join(' ')
                    when [true,false] then
                        n_dependents.map {|n1| n1.value} .join(' ')
                    when [false,true] then
                        n_dependents.map {|n1| '<'+n1.dependency+'>'} .join(' ')
                    end
                if not rule2.match(/<- ?$/) # rule has some child values
                    rule_cnts[rule2] += 1
                end
            end
        }
    end

    def get_production_dependency_rules(rule_cnts, nary=2)
        get_production_rules(rule_cnts, nary, true)
        get_dependency_rules(rule_cnts, 1, true, true, false)
    end

    def get_production_rules(rule_cnts, nary=2, with_leaf=true)
        if not @is_pos 
            if value.match(/.-./)
                rule = value[0...value.index('-')]+' ->'
            else
                rule = value+' ->'
            end
            child_node_ptr = @child_nodes.reject {|n| n.value.match(/-NONE-/)}
            if nary != -1 and child_node_ptr.size > nary
                for i in (0 .. child_node_ptr.size-nary)
                    rule2 = rule+' '+
                        child_node_ptr[i ... i+nary].map {|n| n.value} .join(' ')
                    rule_cnts[rule2] += 1
                end
            else
                child_node_ptr.each do |n|
                    rule += ' '+n.value
                end
                if not rule.match(/->$/) # rule has some child values
                    rule_cnts[rule] += 1
                end
            end
            child_node_ptr.each do |n|
                n.get_production_rules(rule_cnts, nary, with_leaf)
            end
        elsif with_leaf and not @value.match(/-NONE-/)
            rule_cnts[@value+' -> '+@leaf_node.value] += 1
        end
    end

    def get_included_production_rules(rule_cnts, nary=2, with_leaf=true)
        if not @is_pos and @included
            if value.match(/.-./)
                rule = value[0...value.index('-')]+' ->'
            else
                rule = value+' ->'
            end
            child_node_ptr = @child_nodes.reject {|n| n.value.match(/-NONE-/)}
            if nary != -1 and child_node_ptr.size > nary
                for i in (0 .. child_node_ptr.size-nary)
                    rule2 = rule+' '+
                        child_node_ptr[i ... i+nary].map {|n| n.included ? n.value : '@'} .join(' ')
                    rule_cnts[rule2] += 1
                end
            else
                child_node_ptr.each do |n|
                    if n.included
                        rule += ' '+n.value
                    else
                        rule += ' @'
                    end
                end
                if not rule.match(/->$/) # rule has some child values
                    rule_cnts[rule] += 1
                end
            end
            child_node_ptr.each do |n|
                if n.included
                    n.get_included_production_rules(rule_cnts, nary, with_leaf)
                end
            end
        elsif with_leaf and not @value.match(/-NONE-/) and @included
            rule_cnts[@value+' -> '+@leaf_node.value] += 1
        end
    end

    def relative_position(parent_n, child_n)
        ''
    end

    def get_compact_rule(rule_cnts)
        if not @is_pos #and @marked
            rule = value+' ->'
            @child_nodes.each do |n|
                next if n.value.match(/-NONE-/)
                rule += ' '+n.value
            end
            if rule.match(/(([^ ]+) , )+\2( ,)? CC( ,)? \2/)
                rule.sub!(/(([^ ]+) , )+\2( ,)? CC( ,)? \2/, "\\2 CC \\2")
            end
            if not rule.match(/->$/) # rule has some child values
                rule_cnts[rule] += 1
            end
            @child_nodes.each do |n|
                n.get_compact_rule(rule_cnts)
            end
        end
    end

    def get_headed_rule(rule_cnts)
        if not @is_pos #and @marked
            rule = ''
            rule = value+'('+@head_word+')'+' ->'
            @child_nodes.each do |n|
                next if n.value.match(/-NONE-/)
                #rule += ' '+n.value+'('+n.head_word+')'
                rule += ' '+n.value
            end
            if not rule.match(/->$/) # rule has some child values
                rule_cnts[rule] += 1
            end
            @child_nodes.each do |n|
                n.get_headed_rule(rule_cnts)
            end
        end
    end

    def get_path(path_cnts)
        if not @is_pos #and @marked
            c = ''
            if value.match(/.-./)
                c = value[0...value.index('-')]
            else
                c = value
            end
            @child_nodes.each do |n1|
                next if n1.value.match(/-NONE-/) or n1.is_pos
                if n1.value.match(/.-./)
                    c1 = n1.value[0...n1.value.index('-')]
                else
                    c1 = n1.value
                end
                n1.child_nodes.each do |n2|
                    next if n2.value.match(/-NONE-/) 
                    if n2.value.match(/.-./)
                        c2 = n2.value[0...n2.value.index('-')]
                    else
                        c2 = n2.value
                    end
                    path_cnts[c+'--'+c1+'--'+c2] += 1
                end
            end
            @child_nodes.each do |n|
                n.get_path(path_cnts)
            end
        end
    end

    def get_headed_path(path_cnts)
        if not @is_pos #and @marked
            c = @value+'('+@head_word+')'
            @child_nodes.each do |n1|
                next if n1.value.match(/-NONE-/) or n1.is_pos
                c1 = n1.value+'('+n1.head_word+')'
                n1.child_nodes.each do |n2|
                    next if n2.value.match(/-NONE-/) 
                    c2 = n2.value+'('+n2.head_word+')'
                    path_cnts[c+'--'+c1+'--'+c2] += 1
                end
            end
            @child_nodes.each do |n|
                n.get_headed_path(path_cnts)
            end
        end
    end

    def get_path_4(path_cnts)
        if not @is_pos #and @marked
            c = ''
            if value.match(/.-./)
                c = value[0...value.index('-')]
            else
                c = value
            end
            @child_nodes.each do |n1|
                next if n1.value.match(/-NONE-/) or n1.is_pos
                if n1.value.match(/.-./)
                    c1 = n1.value[0...n1.value.index('-')]
                else
                    c1 = n1.value
                end
                n1.child_nodes.each do |n2|
                    next if n2.value.match(/-NONE-/) or n2.is_pos 
                    if n2.value.match(/.-./)
                        c2 = n2.value[0...n2.value.index('-')]
                    else
                        c2 = n2.value
                    end
                    n2.child_nodes.each do |n3|
                        next if n3.value.match(/-NONE-/)  
                        if n3.value.match(/.-./)
                            c3 = n3.value[0...n3.value.index('-')]
                        else
                            c3 = n3.value
                        end
                        path_cnts[c+'--'+c1+'--'+c2+'--'+c3] += 1
                    end
                end
            end
            @child_nodes.each do |n|
                n.get_path(path_cnts)
            end
        end
    end

    def find_head
        if @is_leaf
            return
        elsif @is_pos
            if @value.match(/-NONE-/)
                @head_word = ''
                @head_word_ptr = nil
            else
                @head_word = @child_nodes[0].downcased
                @head_word_ptr = @child_nodes[0]
            end
            @head_word_idx = 0
            return
        end

        @child_nodes.each do |node|
            node.find_head
        end

        if @value == 'NP'
            found = false
            last_node = @child_nodes.last
            while not last_node.is_pos
                last_node = last_node.child_nodes.last
            end
            if last_node.value == 'POS'
                @head_word = last_node.head_word
                @head_word_ptr = last_node.head_word_ptr
                @head_word_idx = @child_nodes.size - 1
                found = true
            end

            if not found
                value_list = %w/NN NNP NNPS NNS NX POS JJR/
                (@child_nodes.size - 1).downto(0) do |idx|
                    node = @child_nodes[idx]
                    if value_list.include?(node.value)
                        @head_word = node.head_word
                        @head_word_ptr = node.head_word_ptr
                        @head_word_idx = idx
                        found = true
                    end
                end
            end

            if not found
                @child_nodes.each_index do |idx|
                    node = @child_nodes[idx]
                    if node.value == 'NP'
                        @head_word = node.head_word
                        @head_word_ptr = node.head_word_ptr
                        @head_word_idx = idx
                        found = true
                    end
                end
            end

            if not found
                value_list = %w/$ ADJP PRN/
                (@child_nodes.size - 1).downto(0) do |idx|
                    node = @child_nodes[idx]
                    if value_list.include?(node.value)
                        @head_word = node.head_word
                        @head_word_ptr = node.head_word_ptr
                        @head_word_idx = idx
                        found = true
                    end
                end
            end

            if not found
                (@child_nodes.size - 1).downto(0) do |idx|
                    node = @child_nodes[idx]
                    if node.value == 'CD'
                        @head_word = node.head_word
                        @head_word_ptr = node.head_word_ptr
                        @head_word_idx = idx
                        found = true
                    end
                end
            end

            if not found
                value_list = %w/JJ JJS RB QP/
                (@child_nodes.size - 1).downto(0) do |idx|
                    node = @child_nodes[idx]
                    if value_list.include?(node.value)
                        @head_word = node.head_word
                        @head_word_ptr = node.head_word_ptr
                        @head_word_idx = idx
                        found = true
                    end
                end
            end

            @head_word = @span.last
            @head_word_ptr = @span_nodes.last
            @head_word_idx = @child_nodes.size - 1
            @head_word = '' if @head_word == nil
        else
            case @value
            when 'ADJP' then
                direction = 'Left'
                priority_list = %w/NNS QP NN $ ADVP JJ VBN VBG ADJP JJR NP JJS DT FW RBR RBS SBAR RB/
            when 'ADVP' then
                direction = 'Right'
                priority_list = %w/RB RBR RBS FW ADVP TO CD JJR JJ IN NP JJS NN/
            when 'CONJP' then
                direction = 'Right'
                priority_list = %w/CC RB IN/
            when 'FRAG' then
                direction = 'Right'
                priority_list = %w//
            when 'INTJ' then
                direction = 'Left'
                priority_list = %w//
            when 'LST' then
                direction = 'Right'
                priority_list = %w/LS :/
            when 'NAC' then
                direction = 'Left'
                priority_list = %w/NN NNS NNP NNPS NP NAC EX $ CD QP PRP VBG JJ JJS JJR ADJP FW/
            when 'PP' then
                direction = 'Right'
                priority_list = %w/IN TO VBG VBN RP FW/
            when 'PRN' then
                direction = 'Left'
                priority_list = %w//
            when 'PRT' then
                direction = 'Right'
                priority_list = %w/RP/
            when 'QP' then
                direction = 'Left'
                priority_list = %w/$ IN NNS NN JJ RB DT CD NCD QP JJR JJS/
            when 'RRC' then
                direction = 'Right'
                priority_list = %w/VP NP ADVP ADJP PP/
            when 'S' then
                direction = 'Left'
                priority_list = %w/TO IN VP S SBAR ADJP UCP NP/
            when 'SBAR' then
                direction = 'Left'
                priority_list = %w/WHNP WHPP WHADVP WHADJP IN DT S SQ SINV SBAR FRAG/
            when 'SBARQ' then
                direction = 'Left'
                priority_list = %w/SQ S SINV SBARQ FRAG/
            when 'SINV' then
                direction = 'Left'
                priority_list = %w/VBZ VBD VBP VB MD VP S SINV ADJP NP/
            when 'SQ' then
                direction = 'Left'
                priority_list = %w/VBZ VBD VBP VB MD VP SQ/
            when 'UCP' then
                direction = 'Right'
                priority_list = %w//
            when 'VP' then
                direction = 'Left'
                priority_list = %w/TO VBD VBN MD VBZ VB VBG VBP VP ADJP NN NNS NP/
            when 'WHADJP' then
                direction = 'Left'
                priority_list = %w/CC WRB JJ ADJP/
            when 'WHADVP' then
                direction = 'Right'
                priority_list = %w/CC WRB/
            when 'WHNP' then
                direction = 'Left'
                priority_list = %w/WDT WP WP$ WHADJP WHPP WHNP/
            when 'WHPP' then
                direction = 'Right'
                priority_list = %w/IN TO FW/
            else ## 'NX'
                direction = 'Left'
                priority_list = %w//
            end

            children = direction == 'Left' ? @child_nodes : @child_nodes.reverse

            found = false
            catch :OUTER do
                priority_list.each do |wanted_value|
                    if direction == 'Left'
                        @child_nodes.each_index do |idx|
                            child = @child_nodes[idx]
                            if child.value == wanted_value
                                @head_word = child.head_word
                                @head_word_ptr = child.head_word_ptr
                                @head_word_idx = idx
                                found = true
                                throw :OUTER
                            end
                        end
                    else
                        (@child_nodes.size - 1).downto(0) do |idx|
                            child = @child_nodes[idx]
                            if child.value == wanted_value
                                @head_word = child.head_word
                                @head_word_ptr = child.head_word_ptr
                                @head_word_idx = idx
                                found = true
                                throw :OUTER
                            end
                        end
                    end
                end
            end

            if not found
                if direction == 'Left'
                    @head_word = @span.first
                    @head_word_ptr = @span_nodes.first
                    @head_word_idx = 0
                else
                    @head_word = @span.last
                    @head_word_ptr = @span_nodes.last
                    @head_word_idx = @child_nodes.size - 1
                end
                @head_word = '' if @head_word == nil
            end
        end

        if @child_nodes[@head_word_idx - 1].value == 'CC' and @head_word_idx > 1
            @head_word_idx = @head_word_idx - 2
            @head_word = @child_nodes[@head_word_idx].head_word
            @head_word_ptr = @child_nodes[@head_word_idx].head_word_ptr
        end
    end

    def count_node(value, cnt)
        if not @is_leaf
            if value == @value
                cnt[0] += 1
            end
            @child_nodes.each do |n|
                n.count_node(value, cnt)
            end
        end
    end

    def has_subtree_node?(node)
        @child_nodes.each do |c|
            if c == node then
                return true
            else
                c.has_subtree_node?(node)
            end
        end
        false
    end

    def has_subtree?(node)
        #return false if not @marked

        values = node.value.split('|')
        if values.include?(@value)
            result = match_subtree?(node)
            if result
                return self
            end
        end

        @child_nodes.each do |n|
            subtree = n.has_subtree?(node)
            if not n.is_leaf and subtree
                return subtree
            end
        end
        false
    end

    def has_child_value?(v)
        @child_nodes.each {|n|
            if n.value == v
                return true
            end
        }
        false
    end

    def match_child_value?(ary)
        ary.each {|v|
            if has_child_value?(v)
                return true
            end
        }
        false
    end

    def match_subtree?(node)
        if node.value == '-ALL-'
            return true
        elsif node.value.split('|').include?(@value)
            all_matched = true
            child_nodes2 = @child_nodes.dup
            node.child_nodes.each do |n1|
                matched = false
                while n2 = child_nodes2.shift
                    if n2.match_subtree?(n1)
                        matched = true
                        break
                    end
                end

                if not matched
                    all_matched = false
                    break
                end
            end
            
            if all_matched
                return true
            else
                return false
            end
        else
            return false
        end
    end

    def to_text
        if @is_leaf and not @is_NONE_leaf
            @value + ' '
        else
            @child_nodes.inject('') {|str,n| str += n.to_text}
        end
    end

    def to_s
        if @is_pos
            '(' + @value + ' ' + @child_nodes[0].value + ')'
        else
            '(' + @value + ' ' + @child_nodes.inject('') {|str,n| str += n.to_s} + ')'
        end
    end

    def print_subtree_at_node(prefix='')
        if @is_pos
            print prefix+@value+'('+@head_word+')'+@order_label.to_s
            puts ' '+@child_nodes[0].value
            #$stat_hash[@child_nodes[0].value.downcase] += 1
        elsif not @is_pos and not @is_leaf
            puts prefix+@value+'('+@head_word+')'+@order_label.to_s
            @child_nodes.each do |n|
                n.print_subtree_at_node(prefix+'  ')
            end
        end
    end

    def mark_as_included
        return if @is_leaf 
        @marked = true
    end

    def mark_child_nodes
        return if @is_leaf 
        @marked = true
        @child_nodes.each do |n|
            n.mark_child_nodes
        end
    end

    def collect_words(list)
        return if value == '-NONE-'
        if @is_leaf 
            list.push(lemmatized)
        end
        @child_nodes.each do |n|
            n.collect_words(list)
        end
    end
end