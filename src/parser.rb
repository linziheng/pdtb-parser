#!/usr/bin/ruby

require File.dirname(__FILE__)+'/connective'
require File.dirname(__FILE__)+'/arg_pos'
require File.dirname(__FILE__)+'/arg_ext_ss'
require File.dirname(__FILE__)+'/arg_ext_ps'
require File.dirname(__FILE__)+'/explicit'
require File.dirname(__FILE__)+'/implicit'
require File.dirname(__FILE__)+'/attribution'
require 'rubygems'
#require 'wordnet'
require 'fileutils'

class Parser
    ## split text into sentences with paragraph ino
    #def split_sentences(text, to_f, jmx=false)
        #text.strip!
        #text.delete!("\C-M")
        #paras = text.split(/\n\n+/)
        #paras.each {|p| p.gsub!(/\s+/, ' ')}
#
        #File.delete(to_f) if File.exist?(to_f)
        #sents = Array.new
        #sent_id = 0
        #para_file = File.open(to_f.sub(/\.sent$/, '.para'), 'w')
        #paras.each_index {|i|
            #para = paras[i]
            #tmp = "/tmp/"+Time.new.to_i.to_s+rand.to_s
            #File.open(tmp, 'w') {|f| f.puts para}
            #if jmx then
                #text_para = `java -classpath /home/linzihen/tools/jmx/mxpost.jar eos.TestEOS \
                #/home/linzihen/tools/jmx/eos.project < #{tmp} 2> /dev/null`
            #else
                #`/home/linzihen/tools/duc2003.breakSent/breakSent-multi.pl #{tmp}`
                #text_para = File.readlines(tmp).join
            #end
            #File.open(to_f, 'a') {|f| f.puts text_para; f.puts if i != paras.size - 1}
            #para_sents = text_para.split("\n")
            #sents += para_sents
            #File.delete(tmp)
            #para_file.puts sent_id
            #sent_id += para_sents.size
        #}
        #para_file.close
        #sents
    #end
#
    ## parse sentences into their constituent parse trees with charniak parser
    #def parse_charniak(sents, to_f)
        #tmp = "/tmp/"+Time.new.to_i.to_s+rand.to_s
        #File.open(tmp, 'w') {|f|
            #sents.each {|s|
                #f.puts '<s>'
                #f.puts s
                #f.puts '</s>'
            #}
        #}
        #`/home/linzihen/tools/charniak-parser/PARSE/parseIt -P /home/linzihen/tools/charniak-parser/DATA/EN/ #{tmp} > #{to_f}`
        #File.delete(tmp)
#
        #text_parse = "\n"
        #File.readlines(to_f).each {|l|
            #l = l.sub(/^\(S1 /, '( ')
            #text_parse += l if l != "\n"
        #}
        #File.open(to_f, 'w') {|f| f.puts text_parse}
    #end
#
    ## parse sentences into their dependency trees with stanford parser
    #def parse_dependency(from_f, to_f, print_html=false)
        #`java -cp /home/linzihen/tools/stanford-parser/stanford-parser.jar \
        #edu.stanford.nlp.trees.EnglishGrammaticalStructure -retainTmpSubcategories \
        #-treeFile #{from_f} -basic > #{to_f} 2> /dev/null`
#
        #text = File.readlines(to_f).join
        #while text.match(/^\n^\n/) do text.sub!(/^\n^\n/, "\n_nil_\n\n") end
        #File.open(to_f, 'w') {|f| f.puts text}        
#
        #if print_html then
            #dir = to_f.sub(/\.dtree/, '')
            #`rm -fr #{dir}`
            #`mkdir #{dir}`
            #cnt = 1
            #html = "<html>
                #<head>
                #<meta content=\"text/html; charset=ISO-8859-1\"
                #http-equiv=\"content-type\">
                #<title></title>
                #</head>
                #<body>"
            #dtree_str = File.readlines(to_f).join()
            #arr = dtree_str.split(/\n\n/)
#
            #arr.each {|dtree|
                #links = dtree.split(/\n/)
                #w = Hash.new
                #str = ""
                #links.each {|l|
                    #t = l.split(/[()]/)
                    #token = t[1].split(/, /)
                    #token.unshift(t[0])
                    #token[1].sub!(/\-(\d+)/, "_\\1")
                    #w[token[1]] = $1
                    #token[2].sub!(/\-(\d+)/, "_\\1")  
                    #w[token[2]] = $1
                    #str += "\"#{token[1]}\" -> \"#{token[2]}\" [arrowhead=none,arrowtail=normal,label=\"#{token[0]}\"];\n";
                #}
                #tmp_dot = "/tmp/"+Time.new.to_i.to_s+rand.to_s+'.dot'
                #fn = File.open(tmp_dot, 'w')
                #fn.puts "digraph G {\n"
