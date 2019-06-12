# CodecFactory:
# lazy-fetch codec plugins
# (FIXME: is this thread-safe?)
require "logstash/inputs/threadable"

module LogStash module Inputs class S3SNSSQS < LogStash::Inputs::Threadable
  class CodecFactory
    def initialize(logger, options)
      @logger = logger
      @default_codec = options[:default_codec]
      @codec_by_folder = options[:codec_by_folder]
      @codecs = {
        'default' => get_codec_plugin(@default_codec, { 'charset' => 'UTF-8' })
      }
    end

    def get_codec(record)
      codec = find_codec(record)
      if @codecs[codec].nil?
        @codecs[codec] = get_codec_plugin(codec)
      end
      @logger.debug("Switching to codec #{codec}") if codec != 'default'
      return @codecs[codec]
    end

    private

    def find_codec(record)
      bucket, key = record[:bucket], record[:key]
      if @codec_by_folder[bucket]
        folder = get_type_folder(key)
        if @codec_by_folder[bucket].key?(folder)
          return @codec_by_folder[bucket][folder]
        end
      end
      return 'default'
    end

    def get_type_folder(key)
      # TEST THIS!
      # if match = /.*\/?(?<type_folder>)\/[^\/]*.match(key)
      #   return match['type_folder']
      # end
      folder = File.dirname(key)
      return '' if folder == '.'
      return folder
    end

    def get_codec_plugin(name, options = {})
      LogStash::Plugin.lookup('codec', name).new(options)
    end
  end
end;end;end
