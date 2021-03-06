require "test_helper"
require "database/setup"
require "active_storage/blob"

require "active_job"
ActiveJob::Base.queue_adapter = :test
ActiveJob::Base.logger = nil

# ActiveRecord::Base.logger = Logger.new(STDOUT)

class User < ActiveRecord::Base
  has_one_attached  :avatar
  has_many_attached :highlights
end

class ActiveStorage::AttachmentsTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup { @user = User.create!(name: "DHH") }

  teardown { ActiveStorage::Blob.all.each(&:purge) }

  test "attach existing blob" do
    @user.avatar.attach create_blob(filename: "funky.jpg")
    assert_equal "funky.jpg", @user.avatar.filename.to_s
  end

  test "attach existing sgid blob" do
    @user.avatar.attach create_blob(filename: "funky.jpg").to_sgid.to_s
    assert_equal "funky.jpg", @user.avatar.filename.to_s
  end

  test "attach new blob" do
    @user.avatar.attach io: StringIO.new("STUFF"), filename: "town.jpg", content_type: "image/jpg"
    assert_equal "town.jpg", @user.avatar.filename.to_s
  end

  test "purge attached blob" do
    @user.avatar.attach create_blob(filename: "funky.jpg")
    avatar_key = @user.avatar.key

    @user.avatar.purge
    assert_not @user.avatar.attached?
    assert_not ActiveStorage::Blob.service.exist?(avatar_key)
  end

  test "purge attached blob later when the record is destroyed" do
    @user.avatar.attach create_blob(filename: "funky.jpg")
    avatar_key = @user.avatar.key

    perform_enqueued_jobs do
      @user.destroy

      assert_nil ActiveStorage::Blob.find_by(key: avatar_key)
      assert_not ActiveStorage::Blob.service.exist?(avatar_key)
    end
  end


  test "attach existing blobs" do
    @user.highlights.attach create_blob(filename: "funky.jpg"), create_blob(filename: "wonky.jpg")

    assert_equal "funky.jpg", @user.highlights.first.filename.to_s
    assert_equal "wonky.jpg", @user.highlights.second.filename.to_s
  end

  test "attach new blobs" do
    @user.highlights.attach(
      { io: StringIO.new("STUFF"), filename: "town.jpg", content_type: "image/jpg" }, 
      { io: StringIO.new("IT"), filename: "country.jpg", content_type: "image/jpg" })

    assert_equal "town.jpg", @user.highlights.first.filename.to_s
    assert_equal "country.jpg", @user.highlights.second.filename.to_s
  end

  test "purge attached blobs" do
    @user.highlights.attach create_blob(filename: "funky.jpg"), create_blob(filename: "wonky.jpg")
    highlight_keys = @user.highlights.collect(&:key)
    
    @user.highlights.purge
    assert_not @user.highlights.attached?
    assert_not ActiveStorage::Blob.service.exist?(highlight_keys.first)
    assert_not ActiveStorage::Blob.service.exist?(highlight_keys.second)
  end

  test "purge attached blobs later when the record is destroyed" do
    @user.highlights.attach create_blob(filename: "funky.jpg"), create_blob(filename: "wonky.jpg")
    highlight_keys = @user.highlights.collect(&:key)

    perform_enqueued_jobs do
      @user.destroy

      assert_nil ActiveStorage::Blob.find_by(key: highlight_keys.first)
      assert_not ActiveStorage::Blob.service.exist?(highlight_keys.first)

      assert_nil ActiveStorage::Blob.find_by(key: highlight_keys.second)
      assert_not ActiveStorage::Blob.service.exist?(highlight_keys.second)
    end
  end
end
