class MarkdownRenderer
  ALLOWED_TAGS = %w[p br strong em a ul ol li h1 h2 h3 h4 h5 h6 hr del
                    table thead tbody tr th td blockquote].freeze
  ALLOWED_ATTRIBUTES = %w[href title].freeze

  def initialize
    renderer = Redcarpet::Render::HTML.new(hard_wrap: true)
    @markdown = Redcarpet::Markdown.new(renderer,
      autolink: true,
      no_intra_emphasis: true,
      strikethrough: true,
      tables: true
    )
    @sanitizer = Rails::HTML5::SafeListSanitizer.new
  end

  def to_html(text)
    return "" if text.blank?

    html = @markdown.render(text)
    @sanitizer.sanitize(html, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES).html_safe
  end

  def to_text(text)
    text.to_s
  end
end
