# frozen_string_literal: true

require 'rails_helper'

describe UserCardSerializer do
  fab!(:follower) { Fabricate(:user) }
  fab!(:followed) { Fabricate(:user) }

  before do
    ::Follow::Updater.new(follower, followed).watch_follow
  end

  def get_serializer(user, current_user:)
    UserCardSerializer.new(user, scope: Guardian.new(current_user), root: false).as_json
  end

  context "when no settings are restrictive" do
    before do
      SiteSetting.discourse_follow_enabled = true
      SiteSetting.follow_show_statistics_on_profile = true
      SiteSetting.follow_followers_visible = FollowPagesVisibility::EVERYONE
      SiteSetting.follow_following_visible = FollowPagesVisibility::EVERYONE
    end

    it 'is_followed field is included' do
      expect(get_serializer(followed, current_user: follower)[:is_followed]).to eq(true)
    end

    it 'total_followers field is included' do
      expect(get_serializer(followed, current_user: nil)[:total_followers]).to eq(1)
    end

    it 'total_following field is included' do
      expect(get_serializer(follower, current_user: nil)[:total_following]).to eq(1)
    end
  end

  context "when discourse_follow_enabled setting is off" do
    before do
      SiteSetting.discourse_follow_enabled = false
    end

    it 'is_followed field is not included' do
      expect(get_serializer(followed, current_user: follower)).not_to include(:is_followed)
    end

    it 'total_followers field is not included' do
      expect(get_serializer(followed, current_user: followed)).not_to include(:total_followers)
    end

    it 'total_following field is not included' do
      expect(get_serializer(follower, current_user: follower)).not_to include(:total_following)
    end
  end

  context "when follow_show_statistics_on_profile setting is off" do
    before do
      SiteSetting.follow_show_statistics_on_profile = false
    end

    it 'is_followed field is included' do
      expect(get_serializer(followed, current_user: follower)[:is_followed]).to eq(true)
    end

    it 'total_followers field is not included' do
      expect(get_serializer(followed, current_user: followed)).not_to include(:total_followers)
    end

    it 'total_following field is not included' do
      expect(get_serializer(follower, current_user: follower)).not_to include(:total_following)
    end
  end

  context 'when follow_followers_visible does not allow anyone' do
    before do
      SiteSetting.follow_followers_visible = FollowPagesVisibility::NO_ONE
    end

    it 'total_followers field is not included' do
      expect(get_serializer(followed, current_user: followed)).not_to include(:total_followers)
    end

    it 'total_following field is included' do
      expect(get_serializer(follower, current_user: follower)[:total_following]).to eq(1)
    end
  end

  context 'when follow_following_visible does not allow anyone' do
    before do
      SiteSetting.follow_following_visible = FollowPagesVisibility::NO_ONE
    end

    it 'total_followers field is included' do
      expect(get_serializer(followed, current_user: followed)[:total_followers]).to eq(1)
    end

    it 'total_following field is not included' do
      expect(get_serializer(follower, current_user: follower)).not_to include(:total_following)
    end
  end

  context "when there is no current user" do
    it "is_followed is not included" do
      expect(get_serializer(followed, current_user: nil)).not_to include(:is_followed)
    end
  end

  context "when there is current user" do
    it "is_followed is true if current user is following the user" do
      expect(get_serializer(followed, current_user: follower)[:is_followed]).to eq(true)
    end

    it "is_followed is false if current user is not following the user" do
      expect(get_serializer(followed, current_user: Fabricate(:user))[:is_followed]).to eq(false)
    end
  end
end
