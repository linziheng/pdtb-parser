require 'pp'
require File.dirname(__FILE__)+'/corpus'
require File.dirname(__FILE__)+'/variable'

class ArgExtPS < Corpus
    def initialize 
        $knott_cue_phrases = Hash.new()
        File.readlines(File.dirname(__FILE__)+"/../lib/connective-category-mod.txt").each {|l| 
            t = l.strip.split(' # ')
            $knott_cue_phrases[t.first] = t.last
        }
        $knott_cue_phrases['afterwards'] = $knott_cue_phrases['afterward']
    end


    def print_coherence_features(features, article, to_file, which)
        line2 = ' 1:1'
        line1 = ' 1:1'

        hsh2 = Hash.new
        hsh1 = Hash.new
        tuples = article.sentences.map {|s| [s, nil]}
        disc_connectives = article.disc_connectives
        disc_connectives.each_index do |idx|
            connective = disc_connectives[idx]
            conn_str, conn_sids = get_conn_str(connective)
            conn_str = conn_str.gsub(/ /, '_')
            conn_node = connective.last.up

            long_connective = article.long_disc_connectives[article.disc_connectives.index(connective)]
            relation = article.get_exp_relation(connective)
            arg1_sids = article.gorns2sentid(relation.arg1s['gorn_addr'])
            arg2_sids = article.gorns2sentid(relation.arg2s['gorn_addr'])
            arg1_sid = arg1_sids.last
            arg2_sid = arg2_sids.first
            arg1_sent = article.sentences[arg1_sid]
            arg2_sent = article.sentences[arg2_sid]

            argpos = find_argpos(arg1_sids, conn_sids)

            # combine IPS and NAPS
            if argpos == 'IPS' or argpos == 'NAPS' then argpos = 'PS' end
            next if which == 'train' and argpos != 'PS'

            tuples[arg2_sid][1] = connective
        end

        tuples.each_index do |i|
            next if tuples[i][1] == nil
            conn_str, conn_sids = get_conn_str(tuples[i][1])
            conn_str = conn_str.gsub(/ /, '_')
            arg1_sent = article.sentences[i-1]
            arg2_sent = article.sentences[i]
            arg1_sent.leaves.each do |la|
                arg2_sent.leaves.each do |lb|
                    hsh2[la.v+'_'+conn_str+'_'+lb.v] = 1
                end
            end
        end

        tuples = tuples.reverse

        tuples.each_index do |i|
            next if tuples[i][1] == nil
            conn_str, conn_sids = get_conn_str(tuples[i][1])
            conn_str = conn_str.gsub(/ /, '_')
            arg1_sent = article.sentences[i-1]
            arg2_sent = article.sentences[i]
            arg1_sent.leaves.each do |la|
                arg2_sent.leaves.each do |lb|
                    hsh1[la.v+'_'+conn_str+'_'+lb.v] = 1
                end
            end
        end

        features.each_index do |i|
            if hsh2.has_key?(features[i]) then
                line2 += " #{i+2}:1"
            end
        end
        features.each_index do |i|
            if hsh1.has_key?(features[i]) then
                line1 += " #{i+2}:1"
            end
        end

        if line2 != ' 1:1' and line1 != ' 1:1' then
            to_file.puts "2 qid:#{$qid}"+line2
            to_file.puts "1 qid:#{$qid}"+line1
        end
    end

    def permute(size)
        orig = (0...size).to_a
        perms = []
        20.times do |i|
            perm = orig.sort_by {rand}
            if not ([orig] + perms).include?(perm) then
                perms << perm
            end
        end
        perms
    end

    def compute_MI(n, n1_, n_1, n11, frequency, file)
        hash = Hash.new(0)
        n1_.each_key do |p|
            next if n1_[p] < frequency
            nn1_ = n1_[p]
            n_1.each_key do |r|
                nn_1 = n_1[r]
                nn11 = n11[p+" "+r]

                nn01 = nn_1 - nn11
                nn0_ = n - nn1_
                nn_0 = n - nn_1
                nn10 = nn1_ - nn11
                nn00 = nn0_ - nn01
                
                a = (nn11+1) * 1.0 / (n+4) * Math.log((n+4) * (nn11+1) * 1.0 / (nn1_+2) / (nn_1+2)) / Math.log(2)
                b = (nn01+1) * 1.0 / (n+4) * Math.log((n+4) * (nn01+1) * 1.0 / (nn0_+2) / (nn_1+2)) / Math.log(2)
                c = (nn10+1) * 1.0 / (n+4) * Math.log((n+4) * (nn10+1) * 1.0 / (nn1_+2) / (nn_0+2)) / Math.log(2)
                d = (nn00+1) * 1.0 / (n+4) * Math.log((n+4) * (nn00+1) * 1.0 / (nn0_+2) / (nn_0+2)) / Math.log(2)
                
                hash["#{p} #{r} #{n1_[p]} #{nn11} #{nn10} #{nn01} #{nn00}"] = a + b + c +d
            end
        end
        
        to_file = File.open(file, "w")
        hash.sort {|a,b| b[1] <=> a[1]} .each {|k,v|
            to_file.puts k+" "+v.to_s
        }
        to_file.close
    end

    def prepare_data(prefix)
        ['../data/'+prefix+'.train', 
            '../data/'+prefix+'.test',
            '../data/'+prefix.sub(/\.nep\./, '.ep.')+'.test',
            '../data/'+prefix.sub(/\.nep\./, '.ep.').sub(/\.npp$/, '.pp')+'.test',
        ].each do |filename|
            if filename.match(/train/) 
                which = 'train'
                some_sections = Variable::Train_data
            elsif filename.match(/test/)
                which = 'test'
                some_sections = Variable::Test_data
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

            $n1_ = Hash.new(0)
            $n_1 = Hash.new(0)
            $n11 = Hash.new(0)
            $n   = 0

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

    def find_PS_arg_sents(article, argpos_res)
        res1 = argpos_res
        res2 = res1.map {|e| e != 'xxxxx' ? '1' : '0'}
        res1.delete('xxxxx')
        disc_connectives = article.disc_connectives_p

        ps_arg_pairs = Array.new

        disc_connectives.each_index do |idx|
            next if res1[idx] != 'PS'
            connective = disc_connectives[idx]
            conn_str, conn_sids = get_conn_str(connective)
            arg1_leaves = article.sentences[conn_sids.first-1].leaves.map {|l| l.article_order.to_s+'_'+l.up.v+'_'+l.v} .join(' ')
            arg2_leaves = article.sentences[conn_sids.first].leaves.map {|l| l.article_order.to_s+'_'+l.up.v+'_'+l.v} .join(' ')
            ps_arg_pairs << [arg1_leaves, arg2_leaves]
        end

        ps_arg_pairs
    end

    def print_features(article, to_file, which, f1, f2, f3, argpos_res, f1_res)
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

            next if (which == 'test' or which == 'parse') and res1[idx] != 'PS' 

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

                tmp_str = 'xxxxx'
                if which == 'test' then
                    if f2_arg_spans == '#####' then
                        f2.puts 'xxxxx ## xxxxx'
                    else
                        spans = f2_arg_spans.split(' ## ')
                        f2.puts spans[0,2].join(' ## ')
                        tmp_str = spans[0]
                    end
                end
                arg2_sid = conn_sids.first
                if tmp_str == 'xxxxx' then
                    arg1_sid = -5
                else
                    argmax = -5
                    max = -5
                    tmp_str.gsub!(/\S+_\S+_(\S+)/, "\\1")
                    0.upto(arg2_sid-1) do |a1id|
                        currsim = Utils.word_level_levenshtein_similarity(article.sentences[a1id].text3, tmp_str)
                        if currsim >= max then
                            max = currsim
                            argmax = a1id
                        end
                    end
                    arg1_sid = argmax
                end
            elsif article.disc_connectives.include?(connective) then
                long_connective = article.long_disc_connectives[article.disc_connectives.index(connective)]
                relation = article.get_exp_relation(connective)
                arg1_sids = article.gorns2sentid(relation.arg1s['gorn_addr'])
                arg2_sids = article.gorns2sentid(relation.arg2s['gorn_addr'])
                arg1_sid = arg1_sids.last
                arg2_sid = arg2_sids.first

                argpos = find_argpos(arg1_sids, conn_sids)

                # combine IPS and NAPS
                if argpos == 'IPS' or argpos == 'NAPS' then argpos = 'PS' end
                next if which == 'train' and argpos != 'PS'

                arg1_leaves = relation.arg1_leaves
                arg2_leaves = relation.arg2_leaves
                if which == 'test' then
                    f2.puts arg1_leaves.map {|l| l.article_order.to_s+'_'+l.up.v+'_'+l.v} .join(' ') + ' ## ' +
                        arg2_leaves.map {|l| l.article_order.to_s+'_'+l.up.v+'_'+l.v} .join(' ')
                end

                $n += 1
                $n_1['1'] += 1
                leave_pairs = Hash.new(0)
                arg1_leaves.each do |la|
                    arg2_leaves.each do |lb|
                        leave_pairs[la.v+'_'+conn_str+'_'+lb.v] = 1
                    end
                end
                leave_pairs.keys.each do |p|
                    $n1_[p] += 1
                    $n11[p+' 1'] += 1
                end

                diff_arg1_sent = pick_diff_arg1(article, arg1_sid, arg2_sid)
                if diff_arg1_sent != nil then
                    $n += 1
                    $n_1['0'] += 1
                    leave_pairs = Hash.new(0)
                    diff_arg1_sent.leaves.each do |la|
                        arg2_leaves.each do |lb|
                            leave_pairs[la.v+'_'+conn_str+'_'+lb.v] = 1
                        end
                    end
                    leave_pairs.keys.each do |p|
                        $n1_[p] += 1
                        $n11[p+' 0'] += 1
                    end
                end
            else
                long_connective = connective
                arg1_node = nil
                arg2_node = nil
                if which == 'test' then
                    f2.puts 'xxxxx ## xxxxx' 
                end
            end

            if which == 'test' or which == 'parse' then
                f1.puts 'x '+conn_cat+' '+
                    long_connective.map {|l| l.article_order.to_s+'_'+l.up.v+'_'+l.v} .join(' ')
                f3.puts article.sentences[conn_sids.first-1].leaves.map {|l| l.article_order.to_s+'_'+l.up.v+'_'+l.v} .join(' ') + ' ## ' +
                    article.sentences[conn_sids.first].leaves.map {|l| l.article_order.to_s+'_'+l.up.v+'_'+l.v} .join(' ')
            end

            sentence = article.sentences[conn_sids.first]
        end
    end

    def pick_diff_arg1(article, arg1_sid, arg2_sid)
        article.sentences.sort_by {rand} .each do |sent|
            if sent.id != arg1_sid and sent.id != arg2_sid then
                return sent
            end
        end
        nil
    end
end
