#require 'rubygems'
#require 'wordnet'

class Utils
    def initialize
    end

    # lex: a WordNet::Lexicon
    # w1, w2: word pair, such as 'decline' and 'rise'
    # w1_pos: can be one of "n", "v", "a" and "r".
    # symbol: one of the WordNet::Constants::POINTER_TYPES (e.g., :antonym)
    #   nil means check whether w1 and w2 are synonymous
    def Utils.check_word_relation(lex, w1, w2, w1_pos, symbol=nil)
        if w1_pos == nil
            poss = ["n", "v", "a", "r"]
        else
            poss = [w1_pos]
        end

        poss.each do |pos|
            synsets = lex.lookup_synsets(w1, pos)
            next if synsets == nil
            synsets.each do |syns|
                if symbol == nil
                    if w1 != w2 and syns.words.include?(w2)
                        return true
                    end
                else
                    pointers = syns.pointers
                    next if pointers == nil
                    pointers.each do |pointer|
                        if pointer.type_symbol == symbol and
                            lex.lookup_synsets_by_key(pointer.synset).words.include?(w2)
                            return true
                        end
                    end
                end
            end
        end
        false
    end

    def Utils.remove_punctuations(text)
        #$$textref =~ s/[(),\.\?:;`'\"!\-_\/]/ /g; 
        text.gsub!(/[(),\.\?:;`'\"!\-_\/]/, " ")
        #$$textref =~ s/ +/ /g;
        text.gsub!(/\s+/, " ")
        #&trim($textref);
        text.gsub!(/^\s+|\s+$/, "")
        text
    end
    
    def Utils.remove_stop_words(text)
        stopwords = %w/a ii about above according across 39 actually ad adj ae af after afterwards ag again against ai al all 
        almost alone along already also although always am among amongst an and another any anyhow anyone anything anywhere ao aq 
        ar are aren aren't around arpa as at au aw az b ba bb bd be became because become becomes becoming been before beforehand 
        begin beginning behind being below beside besides between beyond bf bg bh bi billion bj bm bn bo both br bs bt but buy bv 
        bw by bz c ca can can't cannot caption cc cd cf cg ch ci ck cl click cm cn co co. com copy could couldn couldn't cr cs cu 
        cv cx cy cz d de did didn didn't dj dk dm do does doesn doesn't don don't down during dz e each ec edu ee eg eh eight eighty 
        either else elsewhere end ending enough er es et etc even ever every everyone everything everywhere except f few fi fifty 
        find first five fj fk fm fo for former formerly forty found four fr free from further fx g ga gb gd ge get gf gg gh gi gl 
        gm gmt gn go gov gp gq gr gs gt gu gw gy h had has hasn hasn't have haven haven't he he'd he'll he's help hence her here here's 
        hereafter hereby herein hereupon hers herself him himself his hk hm hn home homepage how however hr ht htm html http hu 
        hundred i i'd i'll i'm i've i.e. id ie if il im in inc inc. indeed information instead int into io iq ir is isn isn't it it's 
        its itself j je jm jo join jp k ke kg kh ki km kn kp kr kw ky kz l la last later latter lb lc least less let let's li like 
        likely lk ll lr ls lt ltd lu lv ly m ma made make makes many maybe mc md me meantime meanwhile mg mh microsoft might mil 
        million miss mk ml mm mn mo more moreover most mostly mp mq mr mrs ms msie mt mu much must mv mw mx my myself mz n na namely 
        nc ne neither net netscape never nevertheless new next nf ng ni nine ninety nl no nobody none nonetheless noone nor not 
        nothing now nowhere np nr nu nz o of off often om on once one one's only onto or org other others otherwise our ours ourselves 
        out over overall own p pa page pe per perhaps pf pg ph pk pl pm pn pr pt pw py q qa r rather re recent recently reserved 
        ring ro ru rw s sa same sb sc sd se seem seemed seeming seems seven seventy several sg sh she she'd she'll she's should 
        shouldn shouldn't si since site six sixty sj sk sl sm sn so some somehow someone something sometime sometimes somewhere sr 
        st still stop su such sv sy sz t taking tc td ten text tf tg test th than that that'll that's the their them themselves then 
        thence there there'll there's thereafter thereby therefore therein thereupon these they they'd they'll they're they've thirty 
        this those though thousand three through throughout thru thus tj tk tm tn to together too toward towards tp tr trillion tt tv 
        tw twenty two tz u ua ug uk um under unless unlike unlikely until up upon us use used using uy uz v va vc ve very vg vi via 
        vn vu w was wasn wasn't we we'd we'll we're we've web webpage website welcome well were weren weren't wf what what'll what's 
        whatever when whence whenever where whereafter whereas whereby wherein whereupon wherever whether which while whither who who'd 
        who'll who's whoever NULL whole whom whomever whose why will with within without won won't would wouldn wouldn't ws www x y 
        ye yes yet you you'd you'll you're you've your yours yourself yourselves yt yu z za zm zr 10 z/
        
        text.downcase!
        stopwords.each do |word|
            text.gsub!(/\b#{word}\b/, '')
        end
        text.gsub!(/^\s+|\s+$/, '')
        text.gsub!(/\s+/, ' ')
        text
    end

    def Utils.lemmatize(text)
        text.gsub!(/`/, "'")
        text.gsub!(/"/, "''")
        text_lemmatized = `echo "#{text}" | ../lib/morph/morpha.ix86_linux -uf ../lib/morph/verbstem.list`
        text_lemmatized.chop!
        text_lemmatized
    end

    def Utils.lemmatize_word(word)
        if word.match(/^["'`]+$/)
            return word
        end
        word_lemmatized = `echo "#{word}" | ../lib/morph/morpha.ix86_linux -uf ../lib/morph/verbstem.list`
        word_lemmatized.chop!
        word_lemmatized
    end

    def Utils.lemmatize_file(file)
        `../lib/morph/morpha -uf < #{file} ../lib/morph/verbstem.list`
    end
    
    def Utils.tokenize(text)
        #the following code copied from Robert MacIntyre's Penn Treebank tokenizer
        #$$textRef =~ s/^"/`` /g;
        text.gsub!(/^"/, '`` ')
        text.gsub!(/``/, ' `` ')     # added 2009/4/1
        #$$textRef =~ s/([ \([{<])"/$1 `` /g;
        text.gsub!(/([ \(\[{<])"/, "\\1 `` ")
        # close quotes handled at end

        #$$textRef =~ s/\.\.\./ ... /g;
        text.gsub!(/\.\.\./, " ... ")
        #$$textRef =~ s/[,;:@#\$%&]/ $& /g;
        text.gsub!(/[,;:@#\$%&]/, " \\& ")

        # Assume sentence tokenization has been done first, so split FINAL periods
        # only. 
        #$$textRef =~ s/([^.])([.])([\])}>"']*)[ \t]*$/$1 $2$3 /g;
        text.gsub!(/([^.])([.])([\])}>"']*)[ \t]*$/, "\\1 \\2\\3 ")
        # however, we may as well split ALL question marks and exclamation points,
        # since they shouldn't have the abbrev.-marker ambiguity problem
        #$$textRef =~ s/[?!]/ $& /g;
        text.gsub!(/[?!]/, " \\& ")

        # parentheses, brackets, etc.
        #$$textRef =~ s/[\]\[\(\){}\<\>]/ $& /g;
        text.gsub!(/[\]\[\(\){}\<\>]/, " \\& ")
        # Some taggers, such as Adwait Ratnaparkhi's MXPOST, use the parsed-file
        # version of these symbols.
        # UNCOMMENT THE FOLLOWING 6 LINES if you're using MXPOST.
        #$$textRef =~ s/\(/-LRB-/g;
        #$$textRef =~ s/\)/-RRB-/g;
        #$$textRef =~ s/\[/-LSB-/g;
        #$$textRef =~ s/\]/-RSB-/g;
        #$$textRef =~ s/{/-LCB-/g;
        #$$textRef =~ s/}/-RCB-/g;

        #$$textRef =~ s/--/ -- /g;
        text.gsub!(/--/, " -- ")

        # NOTE THAT SPLIT WORDS ARE NOT MARKED.  Obviously this isn't great, since
        # you might someday want to know how the words originally fit together --
        # but it's too late to make a better system now, given the millions of
        # words we've already done "wrong".

        # First off, add a space to the beginning and end of each line, to reduce
        # necessary number of regexps.
        #$$textRef =~ s/$/ /;
        text.gsub!(/$/, " ")
        #$$textRef =~ s/^/ /;
        text.gsub!(/^/, " ")

        #$$textRef =~ s/"/ '' /g;
        text.gsub!(/"/, " '' ")
        text.gsub!(/''/, " '' ") # added 2009/4/1 
        # possessive or close-single-quote
        #$$textRef =~ s/([^'])' /$1 ' /g;
        text.gsub!(/([^'])' /, "\\1 ' ")
        # as in it's, I'm, we'd
        #$$textRef =~ s/'([sSmMdD]) / '$1 /g;
        text.gsub!(/'([sSmMdD]) /, " '\\1 ")
        #$$textRef =~ s/'ll / 'll /g;
        text.gsub!(/'ll /, " 'll ")
        #$$textRef =~ s/'re / 're /g;
        text.gsub!(/'re /, " 're ")
        #$$textRef =~ s/'ve / 've /g;
        text.gsub!(/'ve /, " 've ")
        #$$textRef =~ s/n't / n't /g;
        text.gsub!(/n't /, " n't ")
        #$$textRef =~ s/'LL / 'LL /g;
        text.gsub!(/'LL /, " 'LL ")
        #$$textRef =~ s/'RE / 'RE /g;
        text.gsub!(/'RE /, " 'RE ")
        #$$textRef =~ s/'VE / 'VE /g;
        text.gsub!(/'VE /, " 'VE ")
        #$$textRef =~ s/N'T / N'T /g;
        text.gsub!(/N'T /, " N'T ")

        #$$textRef =~ s/ ([Cc])annot / $1an not /g;
        text.gsub!(/ ([Cc])annot /, " \\1an not ")
        #$$textRef =~ s/ ([Dd])'ye / $1' ye /g;
        text.gsub!(/ ([Dd])'ye /, " \\1' ye ")
        #$$textRef =~ s/ ([Gg])imme / $1im me /g;
        text.gsub!(/ ([Gg])imme /, " \\1im me ")
        #$$textRef =~ s/ ([Gg])onna / $1on na /g;
        text.gsub!(/ ([Gg])onna /, " \\1on na ")
        #$$textRef =~ s/ ([Gg])otta / $1ot ta /g;
        text.gsub!(/ ([Gg])otta /, " \\1ot ta ")
        #$$textRef =~ s/ ([Ll])emme / $1em me /g;
        text.gsub!(/ ([Ll])emme /, " \\1em me ")
        #$$textRef =~ s/ ([Mm])ore'n / $1ore 'n /g;
        text.gsub!(/ ([Mm])ore'n /, " \\1ore 'n ")
        #$$textRef =~ s/ '([Tt])is / '$1 is /g;
        text.gsub!(/ '([Tt])is /, " '\\1 is ")
        #$$textRef =~ s/ '([Tt])was / '$1 was /g;
        text.gsub!(/ '([Tt])was /, " '\\1 was ")
        #$$textRef =~ s/ ([Ww])anna / $1an na /g;
        text.gsub!(/ ([Ww])anna /, " \\1an na ")
        # s/ ([Ww])haddya / $1ha dd ya /g;
        # s/ ([Ww])hatcha / $1ha t cha /g;

        # clean out extra spaces
        #$$textRef =~ s/  */ /g;
        text.gsub!(/  */, " ")
        #$$textRef =~ s/^ *//g;	
        text.gsub!(/^ */, "")
        text
    end

    def Utils.cartesian_product(*args)
        result = [[]]
        while [] != args
            t, result = result, []
            b, *args = args
            t.each do |a|
                b.each do |n|
                    result << a + [n]
                end
            end
        end
        result
    end

    def Utils.cartesian_product2(*args)
        result = [[]]
        while [] != args
            t, result = result, []
            b, *args = args
            t.each do |a|
                b.each do |n|
                    if args.size == 0
                        yield(a << n)
                        a.pop
                    else
                        result << a + [n]
                    end
                end
            end
        end
    end

    def Utils.cartesian_product3(arr_arr, curr=[], &blk)
        if arr_arr.size > 1
            arr = arr_arr.first
            arr.each {|e| Utils.cartesian_product3(arr_arr[1..-1], curr << e, &blk); curr.pop}
        else
            arr_arr.first.each {|e| blk.call(curr << e); curr.pop}
        end
    end

    def Utils.cartesian_product4(arr_arr, &blk)
        arr = []
        eval Utils.generate_code(arr_arr, 0)
    end

    def Utils.generate_code(arr_arr, idx)
        "arr_arr[#{idx}].each {|a#{idx}| arr << a#{idx}; " +
        (idx == arr_arr.size - 1 ?
        "blk.call(arr); " :
        generate_code(arr_arr, idx+1)) +
        "arr.pop}; "
    end

    def Utils.combination(n, r)
        return [[]] if n.nil? || n.empty? && r == 0
        return [] if n.nil? || n.empty? && r > 0
        return [[]] if n.size > 0 && r == 0
        c2 = n.clone
        c2.pop
        new_element = n.clone.pop
        Utils.combination(c2, r) + Utils.combination(c2, r-1).map { |l| l << new_element }
    end

    def Utils.permutation(n, r)
        permutations = Array.new
        n.perm(r) {|x| permutations.push(x)}
        permutations
    end

    def Utils.word_level_levenshtein_similarity(str1, str2, pattern=nil)
        Utils.levenshtein_similarity(str1, str2, pattern)
    end

    def Utils.char_level_levenshtein_similarity(str1, str2)
        Utils.levenshtein_similarity(str1, str2, //)
    end

    private
    def Utils.levenshtein_similarity(text1, text2, pattern=//)
        s = text1.split(pattern)
        t = text2.split(pattern)
        m = s.length
        n = t.length

        d = Array.new(m+1)
        d.map! {|c| c = Array.new(n+1)}

        for i in (0..m)
            d[i][0] = i
        end

        for j in (0..n)
            d[0][j] = j
        end

        for i in (1..m)
            for j in (1..n)
                cost = (s[i-1] == t[j-1]) ? 0 : 1
                d[i][j] = [d[i-1][j] + 1, d[i][j-1] + 1, d[i-1][j-1] + cost].min
            end
        end
        #puts d[m][n].to_f
        #puts [m,n].max

        1.0 - (d[m][n].to_f / [m,n].max)
    end
end

class Array
    def perm(n = size)
        if size < n or n < 0
        elsif n == 0
            yield([])
        else
            self[1..-1].perm(n - 1) do |x|
                (0...n).each do |i|
                    yield(x[0...i] + [first] + x[i..-1])
                end
            end
            self[1..-1].perm(n) do |x|
                yield(x)
            end
        end
    end
end

module Enumerable

    class << self
        # Provides the cross-product of two or more Enumerables.
        # This is the class-level method. The instance method
        # calls on this.
        #
        #   Enumerable.cross([1,2], [4], ["apple", "banana"])
        #   #=> [[1, 4, "apple"], [1, 4, "banana"], [2, 4, "apple"], [2, 4, "banana"]]
        #
        #   Enumerable.cross([1,2], [3,4])
        #   #=> [[1, 3], [1, 4], [2, 3], [2, 4]]
        #
        #--
        # TODO Make a more efficient version just for Array (?)
        #++
        def cartesian_product(*enums, &block)
            raise if enums.empty?
            gens = enums.map{|e| Generator.new(e)}
            return [] if gens.any? {|g| g.end?}

            sz = gens.size
            res = []
            tuple = Array.new(sz)

            loop do
                # fill tuple
                (0 ... sz).each { |i|
                    tuple[i] = gens[i].current
                }
                if block.nil?
                    res << tuple.dup
                else
                    block.call(tuple.dup)
                end

                # step forward
                gens[-1].next
                (sz-1).downto(0) do |i|
                    if gens[i].end?
                        if i > 0
                            gens[i].rewind
                            gens[i-1].next
                        else
                            return res
                        end
                    end
                end
            end #loop
        end
    end
    # The instance level version of <tt>Enumerable::cartesian_product</tt>.
    #
    #   a = []
    #   [1,2].cart([4,5]){|elem| a << elem }
    #   a  #=> [[1, 4],[1, 5],[2, 4],[2, 5]]
    #
    #--
    # TODO Make a more efficient version just for Array (?)
    #++

    def cart(*enums, &block)
        Enumerable.cartesian_product(self, *enums, &block)
    end
end

#begin
    #arr = []; 
    #t = Time.now; 
    #Utils.cartesian_product2([1,2,3,4,5,6,7,8,9,nil],[1,2,3,4,5,6,7,8,9,nil],[1,2,3,4,5,6,7,8,9,nil],[1,2,3,4,5,6,7,8,9,nil],[1,2,3,4,5,6,7,8,9,nil],[1,2,3,4,5,6,7,8,9,nil],[1,2,3,4,5,6,7,8,9,nil]) {|a| arr << a}; 
    #Time.now - t
#end
