# frozen_string_literal: true

class HackerNewsParserService
  include ActionView::Helpers::TextHelper
  require 'nokogiri'
  require 'readability'

  HACKER_NEWS_URL = 'https://news.ycombinator.com/best'
  TITLE_META_LIST = [
    "//meta[@property='og:title']",
    "//meta[@property='article:title']",
    "//meta[@name='twitter:title']",
    "//meta[@name='title']"
  ].freeze
  DESCRIPTION_META_LIST = [
    "//meta[@name='description']",
    "//meta[@property='og:description']",
    "//meta[@name='twitter:description']",
    "//meta[@property='article:description']"
  ].freeze
  COVER_IMAGE_META_LIST = [
    "//meta[@property='og:image']",
    "//meta[@name='twitter:image']"
  ].freeze
  HTML_PARAGRAPH_TAGS = %w(p).freeze
  HTML_HEADING_TAGS = %w(h1 h2 h3 h4 h5 h6).freeze
  HTML_LIST_TAGS = %w(ol ul).freeze

  attr_reader :page, :url

  def initialize(params = {})
    @page = params[:page] || 1
    @url = params[:url]
  end

  def crawl_general_information
    response = HTTParty.get("#{HACKER_NEWS_URL}?p=#{page}")
    nokogiri_document = Nokogiri::HTML(response.body)
    posts = []

    nokogiri_document.css('tr.athing').each do |main_node|
      id = main_node.attributes['id'].value
      title = parse_title(main_node)
      url = parse_url(main_node)
      site_name = parse_site_name(main_node)
      sub_text = parse_sub_text(main_node.next)

      post = cached_post(id, { title: title, url: url, site_name: site_name, sub_text: sub_text })
      posts << post
    end

    posts
  end

  def crawl_detail
    Rails.cache.fetch("#{url}/detail_post_cached", expired_in: 24.hours) do
      response = HTTParty.get(url)
      document = Nokogiri::HTML(response.body)

      title = parse_detail_title(document)
      description = parse_detail_description(document)
      cover_image = parse_cover_image(document)
      content = parse_detail_content(response.body)

      Post.new(title: title, url: url, description: description, cover_image: cover_image, content: content)
    end
  end

  private

  def cached_post(id, attributes = {})
    Rails.cache.fetch("#{id}/general_information_post_cached", expired_in: 24.hours) do
      post = Post.new(attributes)

      # Crawl cover image
      post_detail_response = HTTParty.get(post.url) rescue nil
      post.cover_image = parse_cover_image(Nokogiri::HTML(post_detail_response.body)) if post_detail_response

      post
    end
  end

  def base_url
    uri = URI(url)
    uri.host
  end

  def is_blank?(node)
    node.content.strip == '' || (node.element? && node.name == 'br')
  end

  def is_header?(node)
    node.element? && node.name == 'header' || \
      node.respond_to?(:parent) && node.parent.name == 'header'
  end

  def is_footer?(node)
    node.element? && node.name == 'footer' || \
      node.respond_to?(:parent) && node.parent.name == 'footer'
  end

  def is_list?(node)
    HTML_LIST_TAGS.include?(node.name) || node.search(*HTML_LIST_TAGS).present?
  end

  def is_paragraph?(node)
    HTML_PARAGRAPH_TAGS.include?(node.name)
  end

  def is_heading?(node)
    HTML_HEADING_TAGS.include?(node.name)
  end

  def is_phrase_code?(node)
    node.name == 'code'
  end

  def is_script?(node)
    node.name == 'script' || node.search('script').present?
  end

  def parse_title(node)
    node.css('.title > a:first-child').text
  end

  def parse_url(node)
    node.css('.title > a:first-child').attribute('href').value
  end

  def parse_site_name(node)
    node.css('.sitestr').text
  end

  def parse_sub_text(node)
    node.css('.subtext').text.squish
  end

  def parse_detail_title(node)
    title = node.xpath(*TITLE_META_LIST).map {|element| element.attributes['content'].value }.first
    title = node.xpath('//title').text if title.nil?

    title
  end

  def parse_detail_description(node)
    node.xpath(*DESCRIPTION_META_LIST).map {|element| element.attributes['content'].value }.first
  end

  def parse_cover_image(node)
    cover_image = node.xpath(*COVER_IMAGE_META_LIST).map {|element| element.attributes['content'].value }.first
    cover_image = node.css('body img').map { |image| image.attributes['src'].try(:value) }.first if cover_image.nil?

    cover_image
  end

  def parse_detail_content(html_body_response)
    content_filters = YAML.load_file(Rails.root.join('config/content_filters.yml'))

    unless (filter = content_filters[base_url])
      content = Readability::Document.new(html_body_response).content.squish
    else
      # When Readability::Document crawls not enough information, we will handle by ourself
      node = Nokogiri::HTML(html_body_response)
      needed_elements = filter.is_a?(Array) ? node.search(filter.join(',')) : node.search(filter['selector']).children
      paragraphs = []
      needed_elements.each do |element|
        next if is_blank?(element) || is_header?(element) || is_footer?(element) || is_script?(element)

        paragraph = if is_paragraph?(element) || is_heading?(element)
                      content_tag(element.name, element.content)
                    elsif is_list?(element)
                      ul_content = element.css('li').map(&:text).map { |text| content_tag(:li, text) }.join
                      content_tag(:ul, sanitize(ul_content))
                    elsif is_phrase_code?(element)
                      content_tag(:code, element.content)
                    else
                      content_tag(:p, element.content)
                    end

        paragraphs << paragraph
      end

      content = paragraphs.join
    end

    content_tag(:div, sanitize(content))
  end
end
