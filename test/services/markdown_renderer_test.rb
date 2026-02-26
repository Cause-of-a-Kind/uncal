require "test_helper"

class MarkdownRendererTest < ActiveSupport::TestCase
  setup do
    @renderer = MarkdownRenderer.new
  end

  # Basic rendering

  test "renders bold text" do
    html = @renderer.to_html("**hello**")
    assert_includes html, "<strong"
    assert_includes html, "hello"
  end

  test "renders italic text" do
    html = @renderer.to_html("*hello*")
    assert_includes html, "<em>"
    assert_includes html, "hello"
  end

  test "renders links" do
    html = @renderer.to_html("[click here](https://example.com)")
    assert_includes html, 'href="https://example.com"'
    assert_includes html, "click here"
  end

  test "renders unordered lists" do
    html = @renderer.to_html("- item one\n- item two")
    assert_includes html, "<ul"
    assert_includes html, "<li"
    assert_includes html, "item one"
  end

  test "renders ordered lists" do
    html = @renderer.to_html("1. first\n2. second")
    assert_includes html, "<ol"
    assert_includes html, "first"
  end

  test "renders headings" do
    html = @renderer.to_html("## Hello")
    assert_includes html, "<h2"
    assert_includes html, "Hello"
  end

  test "autolinks bare URLs" do
    html = @renderer.to_html("Visit https://example.com today")
    assert_includes html, 'href="https://example.com"'
  end

  test "hard wraps single newlines to br" do
    html = @renderer.to_html("line one\nline two")
    assert_includes html, "<br"
  end

  test "renders strikethrough" do
    html = @renderer.to_html("~~deleted~~")
    assert_includes html, "<del"
    assert_includes html, "deleted"
  end

  # Sanitization

  test "strips script tags" do
    html = @renderer.to_html('<script>alert("xss")</script>')
    refute_includes html, "<script"
  end

  test "strips onclick attributes" do
    html = @renderer.to_html('<a href="#" onclick="alert(1)">click</a>')
    refute_includes html, "onclick"
  end

  test "strips iframe tags" do
    html = @renderer.to_html('<iframe src="https://evil.com"></iframe>')
    refute_includes html, "<iframe"
  end

  test "preserves allowed tags through sanitization" do
    html = @renderer.to_html("**bold** and *italic*")
    assert_includes html, "<strong"
    assert_includes html, "<em>"
  end

  # Edge cases

  test "handles nil input" do
    assert_equal "", @renderer.to_html(nil)
  end

  test "handles empty string" do
    assert_equal "", @renderer.to_html("")
  end

  test "to_text returns input unchanged" do
    text = "**bold** and [link](url)"
    assert_equal text, @renderer.to_text(text)
  end

  test "returns html_safe string" do
    html = @renderer.to_html("hello")
    assert_predicate html, :html_safe?
  end
end
