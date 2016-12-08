module Fastlane
  module Helper
    class UploadToQmobileHelper
      def self.new_upload(json)
        url = app_url(json[:entry])
        shared_url(url)

        UI.success 'Successful uploaded file'
        UI.success url
      end

      def self.found_exist(json)
        url = app_url(json[:entry], true)
        shared_url(url)

        UI.important 'This version had been uploaded.'
        UI.important url
      end

      def self.fail_valid(json)
        if json.empty?
          UI.user_error! 'Unkonwn error!'
        else
          errors = ["[ERROR] #{json[:message]}"]
          json[:entry].each_with_index do |(key, items), i|
            errors.push "#{i + 1}. #{key}"
            items.each do |item|
              errors.push "- #{item}"
            end
          end

          UI.user_error! errors.join("\n")
        end
      end

      def self.app_url(json, version = false)
        host = json['host']['external']
        slug = json['app']['slug']
        paths = [host, 'apps', slug]
        paths.push(json['version'].to_s) if version

        paths.join('/')
      end

      def self.shared_url(url)
        Actions.lane_context[Actions::SharedValues::QMOBILE_PUBLISH_URL] = url
        ENV[Actions::SharedValues::QMOBILE_PUBLISH_URL.to_s] = url
      end

      def self.jenkins?
        %w(JENKINS_URL JENKINS_HOME).each do |current|
          return true if ENV.key?(current)
        end

        return false
      end

      def self.gitlab?
        ENV.key?('GITLAB_CI')
      end

      def self.travis?
        ENV.key?('TRAVIS')
      end
    end
  end
end
