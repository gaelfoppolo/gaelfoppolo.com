# frozen_string_literal: true

module Jekyll
  class NoticeBlock < Liquid::Block
    def initialize(tag_name, arguments, tokens)
      super

      @type = tag_name
    end

    def render(context)
      content = super
      <<~EOD
        <aside class="notice #{@type}" markdown="1">
         #{content}
        </aside>
      EOD
    end
  end
end

%w[standard info warning success error].each do |notice|
  Liquid::Template.register_tag(notice, Jekyll::NoticeBlock)
end