class Paragraph
    attr_accessor :sentences, :article, :id

    def initialize(all_sents, start_sid, end_sid, id)
        @sentences = all_sents[start_sid ... end_sid]
        @id = id
    end

    def length
        @sentences.size
    end

    def has_nonexp_relation?(i)
        sid1 = @sentences[i].id
        sid2 = @sentences[i+1].id
        @article.relations.each {|relation|
            next if relation[1] != "Implicit" and relation[1] != "AltLex" and 
                relation[1] != "EntRel" and relation[1] != "NoRel"  

            rsid1 = relation.arg1_leaves.last.goto_tree.sent_id
            rsid2 = relation.arg2_leaves.first.goto_tree.sent_id

            if sid1 == rsid1 and sid2 == rsid2 then
                puts '    ' + sid1.to_s + ' ' + sid2.to_s
                return relation
            end
        }
        puts sid1.to_s + ' ' + sid2.to_s
        false
    end

    def has_exp_relation?(i)
        sid1 = @sentences[i].id
        sid2 = @sentences[i+1].id
        @article.exp_relations_p.each {|relation|
            if relation.arg1_sid == sid1 and relation.arg2_sid == sid2
                return true
            end
        }
        return false
    end
end
