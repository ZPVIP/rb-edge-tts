# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RbEdgeTTS::Util do
  describe '.escape_xml' do
    it 'escapes XML special characters' do
      escaped = RbEdgeTTS::Util.escape_xml('<>&"\'')
      expect(escaped).to eq('&lt;&gt;&amp;&quot;&#39;')
    end
  end

  describe '.unescape_xml' do
    it 'unescapes XML entities' do
      unescaped = RbEdgeTTS::Util.unescape_xml('&lt;&gt;&amp;&quot;&#39;')
      expect(unescaped).to eq('<>&"\'')
    end
  end

  describe '.split_text_by_byte_length' do
    it 'splits text into chunks' do
      text = 'a' * 100
      chunks = RbEdgeTTS::Util.split_text_by_byte_length(text, 30).to_a
      expect(chunks.size).to eq(4)
    end

    it 'preserves UTF-8 boundaries' do
      text = '你好世界' * 10
      chunks = RbEdgeTTS::Util.split_text_by_byte_length(text, 10).to_a
      expect(chunks.all? { |chunk| chunk.valid_encoding? }).to be true
    end
  end

  describe '.connect_id' do
    it 'generates a connection ID without dashes' do
      id = RbEdgeTTS::Util.connect_id
      expect(id).not_to match(/-/)
      expect(id.length).to eq(32)
    end
  end
end
