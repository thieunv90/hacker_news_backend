class Post
  include ActiveModel::Serialization
  extend ActiveModel::Naming

  URL_REGEX = /https?:\/\/[\S]+/
  INTERNAL_URL = 'https://news.ycombinator.com/'

  attr_reader :title, :url, :site_name, :sub_text, :content, :cover_image, :description
  attr_writer :cover_image

  def initialize(attributes)
    @title = attributes[:title]
    @url = attributes[:url]
    @site_name = attributes[:site_name]
    @sub_text = attributes[:sub_text]
    @content = attributes[:content]
    @cover_image = attributes[:cover_image]
    @description = attributes[:description]
  end

  def url
    return unless @url

    unless @url.match(URL_REGEX)
      INTERNAL_URL + @url
    else
      @url
    end
  end

  def cover_image
    return unless @cover_image

    if url && !@cover_image.match(URL_REGEX)
      uri = URI(url)
      "#{uri.scheme}://#{uri.host}/" + @cover_image
    else
      @cover_image
    end
  end
end
