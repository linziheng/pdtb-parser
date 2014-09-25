require 'pp'
require File.dirname(__FILE__)+'/corpus'
require File.dirname(__FILE__)+'/variable'

class Explicit < Corpus
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
                if filename.match(/\.ep\./)
                    $error_propagate = true
                end
                if filename.match(/\.pp/) then 
                    $with_preprocess = true 
                end
            else
                which = 'dev'
                some_sections = Varialbe::Dev_data
            end

            reset_files

            if which != 'train'
                f1 = File.open(filename+'.f1', 'w')
                f2 = File.open(filename+'.f2', 'w')
            end

            to_file = File.open(filename, 'w')

            if $error_propagate and which == 'test' then
                argpos_res = File.readlines($argpos_res_file) .map {|e| e.chomp.split.last}
                argext_res = File.readlines($argext_res_file) .map {|e| e.chomp}
                exp_human_res = File.readlines($exp_human_res_file) .map {|e| e.chomp}
            else
                argpos_res = nil
                argext_res = nil
                exp_human_res = nil
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
                    print_features(article, to_file, f1, f2, which, argpos_res, argext_res, exp_human_res)
                end
            end

            to_file.close
            if which != 'train'
                f1.close
                f2.close
            end
        end
    end

    def print_features(article, to_file, f1, f2, which, argpos_res, argext_res, exp_human_res)

        if which == 'test' and $error_propagate then
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
            res3 = exp_human_res.slice!(0, conn_size)

            res4 = Array.new
            res3.each_index {|i| if res1[i] == '1' then res4.push(res3[i]) end}
            res4 = res4.map {|e| e.split()[5..-1]}

            article.label_exp_relations_types(res4)
            exp_relations = article.exp_relations_p
        elsif which == 'parse'
            res1 = argpos_res
            res2 = res1.map {|e| e != 'xxxxx' ? '1' : '0'}
            res1.delete('xxxxx')

            article.label_arguments(argext_res)
            disc_connectives = article.disc_connectives_p
            exp_relations = article.exp_relations_p
            
        else
            ary = Array.new
            article.sentences.each {|sentence| 
                ary += sentence.check_connectives
            }            
            disc_connectives = Array.new
            ary.each_index do |i| 
                if article.disc_connectives.include?(ary[i]) then 
                    disc_connectives << ary[i]
                end
            end
            exp_relations = Array.new      
            ary.each {|e| 
                if article.disc_connectives.include?(e) then
                    exp_relations.push(article.exp_relations[article.disc_connectives.index(e)])
                end
            }
        end

        disc_connectives.each_index {|idx|
            connective = disc_connectives[idx]
            relation = exp_relations[idx] 
            conn_sids = Array.new
            conn_sids = [connective[0].goto_tree.sent_id]
            conn_str = connective[0].value
            check = false
            1.upto(connective.size - 1) {|i|
                if connective[i-1].next_leaf == connective[i]
                    conn_str += ' '+connective[i].value
                else
                    conn_str += '..'+connective[i].value
                    if not check and connective[i].goto_tree.sent_id != conn_sids.first
                        conn_sids.push(connective[i].goto_tree.sent_id)
                        check = true
                    end
                end
            }

            conn_lc = conn_str.downcase

            sentence = article.sentences[conn_sids.first]

            if which != 'parse' then
                conns_and_types = relation.conns_and_level_2_types
                if conns_and_types == nil then
                    f2.puts 'nil' if which == 'test' 
                    next
                else
                    labels = conns_and_types.map {|pair| pair.last}
                    f2.puts labels.size if which == 'test'
                end
            end

            if Variable::Conn_group.include?(conn_str.downcase)
                conn_type = 'group'
            elsif Variable::Conn_intra.include?(conn_str.downcase)
                conn_type = 'intra'
            else
                conn_type = 'inter'
            end

            to_file_line = ''

            to_file_line += 'conn_lc:'+ conn_str.downcase.gsub(/ /, '_') +' '
            to_file_line += 'conn:'+ conn_str.gsub(/ /, '_') +' '

            conn_pos = connective.map {|l| l.parent_node.value} .join('_')
            to_file_line += 'conn_POS:'+ conn_pos +' '

            if connective.first.prev_leaf != nil
                to_file_line += 'with_prev_full:'+connective.first.prev_leaf.downcased+'_'+conn_str.downcase.gsub(/ /, '_')+' '
            end

            curr = sentence.parsed_tree.root.first_leaf

            if which != 'parse' then
                if which == 'train' then
                    labels.each {|label|
                        to_file.puts to_file_line+label 
                    }
                else
                    to_file.puts to_file_line+labels.first
                    f1.puts labels.join(' ')
                end
            else
                to_file.puts to_file_line+'xxxxx'
            end
        }
    end
end
