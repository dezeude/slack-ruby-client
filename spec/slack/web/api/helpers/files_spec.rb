# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Slack::Web::Api::Helpers::Files do
  subject(:client) { Slack::Web::Client.new }

  describe '#files_upload_v2' do
    it 'requires a filename' do
      expect { client.files_upload_v2(content: 'hello') }.to(
        raise_error(ArgumentError, 'required argument :`filename` missing in file (`0`)')
      )
    end

    it 'requires content' do
      expect { client.files_upload_v2(filename: 'hello.txt') }.to(
        raise_error(ArgumentError, 'required argument :`content` missing in file (`0`)')
      )
    end

    it 'identifies the invalid file in a batch' do
      files = [{ filename: 'hello.txt', content: 'hello' }, { content: 'world' }]
      expect { client.files_upload_v2(files: files) }.to(
        raise_error(ArgumentError, 'required argument :`filename` missing in file (`1`)')
      )
    end

    it 'rejects conflicting channel arguments' do
      expect do
        client.files_upload_v2(filename: 'hello.txt', content: 'hello', channel: '#general', channel_id: 'C123456')
      end.to raise_error(ArgumentError, 'only one of :channel, :channels, or :channel_id is required')
    end

    it 'passes username and icon options to files.completeUploadExternal' do
      stub_request(:post, 'https://slack.com/api/files.getUploadURLExternal')
        .to_return(body: { ok: true, upload_url: 'https://files.slack.test/upload', file_id: 'F123' }.to_json)
      stub_request(:post, 'https://files.slack.test/upload').with(body: 'hello')
      complete = stub_request(:post, 'https://slack.com/api/files.completeUploadExternal')
                 .with(body: {
                         files: [{ id: 'F123', title: 'hello.txt' }].to_json,
                         channel_id: 'C123456',
                         username: 'Reports Bot',
                         icon_emoji: ':bar_chart:',
                         icon_url: 'https://example.com/icon.png'
                       })
                 .to_return(body: { ok: true }.to_json)

      client.files_upload_v2(
        filename: 'hello.txt', content: 'hello', channel_id: 'C123456',
        username: 'Reports Bot', icon_emoji: ':bar_chart:', icon_url: 'https://example.com/icon.png'
      )

      expect(complete).to have_been_requested
    end
  end
end
