require "service/shared_service_tests"
require "httparty"
require "uri"

if SERVICE_CONFIGURATIONS[:spaces]
  class ActiveStorage::Service::SpacesServiceTest < ActiveSupport::TestCase
    SERVICE = ActiveStorage::Service.configure(:spaces, SERVICE_CONFIGURATIONS)

    include ActiveStorage::Service::SharedServiceTests

    test "signed URL generation" do
      assert_match /digitaloceanspaces\.com.*response-content-disposition=inline.*avatar\.png/,
        @service.url(FIXTURE_KEY, expires_in: 5.minutes, disposition: :inline, filename: "avatar.png")
    end
  end
else
  puts "Skipping Spaces Service tests because no Spaces configuration was supplied"
end
