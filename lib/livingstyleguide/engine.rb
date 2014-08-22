module LivingStyleGuide

  class Engine
    attr_accessor :markdown, :files, :options

    @@default_options = {
      default_language: 'example',
      title: 'Living Style Guide',
      header: '<h1 class="livingstyleguide--page-title">Living Style Guide</h1>',
      footer: '<div class="livingstyleguide--footer"><a class="livingstyleguide--logo" href="http://livingstyleguide.org">Made with the LivingStyleGuide gem.</a></div>',
      root: '/'
    }

    def self.default_options
      @@default_options
    end

    def initialize(source, options, sass_options)
      @source = source
      @options = @@default_options.merge(options)
      @sass_options = sass_options
    end

    def render
      data = TemplateData.new(self)
      template = File.read(File.join(File.dirname(__FILE__), '..', '..', 'templates', 'layouts', 'default.html.erb'))
      ERB.new(template).result(data.get_binding)
    end

    def files
      @files ||= generate_file_list(sass_engine.to_tree)
    end

    def markdown
      @markdown ||= generate_markdown
    end

    def css
      sass_engine.render
    end

    def html
      renderer = RedcarpetHTML.new(@options)
      redcarpet = ::Redcarpet::Markdown.new(renderer, REDCARPET_RENDER_OPTIONS)
      redcarpet.render(markdown)
    end

    private
    def generate_file_list(node)
      list = []
      list << node.filename if node.filename =~ /\.s[ac]ss/
      node.children.each do |child|
        if child.is_a?(Sass::Tree::ImportNode)
          list += generate_file_list(child.imported_file.to_tree)
        end
      end
      list
    end

    private
    def sass_engine
      return @sass_engine if @sass_engine
      sass_options = @sass_options.clone
      sass_options[:living_style_guide] = self
      @sass_engine = ::Sass::Engine.new(@source, sass_options)
    end

    private
    def generate_markdown
      source = ''
      files.clone.each do |sass_filename|
        glob = "#{sass_filename.sub(/\.s[ac]ss$/, '')}.md"
        Dir.glob(glob) do |markdown_filename|
          files << markdown_filename
          source << File.read(markdown_filename)
        end
      end
      source
    end

  end

  class TemplateData
    include ERB::Util

    def initialize(engine)
      @engine = engine
    end

    def get_binding
      binding
    end

    def title
      @engine.options[:title]
    end

    def css
      @engine.css
    end

    def html
      @engine.html
    end

    def head
      javascript_tags_for(@engine.options[:javascript_before]).join("\n")
    end

    def header
      contents = [@engine.options[:header]]
      contents.join("\n")
    end

    def footer
      contents = [@engine.options[:footer]]
      contents << javascript_tags_for(@engine.options[:javascript_after])
      contents.join("\n")
    end

    private
    def javascript_tags_for(list)
      return [] unless list
      list.map do |src|
        if src =~ /\.js$/
          %Q(<script src="#{src}"></script>)
        else
          %Q(<script>#{src}</script>)
        end
      end
    end

  end

end

