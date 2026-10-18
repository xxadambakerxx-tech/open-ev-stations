module LazyImages
  def self.apply(output)
    output.gsub(/<img\b(?![^>]*\bloading\s*=)[^>]*>/i) do |tag|
      tag.sub(/\s*(\/?)>\z/) { |ending| " loading=\"lazy\"#{ending.include?("/") ? "/" : ""}>" }
    end
  end
end

Jekyll::Hooks.register :pages, :post_render do |page|
  page.output = LazyImages.apply(page.output)
end

Jekyll::Hooks.register :documents, :post_render do |document|
  document.output = LazyImages.apply(document.output)
end
