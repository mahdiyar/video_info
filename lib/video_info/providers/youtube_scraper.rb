require 'oga'
require 'open-uri'
require 'net_http_timeout_errors'

class VideoInfo
  module Providers
    module YoutubeScraper
      def date
        date = itemprop_node_value('datePublished')

        Time.parse(date) unless !date
      end

      def description
        meta_node_value('description')
      end

      def duration
        duration = itemprop_node_value('duration')

        if duration
          ISO8601::Duration.new(duration).to_seconds.to_i
        else
          0
        end
      end

      def keywords
        value = meta_node_value('keywords')

        value.split(', ') unless !value
      end

      def title
        meta_node_value('title')
      end

      def view_count
        data.css('div.watch-view-count').text.gsub(/\D/, '').to_i
      end

      private

      def meta_nodes
        @meta_nodes ||= data.css('meta')
      end

      def meta_node_value(name)
        if available?
          node = meta_nodes.detect { |n| n.attr('name').value == name }

          node.attr('content').value
        end
      end

      def itemprop_node_value(name)
        if available?
          node = meta_nodes.detect do |m|
            itemprop_attr = m.attr('itemprop')

            itemprop_attr.value == name unless !itemprop_attr
          end

          node.attr('content').value
        end
      end

      def available?
        data.css('div#unavailable-submessage').text.strip.empty?
      end

      def _set_data_from_api_impl(api_url)
        uri = URI(api_url)

        unless uri.scheme
          uri.path = uri.path.prepend('//')
          uri.scheme = 'http'
        end

        # handle fullscreen video URLs
        if url.include?('.com/v/')
          video_id = url.split('/v/')[1].split('?')[0]
          new_url = 'https://www.youtube.com/watch?v=' + video_id
          Oga.parse_html(open(new_url).read)
        else
          Oga.parse_html(open(uri.to_s, allow_redirections: :safe).read)
        end
      end

      def _api_url
        @url
      end
    end
  end
end
