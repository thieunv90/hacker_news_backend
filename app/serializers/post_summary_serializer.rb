class PostSummarySerializer < ActiveModel::Serializer
  attributes :title, :url, :site_name, :sub_text, :cover_image
end
