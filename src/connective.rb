require 'pp'
require File.dirname(__FILE__)+'/corpus'
require File.dirname(__FILE__)+'/variable'

class Connective < Corpus
    def prepare_data(prefix, train_only=false)
        if train_only then
            output_files = [File.dirname(__FILE__)+'/../data/'+prefix+'.train']
        else
            output_files = [File.dirname(__FILE__)+'/../data/'+prefix+'.train', 
                File.dirname(__FILE__)+'/../data/'+prefix+'.test',
                File.dirname(__FILE__)+'/../data/'+prefix.sub(/\.npp$/, '.pp')+'.test',
            ]
        end

        output_files.each do |filename|
            if filename.match(/train/) then 
                which = 'train'
                some_sections = $train_data
            elsif filename.match(/test/) then
                which = 'test'
                some_sections = $test_data
                if filename.match(/\.pp/) then
                    $with_preprocess = true
                end
            else
                which = 'dev'
                some_sections = Varialbe::Dev_data
            end

            to_file = File.open(filename, 'w')
            
            some_sections.each do |section_id|
                if $with_preprocess and which == 'test' then
                    section = Section.new(section_id, Variable::PDTB_DIR+"/"+section_id.to_s,
                                          Variable::PTB_DIR2+"/"+section_id.to_s, Variable::DTREE_DIR2+"/"+section_id.to_s)
                else
                    section = Section.new(section_id, Variable::PDTB_DIR+"/"+section_id.to_s,
                                          Variable::PTB_DIR+"/"+section_id.to_s, Variable::DTREE_DIR+"/"+section_id.to_s)
                end
                puts "section: "+section.section_id
                section.articles.each do |article|
                    puts "  article: "+article.id
                    print_features(article, to_file, which)
                end
            end

            to_file.close
        end
    end

    def print_features(article, to_file, which)

        with_new = true

        conn_strs = Array.new

        article.sentences.each_index do |sid|
            prev_sentence = (sid > 0) ? article.sentences[sid-1] : nil 
            sentence = article.sentences[sid]
            next_sentence = (sid < article.sentences.size - 1) ? article.sentences[sid+1] : nil 
            
            all_conns = sentence.check_connectives
            all_conns.each_index {|i|
                if which != 'parse'
                    if article.disc_connectives.include?(all_conns[i])
                        label = '1'
                    else
                        label = '0'
                    end
                end

                to_file_line = ''

                connective = all_conns[i]
                conn_str = connective[0].value
                1.upto(connective.size - 1) {|j|
                    if connective[j-1].next_leaf == connective[j]
                        conn_str += ' '+connective[j].value
                    else
                        conn_str += '..'+connective[j].value
                    end
                }
                if Variable::Conn_group.include?(conn_str.downcase)
                    conn_type = 'group'
                elsif Variable::Conn_intra.include?(conn_str.downcase)
                    conn_type = 'intra'
                else
                    conn_type = 'inter'
                end

                tmp_sent = sentence.leaves.map {|l| if connective.include?(l) then '*'+l.v+'*' else l.v end} .join(' ')
                comment = article.id+' '+sentence.id.to_s+' '+conn_str+' : '+tmp_sent

                to_file_line += 'conn_lc:'+ conn_str.downcase.gsub(/ /, '_') +' '
                to_file_line += 'conn:'+ conn_str.gsub(/ /, '_') +' '
                conn_strs << conn_str

                if with_new then
                    conn_pos = connective.map {|l| l.parent_node.value} .join('_')
                    to_file_line += 'lexsyn:conn_POS:'+ conn_pos +' '

                    if connective.first.prev_leaf != nil
                        to_file_line += 'lexsyn:with_prev_full:'+connective.first.prev_leaf.value+'_'+conn_str.gsub(/ /, '_')+' '

                        prev_pos = connective.first.prev_leaf.parent_node.value
                        to_file_line += 'lexsyn:prev_POS:'+prev_pos+' '
                        to_file_line += 'lexsyn:with_prev_POS:'+prev_pos+'_'+conn_pos.split('_').first+' '
                        to_file_line += 'lexsyn:with_prev_POS_full:'+prev_pos+'_'+conn_pos+' '
                    end

                    if connective.last.next_leaf != nil
                        to_file_line += 'lexsyn:with_next_full:'+conn_str.gsub(/ /, '_')+'_'+connective.last.next_leaf.value+' '

                        next_pos = connective.last.next_leaf.parent_node.value
                        to_file_line += 'lexsyn:next_POS:'+next_pos+' '
                        to_file_line += 'lexsyn:with_next_POS:'+conn_pos.split('_').last+'_'+next_pos+' '
                        to_file_line += 'lexsyn:with_next_POS_full:'+conn_pos+'_'+next_pos+' '
                    end
                end

                # Pitler & Nenkova (ACL 09) features:
                # self_cat, parent_cat, left_cat, right_cat, right_VP, right_trace =
                res = sentence.get_connective_categories(connective)

                res2 = ['selfCat:'+res[0],
                        'parentCat:'+res[1],
                        'leftCat:'+res[2],
                        'rightCat:'+res[3]]
                res2 << 'rightVP'       if res[4] == true
                res2 << 'rightTrace'    if res[5] == true

                res2.each {|e| to_file_line += 'syn:'+e+' '}

                res2.each {|e| to_file_line += 'conn-syn:'+'conn:'+ conn_str.gsub(/ /, '_')+'-'+e+' '}
                
                res2.each_index {|j|
                    res2[j+1 ... res2.size].each {|p2|
                        to_file_line += 'syn-syn:'+res2[j]+'-'+p2+' '
                    }
                }

                if with_new then
                    res3 = sentence.get_syntactic_features(*res[6])
                    to_file_line += 'path-self>root:'+res3[0]+' '
                    to_file_line += 'path-self>root2:'+res3[1]+' '
                end

                if which == 'parse' then
                    to_file.puts to_file_line+'xxxxx' 
                else
                    to_file.puts to_file_line+label
                end
            }
        end

        conn_strs
    end
end
