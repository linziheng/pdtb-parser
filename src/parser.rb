#!/usr/bin/ruby

require File.dirname(__FILE__)+'/connective'
require File.dirname(__FILE__)+'/arg_pos'
require File.dirname(__FILE__)+'/arg_ext_ss'
require File.dirname(__FILE__)+'/arg_ext_ps'
require File.dirname(__FILE__)+'/explicit'
require File.dirname(__FILE__)+'/implicit'
require File.dirname(__FILE__)+'/attribution'
require File.dirname(__FILE__)+'/variable'
require 'rubygems'
require 'fileutils'

class Parser

   # Parse production rule and dependency rule trees. 
    def parse_ptree_dtree(from_f, ptree_f, dtree_f, para_f, use_newline=false)
        text = File.readlines(from_f).join
        text.strip!
        text.delete!("\C-M")
        text.gsub!(/(\. )+\. ?/, '. ')
        paras = text.split(/\n\n+/)
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

    # parse an article into its discourse representation
    def parse(article, use_set_model=false, get_parsed=false)
        level = 2
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
        article.label_nonexp_types(level, nonexp_res)

        #Step 3: attribution span labeler
        attribution = Attribution.new
        file10 = $tmp_prefix+".parser.step3.attr.test"
        to_file = File.open(file10, 'w')
        attribution.print_features2(article, to_file, nil, nil, nil, nil, 'parse', argpos_res, argext_res, exp_res, nonexp_res)
        to_file.close
        attr_model = use_set_model ? "../data/leave1out.#{set}.attr.nep.npp.model" : "../data/100726h.attr.nep.npp.model"
        res = `cd #{File.dirname(__FILE__)}/../eval; java -cp #{cp} Predict -real #{file10} #{attr_model}`
        attr_res = res.split("\n").map {|l| l.chomp.split.last}
        article.label_attribution_spans2(attr_res)

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

            idx += cnt
        end

        ss_arg_pairs
    end
end

