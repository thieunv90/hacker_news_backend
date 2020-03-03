require 'rails_helper'

describe PostsController do
  describe '#index' do
    let(:post1) { Post.new(title: 'Title 1', url: 'http://url1.com') }
    let(:post2) { Post.new(title: 'Title 2', url: 'http://url2.com') }

    subject { get :index }

    context 'when system works normally' do
      before do
        allow_any_instance_of(HackerNewsParserService).to receive(:crawl_general_information)
          .and_return([post1, post2])
      end

      it { is_expected.to be_successful }

      it 'returns valid JSON' do
        body = JSON.parse(subject.body)
        expect(body[0]['title']).to eq 'Title 1'
        expect(body[0]['url']).to eq 'http://url1.com'
        expect(body[1]['title']).to eq 'Title 2'
        expect(body[1]['url']).to eq 'http://url2.com'
      end
    end

    context 'an exeption occurs while processing' do
      before do
        allow_any_instance_of(HackerNewsParserService).to receive(:crawl_general_information)
          .and_raise('Exception')
      end

      it 'responds with 422' do
        expect(subject.status).to eq 422
      end

      it 'returns JSON with error message' do
        body = JSON.parse(subject.body)

        expect(body['message']).to eq 'Exception'
      end
    end
  end

  describe '#detail' do
    let(:post) { Post.new(title: 'Title', description: 'Description') }

    subject { get :detail }

    context 'when system works normally' do
      before do
        allow_any_instance_of(HackerNewsParserService).to receive(:crawl_detail)
          .and_return(post)
      end

      it { is_expected.to be_successful }

      it 'returns valid JSON' do
        body = JSON.parse(subject.body)
        expect(body['title']).to eq 'Title'
        expect(body['description']).to eq 'Description'
      end
    end

    context 'an exeption occurs while processing' do
      before do
        allow_any_instance_of(HackerNewsParserService).to receive(:crawl_detail)
          .and_raise('Exception')
      end

      it 'responds with 422' do
        expect(subject.status).to eq 422
      end

      it 'returns JSON with error message' do
        body = JSON.parse(subject.body)

        expect(body['message']).to eq 'Exception'
      end
    end
  end
end
