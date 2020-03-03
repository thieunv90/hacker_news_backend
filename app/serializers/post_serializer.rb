class PostSerializer < ActiveModel::Serializer
  attributes :title, :cover_image, :content, :description
end
