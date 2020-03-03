namespace :cache do
  desc "Crawling and caching article information"
  task cache_article_information: :environment do
    begin
      page = 1
      loop do
        posts = HackerNewsParserService.new(page: page).crawl_general_information

        break if posts.blank?

        page += 1
      end
    rescue StandardError => e
      p "[ERROR] - #{e.message}"
    end
  end
end
