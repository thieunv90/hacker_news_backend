class PostsController < ApplicationController
  def index
    posts = HackerNewsParserService.new(page: params[:page]).crawl_general_information

    render json: posts, each_serializer: PostSummarySerializer
  rescue StandardError => e
    render_error(code: 422, message: e.message)
  end

  def detail
    post = HackerNewsParserService.new(url: params[:url]).crawl_detail

    render json: post
  rescue StandardError => e
    render_error(code: 422, message: e.message)
  end
end