#
                #w.keys.sort {|a,b| w[a] <=> w[b]} .each {|wk|
                    #fn.puts "\"#{wk}\";\n"
                #}
                #links.each {|l|
                    #token = l.split(/[(), ]+/)
                #}
                #fn.puts "\n#{str}\n}\n"
                #fn.close
#
                #`dot -Tpng #{tmp_dot} -o #{dir}/dp#{cnt}.png`
                #`cp #{tmp_dot} #{dir}/dp#{cnt}.dot`;
                #html += "Sentence ID: #{cnt}<br><br>
                    #<img src=\"./#{dir}/dp#{cnt}.png\" alt=\"\"><br><br><br><br>\n";
#
                #cnt += 1
#
                #File.delete(tmp_dot)
            #}
            #html += "</body>
                #</html>"
            #File.open("#{dir}.html", 'w') {|f| f.puts html}
        #end
    #end

    def parse_ptree_dtree(from_f, ptree_f, dtree_f, para_f, use_newline=false)
        text = File.readlines(from_f).join
        text.strip!
        text.delete!("\C-M")
        text.gsub!(/(\. )+\. ?/, '. ')
        paras = text.split(/\n\n+/)
        #paras.each {|p| p.gsub!(/ +/, ' ')}
        para_files = Array.new
        paras.each_index do |i|
            para_files[i] = para_f+i.to_s
            File.open(para_files[i], 'w') {|f| f.puts paras[i]}
        end

        linebreak = use_newline ? "-sentences newline" : ""

        res = `java -cp #{Variable::STANFORD_PARSER}/stanford-parser.jar \
        edu.stanford.nlp.parser.lexparser.LexicalizedParser #{linebreak} -retainTmpSubcategories -outputFormat "penn,typedDependencies" \
        -outputFormatOptions "basicDependencies" #{Variable::STANFORD_PARSER}/englishPCFG.ser.gz #{para_files.join(' ')} 2>&1`

        sent_cnt = 0
        ptree_fh = File.open(ptree_f, 'w')
        ptree_fh.puts
        dtree_fh = File.open(dtree_f, 'w')
        para_fh  = File.open(para_f, 'w')
        res.scan(/Parsing file:.*\n([\s\S]*?)Parsed file:/).each do |m|
            para_fh.puts sent_cnt
            text = m.first
            text.gsub!(/^Parsing \[sent.*\]\n/, '')
            while text.match(/^\n^\n/) do text.sub!(/^\n^\n/, "\n_nil_\n\n") end
            arr = text.strip.split(/\n\n/)
            0.step(arr.size-1, 2) do |i|
                sent_cnt += 1
                p = arr[i].sub(/\(ROOT\n +/, '( ')
                d = arr[i+1]
                ptree_fh.puts p
                dtree_fh.puts d
                dtree_fh.puts
            end
        end

        ptree_fh.close
        dtree_fh.close
        para_fh.close
    end

    # parse any text
    def parse_text(from_f, use_newline=false)
        $error_propagate = true
        $with_preprocess = true
        $lemmatize = true
        $tmp_prefix = "/tmp/pdtb_" + rand.to_s + rand.to_s
        pipe_f      = "#{$tmp_prefix}.pipe"
        ptree_f     = "#{$tmp_prefix}.mrg"
        dtree_f     = "#{$tmp_prefix}.dtree"
        para_f      = "#{$tmp_prefix}.para"

        parse_ptree_dtree(from_f, ptree_f, dtree_f, para_f, use_newline)
        article = Article.new(File.basename(from_f), pipe_f, ptree_f, dtree_f, para_f, '', true)
        parse(article)
        FileUtils.rm_f(Dir.glob("#{$tmp_prefix}*"))
        article
    end

    def parse_text2(ptree_f, dtree_f, para_f, use_set_model=false)
        $error_propagate = true
        $with_preprocess = true
        $lemmatize = true
        $tmp_prefix = "/tmp/pdtb_" + rand.to_s + rand.to_s

        article = Article.new(File.basename(ptree_f), '', ptree_f, dtree_f, para_f, '', true)
        parse(article, use_set_model)
        FileUtils.rm_f(Dir.glob("#{$tmp_prefix}*"))
        article
    end

    def parse_permuted_ptb_file(ptree_f, dtree_f, para_f, lmt_f, use_set_model=false)
        $error_propagate = true
        $with_preprocess = true
        $lemmatize = true
        $tmp_prefix = "/tmp/pdtb_" + rand.to_s + rand.to_s
        ##$lexicon = WordNet::Lexicon.new

        #filename = File.basename(parsed_filename).sub(/mrg/,'pipe')
        article = Article.new(File.basename(ptree_f), '', ptree_f, dtree_f, para_f, lmt_f, true, true)
        parse(article, use_set_model)
        FileUtils.rm_f(Dir.glob("#{$tmp_prefix}*"))
        article
    end

    # parse a PTB file
    #def parse_ptb_file(article_id, use_tmp_files=false)
        #$error_propagate = true
        #$with_preprocess = false
        #section_id = article_id[0,2]
        #filename = 'wsj_'+article_id+'.pipe'
        #parsed_filename = filename.sub('.pipe', '.mrg')
        #dtree_filename = filename.sub('.pipe', '.dtree')
        #return nil if not File.exist?(Variable::PDTB_DIR+"/"+section_id+"/"+filename)
        #article = Article.new(filename, 
                              #Variable::PDTB_DIR+"/"+section_id+"/"+filename,
                              #Variable::PTB_DIR+"/"+section_id+"/"+parsed_filename, 
                              #Variable::DTREE_DIR+"/"+section_id+"/"+dtree_filename)
        #[article, parse(article, use_tmp_files)]
    #end

    # parse an article into its discourse representation
    def parse(article, use_set_model=false, get_parsed=false)
        level = 2
        #cp = ".:/home/linzihen/tools/weka-3-4-12/weka.jar:/home/linzihen/tools/maxent-2.4.0/lib/trove.jar:/home/linzihen/tools/maxent-2.4.0/output/maxent-2.4.0.jar:/home/linzihen/tools/opennlp-tools-1.3.0/output/opennlp-tools-1.3.0.jar:/home/linzihen/tools/opennlp-tools-1.3.0/lib/jwnl-1.3.3.jar:/home/linzihen/tools/stanford-ner-2009-01-16/stanford-ner.jar"
        cp = Variable::CLASSPATH

        which = 'parse'
        set = article.set_id

        #Step 1: label Explicit relations
        #Step 1.1: connective classifier
        connective = Connective.new
        file1 = $tmp_prefix+'.parser.step1.conn.test'
        to_file = File.open(file1, 'w')
        conn_strs = connective.print_features(article, to_file, which)
        to_file.close
        conn_model = use_set_model ? "../data/leave1out.#{set}.conn.nep.npp.model" : "../data/100726b.conn.nep.npp.model"
        res = `cd #{File.dirname(__FILE__)}/../eval; java -cp #{cp} Predict -real #{file1} #{conn_model}`
        #puts res
        conn_res = res.split(/\n/).map {|e| e.chomp.split.last}
        conns = Array.new
        conn_res.each_index {|i| if conn_res[i] == '1' then conns << conn_strs[i] end}

        #Step 1.2: argument labeler
        #    argument position classifier
        argpos = ArgPos.new
        file2 = $tmp_prefix+'.parser.step1.2.argpos.test'
        to_file = File.open(file2, 'w')
        conn_res2 = conn_res.dup
        argpos.print_features(article, to_file, which, conn_res2, nil)
        to_file.close
        argpos_model = use_set_model ? "../data/leave1out.#{set}.argpos.nep.npp.model" : "../data/100726c.argpos.nep.npp.model"
        res = `cd #{File.dirname(__FILE__)}/../eval; java -cp #{cp} Predict -real #{file2} #{argpos_model}`
        #puts res
        argpos_res = res.split(/\n/).map {|e| e.chomp.split.last}

        #    argument extracter: SS
        argextss = ArgExtSS.new
        file3 = $tmp_prefix+'.parser.step1.2.argextss.test'
        file4 = $tmp_prefix+'.parser.step1.2.argextss.test.f1'
        file5 = $tmp_prefix+'.parser.step1.2.argextss.test.f2'
        file6 = $tmp_prefix+'.parser.step1.2.argextss.test.f3'
        to_file = File.open(file3, 'w')
        f1      = File.open(file4, 'w')
        f2      = File.open(file5, 'w')
        f3      = File.open(file6, 'w')
        conn_res2 = get_conn_res(conn_res, argpos_res)
        argextss.print_features(article, to_file, which, f1, f2, f3, conn_res2, nil)
        to_file.close
        f1.close
        f2.close
        f3.close
        argextss_model = use_set_model ? "../data/leave1out.#{set}.argextss.nep.npp.model" : "../data/100726d.argextss.nep.npp.model"
        res = `cd #{File.dirname(__FILE__)}/../eval; java -cp #{cp} Predict -real #{file3} #{argextss_model}`
        ss_arg_pairs = find_arg_nodes(file4, file6, res)

        #    argument extracter: PS
        argextps = ArgExtPS.new
        conn_res2 = get_conn_res(conn_res, argpos_res)
        ps_arg_pairs = argextps.find_PS_arg_sents(article, conn_res2)

        file7 = $tmp_prefix+'.parser.step1.2.argext.res'
        prepare_argext_res_file(conns, argpos_res, ss_arg_pairs, ps_arg_pairs, file7)
        argext_res = File.readlines(file7) .map {|e| e.chomp}

        #Step 1.3: explicit classifier
        explicit = Explicit.new
        file8 = $tmp_prefix+".parser.step1.3.exp#{level}.test"
        to_file = File.open(file8, 'w')
        conn_res2 = get_conn_res(conn_res, argpos_res)
        explicit.print_features(article, to_file, nil, nil, which, conn_res2, argext_res, nil)
        to_file.close
        exp_model = use_set_model ? "../data/leave1out.#{set}.exp.nep.npp.model" : "../data/100726f.exp.nep.npp.model"
        res = `cd #{File.dirname(__FILE__)}/../eval; java -cp #{cp} Predict -real #{file8} #{exp_model}`
        exp_res = res.split("\n").map {|l| l.chomp.split.last}
        #pp exp_res
        article.label_exp_types(level, exp_res)

        #Step 2: non-explicit classifier
        implicit = Implicit.new(100, 100, 500, false)
        file9 = $tmp_prefix+".parser.step2.imp#{level}.test"
        to_file = File.open(file9, 'w')
        implicit.print_features2(article, to_file, which, nil, nil, conn_res, argpos_res, argext_res, exp_res, nil, nil)
        to_file.close
        nonexp_model = use_set_model ? "../data/leave1out.#{set}.nonexp.nep.npp.model" : "../data/100726g.nonexp.nep.npp.model"
        res = `cd #{File.dirname(__FILE__)}/../eval; java -cp #{cp} Predict -real #{file9} #{nonexp_model}`
        nonexp_res = res.split("\n").map {|l| l.chomp.split.last}
        #pp nonexp_res
        article.label_nonexp_types(level, nonexp_res)

        #Step 3: attribution span labeler
        #article.process_attribution_edus('parse')
        attribution = Attribution.new
        file10 = $tmp_prefix+".parser.step3.attr.test"
        to_file = File.open(file10, 'w')
        #attribution.print_attr_features(article, to_file, nil, nil, 'parse')
        attribution.print_features2(article, to_file, nil, nil, nil, nil, 'parse', argpos_res, argext_res, exp_res, nonexp_res)
        to_file.close
        attr_model = use_set_model ? "../data/leave1out.#{set}.attr.nep.npp.model" : "../data/100726h.attr.nep.npp.model"
        res = `cd #{File.dirname(__FILE__)}/../eval; java -cp #{cp} Predict -real #{file10} #{attr_model}`
        attr_res = res.split("\n").map {|l| l.chomp.split.last}
        article.label_attribution_spans2(attr_res)

        #FileUtils.rm_f([file1, file2, file3, file4, file5, file6, file7, file8, file9, file10])
        article.get_parsed_text2(2) if get_parsed
    end

    def get_conn_res(conn_res, argpos_res)
        conn_res2 = conn_res.dup
        argpos_res2 = argpos_res.dup
        conn_res2.each_index do |i|
            if conn_res2[i] == '0' then
                conn_res2[i] = 'xxxxx'
            else
                conn_res2[i] = argpos_res2.shift
            end
        end
    end

    def prepare_argext_res_file(conns, argpos_res, ss_arg_pairs, ps_arg_pairs, filename)
        File.open(filename, 'w') do |f|
            argpos_res.each_index do |i|
                pos = argpos_res[i]
                conn = conns[i]
                if pos == 'SS' then
                    args = ss_arg_pairs.shift
                else
                    args = ps_arg_pairs.shift
                end
                f.puts args.join(' ## ') + ' ## X X ' + conn
            end
        end
    end

    def find_arg_nodes(f1_file, f3_file, res)
        predicted = res.split("\n").map {|l| Hash[*l.chomp.split(/\[|\]  /)[0..-2]]}
        cnts = File.readlines(f1_file).map {|l| l.split.first.to_i}
        spans = File.readlines(f3_file).map {|l| l.chomp}
        idx = 0
        ss_arg_pairs = Array.new
        cnts.each_index do |cnti|
            cnt = cnts[cnti]

            argmax1 = -1
            max1 = -1
            cnt.times do |i|
                hsh = predicted[idx + i]
                if hsh['arg1_node'].to_f > max1 then
                    max1 = hsh['arg1_node'].to_f
                    argmax1 = idx + i 
                end 
            end 
            #predicted_arg1_leaves = predicted_leaves[argmax1].split

            argmax2 = -1
            max2 = -1
            cnt.times do |i| 
                hsh = predicted[idx + i]
                if hsh['arg2_node'].to_f > max2 then
                    # make sure argmax1 and argmax2 are not the same node
                    if idx + i != argmax1 then
                        max2 = hsh['arg2_node'].to_f
                        argmax2 = idx + i 
                    end 
                end 
            end 
            ss_arg_pairs << [spans[argmax1], spans[argmax2]]
            #predicted_arg2_leaves = predicted_leaves[argmax2].split

            idx += cnt
        end

        ss_arg_pairs
    end

    #def train
        #cp = ".:/home/linzihen/tools/maxent-2.5.2/lib/trove.jar:/home/linzihen/tools/maxent-2.5.2/output/maxent-2.5.2.jar:/home/linzihen/tools/opennlp-tools-1.3.0/output/opennlp-tools-1.3.0.jar:/home/linzihen/tools/opennlp-tools-1.3.0/lib/jwnl-1.3.3.jar"
        #$prule_file  = File.dirname(__FILE__)+'/../lib/wsj.rule.txt'
        #$drule_file  = File.dirname(__FILE__)+'/../lib/wsj.dtree.txt'
        #$wordpair_file  = File.dirname(__FILE__)+'/../lib/wsj.word-pair.txt'
        #data_sets    = %w/00 01 02 03 04 05 06 07 08 09 10 11 12 13/
#
        #data_sets.each do |t|
            #$train_data = Variable::All_data - [t]
            #prefix = 'leave1out.'+t
#
            #if not File.exist?('../data/'+prefix+'.conn.nep.npp.train') then
                #puts '../data/'+prefix+'.conn.nep.npp.train'
                #obj = Connective.new
                #obj.prepare_data(prefix+'.conn.nep.npp', true)
                #res = `cd #{File.dirname(__FILE__)}/../eval; java -cp #{cp} CreateModel -real ../data/#{prefix}.conn.nep.npp.train`
                #puts res
                #exit
            #elsif not File.exist?('../data/'+prefix+'.argpos.nep.npp.train') then
                #puts '../data/'+prefix+'.argpos.nep.npp.train'
                #obj = ArgPos.new
                #obj.prepare_data(prefix+'.argpos.nep.npp', true)
                #res = `cd #{File.dirname(__FILE__)}/../eval; java -cp #{cp} CreateModel -real ../data/#{prefix}.argpos.nep.npp.train`
                #puts res
                #exit
            #elsif not File.exist?('../data/'+prefix+'.argextss.nep.npp.train') then
                #puts '../data/'+prefix+'.argextss.nep.npp.train'
                #obj = ArgExtSS.new
                #obj.prepare_data(prefix+'.argextss.nep.npp', true)
                #res = `cd #{File.dirname(__FILE__)}/../eval; java -cp #{cp} CreateModel -real ../data/#{prefix}.argextss.nep.npp.train`
                #puts res
                #exit
            #elsif not File.exist?('../data/'+prefix+'.exp.nep.npp.train') then
                #puts '../data/'+prefix+'.exp.nep.npp.train'
                #obj = Explicit.new
                #obj.prepare_data(prefix+'.exp.nep.npp', true)
                #res = `cd #{File.dirname(__FILE__)}/../eval; java -cp #{cp} CreateModel -real ../data/#{prefix}.exp.nep.npp.train`
                #puts res
                #exit
            #elsif not File.exist?('../data/'+prefix+'.nonexp.nep.npp.train') then
                #puts '../data/'+prefix+'.nonexp.nep.npp.train'
                #obj = Implicit.new(100, 100, 500, false)
                #obj.prepare_data(prefix+'.nonexp.nep.npp', true)
                #res = `cd #{File.dirname(__FILE__)}/../eval; java -cp #{cp} CreateModel -real ../data/#{prefix}.nonexp.nep.npp.train`
                #puts res
                #exit
            #elsif not File.exist?('../data/'+prefix+'.attr.nep.npp.train') then
                #puts '../data/'+prefix+'.attr.nep.npp.train'
                #obj = Attribution.new
                #obj.prepare_data(prefix+'.attr.nep.npp', true)
                #res = `cd #{File.dirname(__FILE__)}/../eval; java -cp #{cp} CreateModel -real ../data/#{prefix}.attr.nep.npp.train`
                #puts res
                #exit
            #end
        #end
    #end
end

