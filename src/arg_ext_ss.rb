require 'pp'
require File.dirname(__FILE__)+'/corpus'
require File.dirname(__FILE__)+'/variable'
#require File.dirname(__FILE__)+'/../lib/utils'

class ArgExtSS < Corpus
    def initialize 
        $knott_cue_phrases = Hash.new()
        File.readlines(File.dirname(__FILE__)+"/../lib/connective-category-mod.txt").each {|l| 
            t = l.strip.split(' # ')
            $knott_cue_phrases[t.first] = t.last
        }
        $knott_cue_phrases['afterwards'] = $knott_cue_phrases['afterward']
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

        output_files.each do |filename|
            if filename.match(/train/) 
                which = 'train'
                some_sections = $train_data
            elsif filename.match(/test/)
                which = 'test'
                some_sections = $test_data
                if filename.match(/\.ep\./) then $error_propagate = true end
                if filename.match(/\.pp/) then $with_preprocess = true end
            else
                which = 'dev'
                some_sections = Varialbe::Dev_data
            end

            f1 = nil
            f2 = nil
            f3 = nil
            if which == 'test' then
                f1 = File.open(filename+'.f1', 'w')
                f2 = File.open(filename+'.f2', 'w')
                f3 = File.open(filename+'.f3', 'w')
            end

            reset_files

            if $error_propagate then
                argpos_res = File.readlines($argpos_res_file) .map {|e| e.chomp.split.last}
            else
                argpos_res = File.readlines($argpos_res_file2) .map {|e| e.chomp.split.last}
            end

            f1_res = nil
            if $with_preprocess then
                res4 = Array.new
                res5 = File.readlines($argext_human_res_file).map {|l| l.chomp}
                File.readlines($conn_human_res_file).each {|e|
                    e.chomp!
                    if e == '1' then
                        res4 << res5.shift
                    else
                        res4 << '#####'
                    end
                }
                f1_res = Array.new
                res7 = File.readlines($conn_res_file).map {|e| e.chomp.split.last}
                res7.each_index {|i|
                    if res7[i] == '1' then
                        f1_res << res4[i]
                    end
                }
            end

            to_file = File.open(filename, 'w')

            some_sections.each do |section_id|
                if $with_preprocess and which != 'train' then
                    section = Section.new(section_id, Variable::PDTB_DIR+"/"+section_id.to_s,
                                          Variable::PTB_DIR2+"/"+section_id.to_s, Variable::DTREE_DIR2+"/"+section_id.to_s)
                else
                    section = Section.new(section_id, Variable::PDTB_DIR+"/"+section_id.to_s,
                                          Variable::PTB_DIR+"/"+section_id.to_s, Variable::DTREE_DIR+"/"+section_id.to_s)
                end
                puts "section: "+section.section_id
                section.articles.each do |article|
                    puts "  article: "+article.id
                    #article.process_attribution_edus
                    print_features(article, to_file, which, f1, f2, f3, argpos_res, f1_res)
                end
            end

            if which == 'test' then
                f1.close
                f2.close
                f3.close
            end

            to_file.close
        end
    end

    def print_features(article, to_file, which, f1, f2, f3, argpos_res, f1_res)
        #STDERR.puts 'print argextss features...'

        if which == 'test' then 
            conn_size = 0
            article.sentences.each {|sentence| 
                sentence.check_connectives
                conn_size += sentence.connectives.size
            }
            res1 = argpos_res.slice!(0, conn_size)
            res2 = res1.map {|e| e != 'xxxxx' ? '1' : '0'}
            res1.delete('xxxxx')
            article.flag_disc_connectives(res2)
            disc_connectives = article.disc_connectives_p
        elsif which == 'parse' then
            res1 = argpos_res
            res2 = res1.map {|e| e != 'xxxxx' ? '1' : '0'}
            res1.delete('xxxxx')
            disc_connectives = article.disc_connectives_p
        else 
            disc_connectives = article.disc_connectives
        end

        disc_connectives.each_index do |idx|
            if $with_preprocess and which == 'test' then
                f2_arg_spans = f1_res.shift
            end

            next if (which == 'test' or which == 'parse') and res1[idx] != 'SS'

            connective = disc_connectives[idx]
            conn_str, conn_sids = get_conn_str(connective)

            conn_type = find_conn_type(conn_str)
            conn_cat = $knott_cue_phrases[conn_str.downcase]

            conn_str = conn_str.gsub(/ /, '_')

            conn_node = connective.last.up

            if $with_preprocess then
                long_connective = connective
                arg1_node = nil
                arg2_node = nil

                if which == 'test' then
                    if f2_arg_spans == '#####' then
                        f2.puts 'xxxxx ## xxxxx'
                    else
                        f2.puts f2_arg_spans.split(' ## ')[0,2].join(' ## ')
                    end
                end
            elsif article.disc_connectives.include?(connective) then
                long_connective = article.long_disc_connectives[article.disc_connectives.index(connective)]
                #idx2 = disc_connectives.index(connective)
                #relation = article.exp_relations[idx2]
                relation = article.get_exp_relation(connective)
                arg1_sids = article.gorns2sentid(relation.arg1s['gorn_addr'])
                arg2_sids = article.gorns2sentid(relation.arg2s['gorn_addr'])

                argpos = find_argpos(arg1_sids, conn_sids)

                # combine IPS and NAPS
                #if argpos == 'IPS' or argpos == 'NAPS' then argpos = 'PS' end
                next if which == 'train' and argpos != 'SS' 

                punc_nodes = []
                if conn_cat == 'Coordinator' and conn_node.v == 'CC' then
                    (conn_node.up.child_nodes - relation.arg1s['parsed_tree']).each do |n|
                        if Variable::Punctuation_tags.include?(n.v) then
                            punc_nodes << n
                        end
                    end
                end

                arg1_nodes = relation.arg1s['parsed_tree'] + relation.attr1s['parsed_tree'] + punc_nodes #+ relation.sup1s['parsed_tree']
                arg2_nodes = relation.arg2s['parsed_tree'] + relation.attr2s['parsed_tree'] #+ relation.sup2s['parsed_tree']
                if arg1_nodes.size == 1 then
                    arg1_node = arg1_nodes.first
                else
                    arg1_node = article.find_least_common_ancestor(arg1_nodes)
                end
                if arg2_nodes.size == 1 then
                    arg2_node = arg2_nodes.first
                else
                    #arg2_node = article.find_node_with_most_leaves(arg2_nodes)
                    arg2_node = article.find_least_common_ancestor(arg2_nodes, true)
                end
                arg1_leaves = relation.arg1_leaves
                arg2_leaves = relation.arg2_leaves
                if which == 'test' then
                    f2.puts arg1_leaves.map {|l| l.article_order.to_s+'_'+l.up.v+'_'+l.v} .join(' ') + ' ## ' +
                        arg2_leaves.map {|l| l.article_order.to_s+'_'+l.up.v+'_'+l.v} .join(' ')
                end
            else
                long_connective = connective
                arg1_node = nil
                arg2_node = nil
                if which == 'test' then
                    f2.puts 'xxxxx ## xxxxx' 
                end
            end

            sentence = article.sentences[conn_sids.first]
            node_label = sentence.get_internal_nodes(true).map do |n|
                if n == arg1_node then
                    [n, 'arg1_node']
                elsif n == arg2_node then
                    [n, 'arg2_node']
                else
                    [n, 'none']
                end
            end

            if which == 'test' or which == 'parse' then
                f1.puts node_label.size.to_s+' '+conn_cat.to_s+' '+
                    long_connective.map {|l| l.article_order.to_s+'_'+l.up.v+'_'+l.v} .join(' ')
            end

            node_label.each do |node, label|
                to_file_line = ''
                to_file_line += "conn:#{conn_str} "
                to_file_line += "conn_lc:#{conn_str.downcase} "
                to_file_line += "conn_cat:#{conn_cat} "
                path, path2 = article.find_path(conn_node, node)
                relpos = article.relative_position(conn_node, node)
                to_file_line += "conn_to_node:#{path} "
                lsibs = conn_node.all_left_siblings
                rsibs = conn_node.all_right_siblings
                to_file_line += "conn_node_lsib_size=#{lsibs.size} "
                to_file_line += "conn_node_rsib_size=#{rsibs.size} "
                if lsibs.size > 1 then
                    to_file_line += "conn_to_node:#{path}^conn_node_lsib_size:>1 " 
                end
                to_file_line += "conn_to_node_relpos:#{relpos} "
                to_file.puts to_file_line + label
                if which == 'test' or which == 'parse' then
                    f3.puts node.my_leaves.map {|l| l.article_order.to_s+'_'+l.up.v+'_'+l.v} .join(' ')
                end
            end
        end
    end
end
