class Sentence
    attr_accessor :parsed_tree, :id, :clauses, :edus, :leaves, 
        :connectives, :connective_flags, :disc_connectives, :disc_connectives_p

    def initialize(parsed_tree, id)
        @parsed_tree = parsed_tree
        @id = id
        @leaves = Array.new
        @clauses = Array.new
        @edus = Array.new
        @connectives = Array.new
        @connective_flags = Array.new
        @disc_connectives = Array.new
        @disc_connectives_p = Array.new
        curr = @parsed_tree.root.first_leaf
        while curr != nil
            leaves.push(curr)
            curr = curr.next_leaf
        end
        #@clauses.push(@leaves)
        break_clauses
        break_clauses2
    end

    def first_leaf
        @parsed_tree.root.first_leaf
    end

    def root
        @parsed_tree.root
    end

    def get_internal_nodes(remove_pos_nodes=false)
        nodes = root.get_all_nodes
        nodes.delete_if {|n| n.is_pos} if remove_pos_nodes
        nodes
    end

    def get_production_rules(nary=-1, with_leaf=true)
        rules = Hash.new(0)
        @parsed_tree.root.get_production_rules(rules, nary, with_leaf)
        rules
    end

    def get_dependency_rules(nary=-1, with_leaf=true, with_label=true, lemmatized=false)
        rules = Hash.new(0)
        @parsed_tree.root.get_dependency_rules(rules, nary, with_leaf, with_label, lemmatized)
        rules
    end

    def match_conn_leaves_with_SBAR(conn_leaves)
        if conn_leaves.size == 1
            c1 = conn_leaves.first
            if ((c1.downcased.match(/\b(after|although|as|because|before|if|once|since|though|unless|until|whereas|while)\b/) and c1.up.v == 'IN') or 
                ((c1.downcased == 'as' or c1.downcased == 'so') and c1.up.v == 'RB')) and
                c1.up.up.v == 'SBAR' and
                c1.up.right_siblings_contain(%w/S FRAG/)
                return c1.up.up
            end
        else
            c1 = conn_leaves.first
            c2 = conn_leaves.last
            ws = c1.downcased + ' ' + c2.downcased
            if (((ws == 'so that' or ws == 'as if' or ws == 'as though') and c1.up.v == 'IN' and c2.up.v == 'IN') or
                (ws == 'now that' and c1.up.v == 'RB' and c2.up.v == 'IN') or
                (ws == 'much as' and c1.up.v == 'RB' and c1.up.up.v == 'ADVP' and c2.up.v == 'IN')) and
                c2.up.up.v == 'SBAR' and
                c2.up.right_siblings_contain(%w/S FRAG/)
                return c2.up.up
            end
        end

        nil
    end

    def break_with_structure(conn_leaves)
        arg1_node = arg2_node = nil
        c1 = conn_leaves.first
        str = conn_leaves.map {|l| l.downcased} .join(' ')
        arg2_leaves = Array.new
        arg1_leaves = Array.new
        if (sbar = match_conn_leaves_with_SBAR(conn_leaves)) != nil
            arg2_node = sbar
            arg1_node = sbar.find_first_node_with(%w/S SBARQ SQ SINV/)
        elsif str == 'as soon as'
            arg2_node = conn_leaves.last.up.up.up
            arg1_node = arg2_node.find_first_node_with(%w/S/)
        elsif str == 'by then'
            arg2_node = c1.up.up.up
            arg1_node = arg2_node.find_first_node_with(%w/S/)
        elsif str == 'in fact'
            arg2_node = c1.up.up.up
            arg1_node = arg2_node.find_first_node_with(%w/S/)
        elsif str == 'as a result'
            arg2_node = c1.up.up.up
            arg1_node = arg2_node.find_first_node_with(%w/S/)
        elsif str == 'hence' and 
              c1.up.up.up.v == 'UCP' and 
              c1.up.up.right_sibling.v == 'NP'
            arg2_node = c1.up.up.right_sibling
            arg1_node = c1.up.up.up
        elsif str == 'therefore' and
              c1.up.up.up.v == 'UCP' and
              c1.up.up.right_sibling.v == 'ADJP'
            arg2_node = c1.up.up.right_sibling
            arg1_node = arg2_node.find_first_node_with(%w/S/)
        elsif str == 'when' and 
              c1.up.v == 'WRB' and c1.up.up.v == 'WHADVP' and c1.up.up.up.v == 'SBAR'
            arg2_node = c1.up.up.up
            arg1_node = arg2_node.find_first_node_with(%w/S SBARQ/)
        elsif (str == 'after' or str == 'before' or str == 'since') and
              c1.up.v == 'IN' and c1.up.up.v == 'PP' and c1.up.right_siblings_contain(%w/S NP/) 
            arg2_node = c1.up.up
            arg1_node = arg2_node.find_first_node_with(%w/S/)
        elsif (str == 'for example' or str == 'for instance') and
              (c1.up.up.up.v == 'PRN' or c1.up.up.up.v == 'S')
            arg2_node = c1.up.up.up
            arg1_node = arg2_node.find_first_node_with(%w/S/)
        elsif str.match(/\b(and|but|or|nor|yet)\b/) and 
              c1.up.v == 'CC' and c1.up.up.v.match(/\b(S|SBAR|VP|SINV|UCP)\b/)
            c1.up.all_right_siblings.each {|n| n.get_leaves(arg2_leaves)}
            arg1_node = c1.up.up
            if arg1_node.v == 'VP' and arg1_node.up.v == 'S'
                arg1_node = arg1_node.up
            end
        elsif str == 'so' and 
              (c1.up.v == 'IN' or c1.up.v == 'RB') and c1.up.up.v == 'S'
            c1.up.all_right_siblings.each {|n| n.get_leaves(arg2_leaves)}
            arg1_node = c1.up.up
        elsif (str == 'so' or str == 'then') and
              c1.up.v == 'RB' and c1.up.left_sibling != nil and c1.up.left_sibling.v == 'CC' and 
              c1.up.up.v.match(/\b(S|SBAR|VP)\b/)
            c1.up.all_right_siblings.each {|n| n.get_leaves(arg2_leaves)}
            arg1_node = c1.up.up
            if arg1_node.v == 'VP' and arg1_node.up.v == 'S'
                arg1_node = arg1_node.up
            end
        elsif str == 'then' and
              c1.up.v == 'RB' and c1.up.up.v == 'VP' and c1.up.right_sibling.v == 'VP'
            arg2_node = c1.up.right_sibling
            arg1_node = arg2_node.find_first_node_with(%w/S/)
        elsif str == 'simultaneously' and
              c1.up.v == 'RB' and c1.up.up.v == 'ADVP' and c1.up.up.up.v == 'VP' and c1.up.up.up.up.v == 'VP' and
              c1.up.up.up.left_sibling.v == 'CC' 
            arg2_node = c1.up.up.up
            arg1_node = c1.up.up.up.up
        elsif str == 'and' and
              c1.up.v == 'CC' and c1.up.up.v == 'PRN' 
            arg2_node = c1.up.up
            arg1_node = arg2_node.find_first_node_with(%w/S/)
        elsif str == 'thus' and
              (c1.up != nil and c1.up.v == 'RB') and (c1.up.up != nil and c1.up.up.v == 'ADVP') and 
              (c1.up.up.up != nil and c1.up.up.up.v == 'VP') and 
              (c1.up.up.left_sibling != nil and c1.up.up.left_sibling.v == 'CC')
            c1.up.up.all_right_siblings.each {|n| n.get_leaves(arg2_leaves)}
            arg1_node = c1.up.up.up.find_first_node_with(%w/S/)
        elsif (str == 'rather' or str == 'later') and
              c1.up.v == 'RB' and c1.up.up.v == 'ADVP' and c1.up.up.up.v == 'VP' and c1.up.up.up.up.v == 'S'
            arg2_node = c1.up.up.up.up
            arg1_node = arg2_node.find_first_node_with(%w/S/)
        elsif str.match(/\b(then|accordingly|still|earlier|consequently)\b/) and
              (c1.up.v == 'RB' or c1.up.v == 'RBR') and c1.up.up.v == 'ADVP' and c1.up.up.up.v == 'VP'
            arg2_node = c1.up.up.up
            arg1_node = arg2_node.find_first_node_with(%w/S/)
        elsif str.match(/\b(thus|though|once|earlier|nevertheless)\b/) and
              (c1.up.v == 'RB' or c1.up.v == 'RBR') and c1.up.up.v == 'ADVP' and c1.up.up.up.v == 'S'
            arg2_node = c1.up.up.up
            arg1_node = arg2_node.find_first_node_with(%w/S/)
        elsif str == 'still' and
              c1.up.v == 'RB' and c1.up.up.v == 'ADVP' and 
              (c1.up.up.left_sibling != nil and c1.up.up.left_sibling.v == 'NP') and 
              (c1.up.up.right_sibling != nil and c1.up.up.right_sibling.v == 'VP')
            [c1.up.up.left_sibling, c1.up.up.right_sibling].each {|n| n.get_leaves(arg2_leaves)}
            arg1_node = c1.up.up.up
        else 
            return [nil, nil]
        end

        if arg1_node == nil
            return [nil, nil]
        end

        if arg1_node.v == 'S' and
              arg1_node.up != nil and 
              (arg1_node.up.v == 'SBAR' or 
              (arg1_node.up.v == 'PP' and arg1_node.left_sibling.v == 'IN'))
            arg1_node = arg1_node.up
        end

        if arg2_leaves.empty?
            arg2_node.get_leaves(arg2_leaves)
            arg2_leaves = arg2_leaves - conn_leaves
        end
        arg1_node.get_leaves(arg1_leaves)
        arg1_leaves = arg1_leaves - arg2_leaves - conn_leaves

        [arg1_leaves, arg2_leaves]
    end

    def break_with(conn_leaves)
        ary = Array.new
        @leaves.each {|l|
            if conn_leaves.include?(l)
                ary.push(nil)
            else
                ary.push(l)
            end
        }
        (ary.size-1).downto(1) {|i|
            ary.delete_at(i) if ary[i] == nil and ary[i-1] == nil
        }
        clauses = Array.new
        curr_clause = Array.new
        ary.each {|a|
            if a != nil
                curr_clause.push(a)
            else
                clauses.push(curr_clause) if curr_clause != []
                curr_clause = Array.new
            end
        }
        clauses.push(curr_clause) if curr_clause != []
        clauses
    end

    # this method uses clauses or edus
    def break_with2(conn_leaves, use_edus=false)
        a1 = Array.new
        a2 = Array.new
        idx = nil
        clauses = use_edus ? @edus : @clauses
        clauses.each_index {|i|
            if clauses[i].include?(conn_leaves.first)
                idx = i
                break
            end
        }
        a2 = ( clauses[0...idx] << (clauses[idx] - conn_leaves) ).flatten
        a1 = clauses[(idx+1)...clauses.size] .flatten
        [a1, a2]
    end

    # further break a clause with connectives and VP-SBAR edge
    def break_clauses2

        @parsed_tree.root.mark_edge_1st_leaves
        new_clauses = Array.new
        @clauses.each {|clause|
            new_clause = Array.new
            clause.each {|l|
                if l.sbar_1st_leaf
                    if not new_clause.empty?
                        new_clauses.push(new_clause)
                        new_clause = Array.new
                    end
                end

                new_clause.push(l)
            }
            if not new_clause.empty?
                new_clauses.push(new_clause)
            end
        }
        @clauses = new_clauses
    end

    def break_clauses
        curr_clause = Array.new
        @leaves.each {|l|
            curr_clause.push(l)
            if Variable::Punc2.include?(l.value) and l.next_leaf != nil and not Variable::Punc3.include?(l.next_leaf.value)
                @clauses.push(curr_clause)
                curr_clause = Array.new
            end
            if Variable::Punc1.include?(l.value) and l.prev_leaf != nil and Variable::Punc2.include?(l.prev_leaf.value)
                @clauses.push(curr_clause)
                curr_clause = Array.new
            end
        }
        @clauses.push(curr_clause) if not curr_clause.empty?
    end

    # Find the five features as in
    # Pitler & Nenkova (ACL 09):
    # self_cat, parent_cat, left_cat, right_cat, right_VP, right_trace 
    def get_connective_categories(conn_leaves)
        self_cat = parent_cat = left_cat = right_cat = 'NONE'

        if conn_leaves.size > 1
            conn_leaves.each {|l|
                curr = l.parent_node
                loop do
                    curr.travel_cnt += 1
                    break if curr.is_root
                    curr = curr.parent_node
                end
            }
            parent = nil
            curr = @parsed_tree.root
            loop do
                continue = false
                curr.child_nodes.each {|c| 
                    if c.travel_cnt == curr.travel_cnt
                        parent = curr
                        curr = c
                        continue = true
                        break
                    end
                }
                break if not continue
            end

            @parsed_tree.root.reset_travel_cnt

        else
            curr = conn_leaves[0].parent_node
            parent = curr.parent_node
        end

        self_cat = curr.value
        right_VP = false
        right_trace = false
        left_sib = nil
        right_sib = nil
        if parent != nil
            parent_cat = parent.value
            i = parent.child_nodes.index(curr)
            if i > 0
                left_cat = parent.child_nodes[i-1].value
                left_sib = parent.child_nodes[i-1]
            end
            if i < parent.child_nodes.size - 1
                right_cat = parent.child_nodes[i+1].value
                right_sib = parent.child_nodes[i+1]
                if parent.child_nodes[i+1].contains_node_with_value?('VP')
                    right_VP = true
                end
                if parent.child_nodes[i+1].contains_trace?
                    right_trace = true
                end
            end
        end
        [self_cat, parent_cat, left_cat, right_cat, right_VP, right_trace, [curr, parent, left_sib, right_sib]]
    end

    def get_syntactic_features(self_node, parent_node, left_sib_node, right_sib_node)
        curr = self_node
        self_to_root = curr.v
        self_to_root2 = curr.v
        while curr != @parsed_tree.root
            prev = curr
            curr = curr.up
            self_to_root += '_>_'+curr.v
            self_to_root2 += '_>_'+curr.v if prev.v != curr.v
        end
        
        [self_to_root, self_to_root2]
    end

    def get_verbs
        @leaves.find_all {|l| Variable::Verb_tags.include?(l.up.v)}
    end

    # Find all candidate connectives. 
    def check_connectives

        Variable::Conn_intra.each {|a|
            conns = a.split(/\.\./)
            checked = [nil, nil]
            i1 = i2 = @leaves.length
            @leaves.each_index {|i|
                if @leaves[i].downcased == conns[0]
                    checked[0] = @leaves[i]
                    i1 = i + 1
                    break
                end
            }
            i1.upto(@leaves.length - 1) {|i|
                if @leaves[i].downcased == conns[1]
                    checked[1] = @leaves[i]
                    i2 = i
                    break
                end
            }
            if checked[0] != nil and checked[1] != nil
                checked.each {|l| l.is_conn = true}
                @connectives.push(checked)
                if a == "if..then"
                    i1.upto(i2 - 1) {|i|
                        if @leaves[i].downcased == "if"
                            @leaves[i].is_conn = true
                            @connectives.push([@leaves[i], checked[1]])
                        end
                    }
                end
            end
        }

        Variable::Conn_group.each do |a|
            conns = a.split
            0.upto(@leaves.size - conns.size) do |i|
                ok = true
                checked = Array.new
                conns.each_index do |j|
                    if conns[j] != @leaves[i+j].downcased or @leaves[i+j].is_conn then
                        ok = false
                        break
                    else
                        checked << @leaves[i+j]
                    end
                end
                if ok then
                    checked.each {|l| l.is_conn = true}
                    @connectives << checked
                end
            end
        end


        @connectives.sort! {|a1,a2| a1.first.article_order <=> a2.first.article_order}
        @connectives
    end

    def stemmed_text
        curr = @parsed_tree.root.first_leaf
        str = ''
        while curr != nil
            str += curr.stemmed+' '
            curr = curr.next_leaf
        end
        str.strip
    end

    def text
        curr = @parsed_tree.root.first_leaf
        str = ''
        while curr != nil
            str += curr.value+' '
            curr = curr.next_leaf
        end
        str.strip
    end

    def text2
        curr = @parsed_tree.root.first_leaf
        str = ''
        while curr != nil
            str += curr.replace_value != nil ? curr.replace_value+' ' : '_ '
            curr = curr.next_leaf
        end
        str.strip
    end

    def text3
        @leaves.map {|l| l.print_value} .join(' ')
    end

    def text4
        disc_conn_leaves = Array.new
        @disc_connectives_p.each do |disc_conn|
            disc_conn_leaves += disc_conn
        end

        text = ""
        @leaves.each do |l|
            if disc_conn_leaves.include?(l) then
                text += l.print_value + ' '
            else
                tt = l.print_value.split(/ /)
                if tt.size > 1 then
                    tt.each do |t|
                        if t.match(/(\{Exp|\{NonExp|\{Attr)/) then
                            text += t + ' '
                        elsif t.match(/(Exp\S+\}|NonExp\S+\}|Attr\S+\})/) then
                            text += t + ' '
                        end
                    end
                end
            end
        end
        text.gsub!(/  +/, ' ')
        text.strip!
        text
    end

    def text5
        ary0 = ["<tr><td>S#{@id}</td>", "<td></td>", "<td>"]
        ary1 = ["<tr><td></td>", "<td></td>", "<td>"]
        ary2 = ["<tr><td></td>", "<td></td>", "<td>"]
        ary3 = ["<tr><td></td>", "<td></td>", "<td>"]
        ary4 = ["<tr><td></td>", "<td></td>", "<td>"]
        ary5 = ["<tr><td></td>", "<td></td>", "<td>"]
        ary6 = ["<tr><td></td>", "<td></td>", "<td>"]
        @leaves.each do |l|
            v = l.value.dup
            ary0 << v
            ary1 << v
            ary2 << v
            ary3 << v
            ary4 << v
            ary5 << v
            ary6 << v
            if l.print_value.match(/\{Exp_(\d+)_Arg1/) then
                ary1[1]  = "<td>#{$1}</td>"
                ary1[-1] = "<font style=\"background-color:#FFFF66\">"+ary1[-1]
            end
            if l.print_value.match(/\{Exp_(\d+)_Arg2/) then
                ary3[1]  = "<td>#{$1}</td>"
                ary3[-1] = "<font style=\"background-color:#84C2FF\">"+ary3[-1]
            end
            if l.print_value.match(/\{Exp_(\d+)_conn_/) then
                ary5[1]  = "<td>#{$1}</td>"
                ary5[-1] = "<font style=\"background-color:#FF7575\">"+ary5[-1]
            end
            if l.print_value.match(/Exp_\d+_Arg1\}/) then
                ary1[-1] = ary1[-1]+"</font>"
            end
            if l.print_value.match(/Exp_\d+_Ar2\}/) then
                ary3[-1] = ary3[-1]+"</font>"
            end
            if l.print_value.match(/Exp_\d+_conn\}/) then
                ary5[-1] = ary5[-1]+"</font>"
            end
        end
        text = ary0.join(" ")+"</td></tr>"+
            ary1.join(" ")+"</td></tr>"+
            ary5.join(" ")+"</td></tr>"+
            ary3.join(" ")+"</td></tr>"+
            ary2.join(" ")+"</td></tr>"+
            ary4.join(" ")+"</td></tr>"+
            ary6.join(" ")+"</td></tr>"
        text
    end
end
