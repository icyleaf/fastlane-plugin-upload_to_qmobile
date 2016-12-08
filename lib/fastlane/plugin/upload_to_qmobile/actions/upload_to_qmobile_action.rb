require 'qma'

module Fastlane
  module Actions
    module SharedValues
      QMOBILE_PUBLISH_URL = :QMOBILE_PUBLISH_URL
    end

    class UploadToQmobileAction < Action
      def self.run(params)
        @options = params
        @user_key = params.fetch(:api_key)
        @config_file = params.fetch(:config_path)
        @host_type = params.fetch(:host_type).to_sym
        @file = params.fetch(:file)

        UI.user_error! 'You have to either pass an ipa or an apk file' unless @file

        @app = AppInfo.parse(@file)
        @client = QMA::Client.new(@user_key, config_file: @config_file)

        print_table!
        upload!
      end

      def self.print_table!
        params = {
          url: @client.config.send("#{@host_type}_host"),
          channel: @options.fetch(:channel),
          file: @file
        }.merge(query_params)

        FastlaneCore::PrintTable.print_values(config: params,
                                              title: "Summary for upload_to_qmobile #{UploadToQmobile::VERSION}",
                                              hide_keys: [:devices])
      end

      def self.upload!
        UI.message 'Uploading to qmobile ...'
        response = @client.upload(@file, host_type: @host_type, params: query_params)

        case response[:code]
        when 201
          Helper::UploadToQmobileHelper.new_upload(response)
        when 200
          Helper::UploadToQmobileHelper.found_exist(response)
        when 400..428
          Helper::UploadToQmobileHelper.fail_valid(response)
        else
          UI.user_error! json[:message].to_s
        end

        response[:code]
      end

      def self.query_params
        @params = {
          name: @app.name,
          device_type: @app.device_type,
          identifier: @app.identifier,
          release_version: @app.release_version,
          build_version: @app.build_version,

          branch: @options.fetch(:branch),
          last_commit: @options.fetch(:commit),
          ci_url: @options.fetch(:ci_url),
          changelog: @options.fetch(:changelog)
        }.merge(custom_data)
      end

      def self.custom_data
        params = @options[:custom_data] || {}

        if @app.os == 'iOS' && @app.mobileprovision && !@app.mobileprovision.empty?
          params[:release_type] = @app.release_type
          params[:profile_name] = @app.profile_name
          params[:profile_created_at] = @app.mobileprovision.created_date
          params[:profile_expired_at] = @app.mobileprovision.expired_date
          params[:devices] = @app.devices
        end

        if Helper::UploadToQmobileHelper.jenkins?
          params[:ci_name] = ENV['JOB_NAME']
          params[:git_url] = ENV['GIT_URL']
        end

        params
      end

      def self.description
        'Upload mobile app to qmobile'.freeze
      end

      def self.authors
        ["icyleaf"]
      end

      def self.return_value
        Actions.lane_context[SharedValues::QMOBILE_PUBLISH_URL] = url
        ENV[SharedValues::QMOBILE_PUBLISH_URL.to_s] = url
      end

      def self.details
        'Upload apk/ipa app to qmobile'.freeze
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :api_key,
                                       env_name: 'QMOBILE_API_KEY',
                                       description: 'API key',
                                       verify_block: proc do |value|
                                         raise "No API key, please input again".red unless value && !value.empty?
                                       end),
          FastlaneCore::ConfigItem.new(key: :file,
                                       env_name: 'QMOBILE_FILE',
                                       description: 'path to your app file. Optional if you use the `gym`, `ipa`, `xcodebuild` or `gradle` action. ',
                                       default_value: Actions.lane_context[SharedValues::IPA_OUTPUT_PATH] || Dir['*.ipa'].last || Actions.lane_context[SharedValues::GRADLE_APK_OUTPUT_PATH] || Dir['*.apk'].last,
                                       optional: true,
                                       verify_block: proc do |value|
                                         raise "Couldn't find file".red unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :app_name,
                                       env_name: 'QMOBILE_APP_NAME',
                                       description: 'app name',
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :slug,
                                       env_name: 'QMOBILE_SLUG',
                                       description: 'url slug',
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :changelog,
                                       env_name: 'QMOBILE_CHANGELOG',
                                       description: 'changelog',
                                       default_value: ENV['CICL_CHANGELOG'],
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :channel,
                                       env_name: 'QMOBILE_CHANNEL',
                                       description: 'upload channel name',
                                       default_value: 'fastlane',
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :branch,
                                       env_name: 'QMOBILE_GIT_BRANCH',
                                       description: 'git branch name',
                                       default_value: ENV['CICL_BRANCH'],
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :commit,
                                       env_name: 'QMOBILE_GIT_COMMIT',
                                       description: 'git last commit',
                                       default_value: ENV['CICL_COMMIT'],
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :ci_url,
                                       env_name: 'QMOBILE_CI_URL',
                                       default_value: ENV['CICL_URL'],
                                       description: 'ci url',
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :config_path,
                                       env_name: 'QMOBILE_CONFIG_PATH',
                                       description: 'The path to qma confiuration file',
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :host_type,
                                       env_name: 'QMOBILE_HOST_TYPE',
                                       description: 'The host type to upload host domain',
                                       default_value: 'external',
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :custom_data,
                                       env_name: 'QMOBILE_CUSTOM_DATA',
                                       description: 'Custom data to build query params',
                                       optional: true)
        ]
      end

      def self.is_supported?(platform)
        [:ios, :android].include?(platform)
      end
    end
  end
end