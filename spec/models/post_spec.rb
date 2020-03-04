require 'rails_helper'

RSpec.describe Post, type: :model do
  describe '#url' do
    let(:post) { Post.new(url: url) }

    subject { post.url }

    context 'when url is empty' do
      let(:url) { nil }

      it 'returns nil' do
        expect(subject).to eq nil
      end
    end

    context 'when url contains http/https' do
      let(:url) { 'http://example.com' }

      it 'returns itself' do
        expect(subject).to eq url
      end
    end

    context 'when url does not contain http/https' do
      let(:url) { '/example' }

      it 'returns full url' do
        expect(subject).to eq (Post::HACKER_NEWS_URL + url)
      end
    end
  end

  describe '#cover_image' do
    let(:url) { nil }
    let(:post) { Post.new(cover_image: cover_image, url: url) }

    subject { post.cover_image }

    context 'when cover_image is empty' do
      let(:cover_image) { nil }

      it 'returns nil' do
        expect(subject).to eq nil
      end
    end

    context 'when cover_image contains http/https' do
      let(:cover_image) { 'http://example.com/image.png' }

      context 'but that cover_image file is not exists' do
        it 'returns nil' do
          allow(post).to receive(:remote_file_exists?).and_return(false)

          expect(subject).to eq nil
        end
      end

      context 'and cover_image file is exists' do
        it 'returns cover_image full url itself' do
          allow(post).to receive(:remote_file_exists?).and_return(true)

          expect(subject).to eq cover_image
        end
      end
    end

    context 'when cover_image does not contain http/https' do
      let(:cover_image) { '/image.png' }

      context 'and the post has specific url' do
        let(:url) { 'http://example.com/post.html' }

        it 'returns full cover_image url with the same host' do
          allow(post).to receive(:remote_file_exists?).and_return(true)

          expect(subject).to eq 'http://example.com//image.png'
        end
      end
    end
  end
end
