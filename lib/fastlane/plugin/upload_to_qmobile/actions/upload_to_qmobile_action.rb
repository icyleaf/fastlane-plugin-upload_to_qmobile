require 'qma'

module Fastlane
  module Actions
    module SharedValues
      QMOBILE_PUBLISH_URL = :QMOBILE_PUBLISH_URL
    end

    class UploadToQmobileAction < Action
      def self.run(options)
        @options = options
        @user_key = options.fetch(:api_key)
        @config_file = options.fetch(:config_path)
        @host_type = options.fetch(:host_type).to_sym
        @file = options.fetch(:file)

        UI.user_error! 'You have to either pass an ipa or an apk file' unless @file

        @app = ::AppInfo.parse(@file)
        @client = ::QMA::Client.new(
          @user_key,
          version: options[:api_version],
          timeout: options[:timeout],
          config_file: @config_file
        )

        print_table!
        upload!
      end

      def self.print_table!
        params = {
          channel: @options[:channel],
          timeout: @options[:timeout],
          url: @client.request_url(@host_type),
          file: @file,
          icon: File.basename(app_icon_file)
        }.merge(query_params)

        FastlaneCore::PrintTable.print_values(config: params,
                                              title: "Summary for upload_to_qmobile #{UploadToQmobile::VERSION}",
                                              hide_keys: [:devices, :changelog])
      end

      def self.upload!
        UI.message 'Uploading to qmobile ...'
        response = @client.upload(@file, host_type: @host_type, params: query_params.merge({ icon: File.open(app_icon_file) }))

        case response[:code]
        when 201
          Helper::UploadToQmobileHelper.new_upload(response)
        when 200
          Helper::UploadToQmobileHelper.found_exist(response)
        when 400..500
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

          channel: @options[:channel],
          branch: @options[:branch],
          last_commit: @options[:commit],
          ci_url: @options[:ci_url],
          changelog: @options[:changelog]
        }.merge(custom_data)
      end

      def self.custom_data
        params = @options[:custom_data] || {}

        if @app.os == 'iOS' && @app.mobileprovision && !@app.mobileprovision.empty?
          params[:release_type] = @app.release_type
          params[:devices] = @app.devices if @app.devices
        end

        if Helper::UploadToQmobileHelper.jenkins?
          params[:ci_name] = ENV['JOB_NAME']
          params[:git_url] = ENV['GIT_URL']
        end

        params
      end

      def self.app_icon_file
        return @icon_file if @icon_file

        @icon_file = @app.icons.try(:[], -1).try(:[], :file)
        if !@icon_file.empty? && File.exist?(@icon_file)
          Pngdefry.defry(@icon_file, @icon_file)
        end

        @icon_file
      end

      def self.description
        'Upload mobile app to qmobile.'.freeze
      end

      def self.authors
        ["icyleaf <icyleaf.cn@gmail.com>"]
      end

      def self.output
        [
          [SharedValues::QMOBILE_PUBLISH_URL.to_s, 'the build url of deliver to qmobile']
        ]
      end

      def self.details
        'Deliver any ipa or apk file but only running with qyer inc, better works with ci_changelog plugin'.freeze
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
                                       optional: true),
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
                                       description: 'changelog (automatic detect with ci_changelog)',
                                       default_value: ENV['CICL_CHANGELOG'],
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :channel,
                                       env_name: 'QMOBILE_CHANNEL',
                                       description: 'upload channel name',
                                       default_value: 'fastlane',
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :branch,
                                       env_name: 'QMOBILE_GIT_BRANCH',
                                       description: 'git branch name (automatic detect with ci_changelog)',
                                       default_value: ENV['CICL_BRANCH'],
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :commit,
                                       env_name: 'QMOBILE_GIT_COMMIT',
                                       description: 'git last commit (automatic detect with ci_changelog)',
                                       default_value: ENV['CICL_COMMIT'],
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :ci_url,
                                       env_name: 'QMOBILE_CI_URL',
                                       default_value: ENV['CICL_PROJECT_URL'],
                                       description: 'ci url (automatic detect with ci_changelog)',
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :config_path,
                                       env_name: 'QMOBILE_CONFIG_PATH',
                                       description: 'the path to qma confiuration file',
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :host_type,
                                       env_name: 'QMOBILE_HOST_TYPE',
                                       description: 'the host type to upload host domain',
                                       default_value: 'external',
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :api_version,
                                       env_name: 'QMOBILE_API_VERSION',
                                       description: 'the api version of qmobile',
                                       default_value: 'v2',
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :timeout,
                                       env_name: 'QMOBILE_TIMEOUT',
                                       description: 'the upload timeout of qmobile',
                                       default_value: 600,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :custom_data,
                                       env_name: 'QMOBILE_CUSTOM_DATA',
                                       description: 'custom data to build query params',
                                       optional: true)
        ]
      end

      def self.is_supported?(platform)
        [:ios, :android].include?(platform)
      end
    end
  end
end
