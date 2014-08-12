require File.dirname(__FILE__)+'/article'

class Section
    attr_accessor :section_id, :pdtb_section_dir, :ptb_section_dir, :dtree_section_dir, :articles
  
    def initialize(section_id, pdtb_section_dir, ptb_section_dir, dtree_section_dir='')
        @section_id = section_id
        @pdtb_section_dir = pdtb_section_dir
        @ptb_section_dir = ptb_section_dir
        @dtree_section_dir = dtree_section_dir

        @articles = Array.new()
        Dir.new(@pdtb_section_dir).sort.each do |filename|
            #if filename != "." and filename != ".."
            if not filename.match(/^\./)
                parsed_filename = filename.sub('.pipe', '.mrg')
                dtree_filename = filename.sub('.pipe', '.dtree')
                @articles.push Article.new(filename, 
                    @pdtb_section_dir+"/"+filename, @ptb_section_dir+"/"+parsed_filename,
                    @dtree_section_dir+"/"+dtree_filename)
            end
        end
    end
end
