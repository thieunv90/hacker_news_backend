require 'rails_helper'

RSpec.describe HackerNewsParserService do
  describe '#crawl_general_information' do
    let(:page) { 1 }
    let(:hacker_news_url) { "https://news.ycombinator.com/best?p=#{page}" }
    let(:hacker_news_response) { instance_double(HTTParty::Response, body: hacker_news_response_body) }
    let(:hacker_news_response_body) { File.read("spec/fixtures/files/hacker_news_page.html").to_s }

    subject { described_class.new(page: page).crawl_general_information }

    before do
      allow(HTTParty).to receive(:get).and_return(hacker_news_response)
    end

    it 'fetches the html content from hackes new page' do
      subject
      expect(HTTParty).to have_received(:get).with(hacker_news_url)
    end

    context 'when hacker news page has correct html content' do
      let(:hacker_news_post1_id) { '22448933' }
      let(:hacker_news_post1_title) { 'Freeman Dyson Has Died' }
      let(:hacker_news_post1_url) { 'https://www.nytimes.com/2020/02/28/science/freeman-dyson-dead.html' }
      let(:hacker_news_post1_site_name) { 'nytimes.com' }
      let(:hacker_news_post1_subtext) { '1234 points by ChickeNES 3 days ago | 246 comments' }

      it 'fetchs the post title' do
        expect(subject.map { |post| post.title }).to include hacker_news_post1_title
      end

      it 'fetchs the post url' do
        expect(subject.map { |post| post.url }).to include hacker_news_post1_url
      end

      it 'fetchs the post site_name' do
        expect(subject.map { |post| post.site_name }).to include hacker_news_post1_site_name
      end

      it 'fetchs the post sub_text' do
        expect(subject.map { |post| post.sub_text }).to include hacker_news_post1_subtext
      end

      it 'returns array list of posts' do
        expect(subject.map(&:class)).to eq [Post, Post]
      end

      context 'caching' do
        let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }
        let(:cache) { Rails.cache }

        before do
          allow(Rails).to receive(:cache).and_return(memory_store)
          Rails.cache.clear
        end

        it 'caches the post information' do
          expect(cache.exist?("#{hacker_news_post1_id}/general_information_post_cached")).to be(false)
          subject
          expect(cache.exist?("#{hacker_news_post1_id}/general_information_post_cached")).to be(true)
        end
      end
    end

    context 'when hacker news page has wrong html content' do
      let(:hacker_news_response_body) { 'wrong content' }

      it 'returns empty array' do
        expect(subject).to eq []
      end
    end
  end

  describe '#crawl_detail' do
    let(:specific_news_url) { 'http://example.com' }
    let(:specific_news_response) { instance_double(HTTParty::Response, body: specific_news_response_body) }
    let(:specific_news_response_body) { File.read("spec/fixtures/files/specific_news_page.html").to_s }

    subject { described_class.new(url: specific_news_url).crawl_detail }

    before do
      allow(HTTParty).to receive(:get).and_return(specific_news_response)
      allow_any_instance_of(Post).to receive(:remote_file_exists?).and_return(true)
    end

    it 'fetches the html content from hackes new page' do
      subject
      expect(HTTParty).to have_received(:get).with(specific_news_url)
    end

    it 'fetchs the post title' do
      expect(subject.title).to eq 'title'
    end

    it 'fetchs the post description' do
      expect(subject.description).to eq 'description'
    end

    it 'fetchs the post cover image' do
      expect(subject.cover_image).to eq 'http://image.png'
    end

    it 'fetchs the post content' do
      expect(subject.content).to include 'Content'
    end

    it 'returns post object' do
      expect(subject.class).to eq Post
    end

    context 'caching' do
      let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }
      let(:cache) { Rails.cache }

      before do
        allow(Rails).to receive(:cache).and_return(memory_store)
        Rails.cache.clear
      end

      it 'caches the post information' do
        expect(cache.exist?("#{specific_news_url}/detail_post_cached")).to be(false)
        subject
        expect(cache.exist?("#{specific_news_url}/detail_post_cached")).to be(true)
      end
    end
  end
end
