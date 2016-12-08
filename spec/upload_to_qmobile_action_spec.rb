describe Fastlane::Actions::UploadToQmobileAction do
  describe '#run' do
    # before do
    #   Fastlane::Actions::SharedValues::IPA_OUTPUT_PATH = ''
    #   Fastlane::Actions::SharedValues::GRADLE_APK_OUTPUT_PATH = ''
    # end

    it 'should throws an exception if not pass api_key' do
      expect do
        Fastlane::FastFile.new.parse('lane :test do
            upload_to_qmobile
          end').runner.execute(:test)
      end.to raise_error(FastlaneCore::Interface::FastlaneError, "No API key, please input again".red)
    end

    it 'should throws an exception if not pass app' do
      expect do
        Fastlane::FastFile.new.parse('lane :test do
            upload_to_qmobile(api_key: "fill-api-key")
          end').runner.execute(:test)
      end.to raise_error(FastlaneCore::Interface::FastlaneError, "You have to either pass an ipa or an apk file")
    end
  end
end
