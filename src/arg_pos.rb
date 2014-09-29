require 'pp'
require File.dirname(__FILE__)+'/corpus'
require File.dirname(__FILE__)+'/variable'

class ArgPos < Corpus
    def prepare_data(prefix, train_only=false)
        $joint_model = false
        if train_only then
            output_files = [File.dirname(__FILE__)+'/../data/'+prefix+'.train']
        else
            output_files = [File.dirname(__FILE__)+'/../data/'+prefix+'.train', 
                File.dirname(__FILE__)+'/../data/'+prefix+'.test',
                File.dirname(__FILE__)+'/../data/'+prefix.sub(/\.nep\./, '.ep.')+'.test',
                File.dirname(__FILE__)+'/../data/'+prefix.sub(/\.nep\./, '.ep.').sub(/\.npp$/, '.pp')+'.test',
            ]
        end

        output_files.each do |filename|
            if filename.match(/train/) then 
                which = 'train'
                some_sections = $train_data
            elsif filename.match(/test/) then
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
                some_sections = Varialbe::Dev_data
            end

            reset_files

            to_file = File.open(filename, 'w')
            
            if which == 'test' and $error_propagate then
                conn_res = File.readlines($conn_res_file) .map {|e| e.chomp.split(" ").last}
                if $with_preprocess then
                    argpos_human_res = File.readlines($argpos_human_res_file) .map {|e| e.chomp}
                end
            else
                conn_res = nil
                argpos_human_res = nil
            end

            some_sections.each do |section_id|
                if which == 'test' and $with_preprocess 
                    section = Section.new(section_id, Variable::PDTB_DIR+"/"+section_id.to_s,
                                          Variable::PTB_DIR2+"/"+section_id.to_s, Variable::DTREE_DIR2+"/"+section_id.to_s)
                else
                    section = Section.new(section_id, Variable::PDTB_DIR+"/"+section_id.to_s,
                                          Variable::PTB_DIR+"/"+section_id.to_s, Variable::DTREE_DIR+"/"+section_id.to_s)
                end
                puts "section: "+section.section_id
                section.articles.each do |article|
                    puts "  article: "+article.id
                    print_features(article, to_file, which, conn_res, argpos_human_res)
                end
                if conn_res != nil and conn_res.size != 0
                    puts 'error: conn_res.size = '+conn_res.size.to_s
                    exit
                end
            end

            to_file.close

        end
    end

    def print_features(article, to_file, which, conn_res, argpos_human_res)

        if which == 'test' and $error_propagate
            conn_size = 0
            article.sentences.each {|sentence| 
                sentence.check_connectives
                conn_size += sentence.connectives.size
            }
            res = conn_res.slice!(0, conn_size)
            res1 = res.dup
            article.flag_disc_connectives(res)
            disc_connectives = article.disc_connectives_p
            if $with_preprocess then
                argpos_res = Array.new
                res2 = argpos_human_res.slice!(0, conn_size)
                res1.each_index {|i|
                    if res1[i] == '1' then
                        argpos_res << res2[i].split.last
                    end
                }
            end
        elsif which == 'parse'
            article.flag_disc_connectives(conn_res)
            disc_connectives = article.disc_connectives_p
        else 
            ary = Array.new
            article.sentences.each {|sentence| 
                ary += sentence.check_connectives
            }
            disc_connectives = Array.new
            tmp_ary = Array.new
            tmp_hsh = Hash.new
            cnt = 0
            ary.each_index do |i| 
                if article.disc_connectives.include?(ary[i]) then 
                    disc_connectives << ary[i]
                    tmp_ary << '1'
                    tmp_hsh[cnt] = i
                    cnt += 1
                else
                    tmp_ary << '0'
                end
            end
        end

        disc_connectives.each_index {|idx|
            connective = disc_connectives[idx]
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
            if Variable::Conn_group.include?(conn_str.downcase)
                conn_type = 'group'
            elsif Variable::Conn_intra.include?(conn_str.downcase)
                conn_type = 'intra'
            else
                conn_type = 'inter'
            end
            conn_pos = connective.map {|l| l.parent_node.value} .join('_')

            if which == 'test' and $with_preprocess then
                label = argpos_res.shift
            elsif which == 'test' and $error_propagate and not article.disc_connectives.include?(connective) then
                label = 'xxxxx'
            elsif which == 'parse'
                label = 'xxxxx'
            else
                idx2 = article.disc_connectives.index(connective)
                relation = article.exp_relations[idx2]
                arg1_sids = article.gorns2sentid(relation.arg1s['gorn_addr'])
                arg2_sids = article.gorns2sentid(relation.arg2s['gorn_addr'])

                # IPS
                if arg1_sids.last + 1 == conn_sids.first
                    label = 'IPS'
                # NAPS
                elsif arg1_sids.last + 1 < conn_sids.first
                    label = 'NAPS'
                # FS
                elsif conn_sids.first + 1 <= arg1_sids.first
                    #label = '(arg2)..(arg1)'
                    if which == 'train' then
                        tmp_ary[tmp_hsh[idx]] = '0'
                    end
                    next
                # SS
                else 
                    label = 'SS'
                end
            end

            # combine IPS and NAPS
            if label == 'IPS' or label == 'NAPS' then label = 'PS' end
            to_file_line = ''

            to_file_line += 'conn:' + conn_str.gsub(/ /, '_') + ' '

            to_file_line += 'conn_POS:'+conn_pos+' '

            conn_sent_leaves = article.sentences[conn_sids.first].leaves
            if conn_type == 'group'
                pos = conn_sent_leaves.index(connective[0])
                if pos <= 2
                    to_file_line += 'sent_pos:'+pos.to_s+' '
                else
                    pos = conn_sent_leaves.index(connective.last)
                    if pos >= conn_sent_leaves.size - 3
                        pos2 = pos - conn_sent_leaves.size
                        to_file_line += 'sent_pos:'+pos2.to_s+' '
                    end
                end

                prev2 = prev1 = ws = next1 = next2 = nil
                pPOS2 = pPOS1 = ps = nPOS1 = nPOS2 = nil
                ws = conn_str.downcase
                ps = conn_pos

                if connective.first.prev_leaf != nil
                    prev1 = connective.first.prev_leaf.value
                    pPOS1 = connective.first.prev_leaf.parent_node.value
                    to_file_line += 'prev1:'+prev1+' '
                    to_file_line += 'prev1_POS:'+pPOS1+' '

                    to_file_line += 'with_prev1_full:'+prev1+'_'+conn_str.gsub(/ /, '_')+' '
                    to_file_line += 'with_prev1_POS_full:'+pPOS1+'_'+conn_pos+' '

                    if connective.first.prev_leaf.prev_leaf != nil
                        prev2 = connective.first.prev_leaf.prev_leaf.value
                        pPOS2 = connective.first.prev_leaf.prev_leaf.parent_node.value
                        to_file_line += 'prev2:'+prev2+' '
                        to_file_line += 'prev2_POS:'+pPOS2+' '

                        to_file_line += 'with_prev2_full:'+prev2+'_'+conn_str.gsub(/ /, '_')+' '
                        to_file_line += 'with_prev2_POS_full:'+pPOS2+'_'+conn_pos+' '
                    end
                end
            end

            if which != 'parse' 
                to_file.puts to_file_line+label 
            else
                to_file.puts to_file_line+'xxxxx'
            end
        }
    end
end
