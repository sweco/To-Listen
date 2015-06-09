require 'test_helper'
require 'rspotify'

class PlaylistHelperTest < ActionView::TestCase
  include PlaylistHelper

  def setup
    RSpotify::authenticate(ENV['spotify_client_id'], ENV['spotify_client_secret'])
    @user = SpotifyLastFmUser.new(spotify_user: spotify_users(:andy))
    @user_track = @user.tracks.first

    solo_artist_tracks = @user.tracks.select { |t| t.object.artists.count == 1 }
    raise 'Unable to find track with only one artist' if solo_artist_tracks.empty?
    solo_artist_tracks.each do |sat|
      albums = sat.object.artists.first.albums
      albums.each do |a|
        tracks = a.tracks
        tracks.each do |t|
          if @track_with_all_artists.nil? && t.artists.count == 1 && @user.tracks.find_index { |t2| t2.object.name == t.name }.nil?
            @track_with_all_artists = Track.new(object: t, added_at: nil)
          end
          if @track_with_one_artist.nil? && t.artists.count > 1 && @user.tracks.find_index { |t2| t2.object.name == t.name && t2.object.artists.collect { |art| art.name } == t.artists.collect { |art| art.name } }.nil?
            @track_with_one_artist = Track.new(object: t, added_at: nil)
          end
          break unless @track_with_all_artists.nil? || @track_with_one_artist.nil?
        end
        break unless @track_with_all_artists.nil? || @track_with_one_artist.nil?
      end
      break unless @track_with_all_artists.nil? || @track_with_one_artist.nil?
    end

    @random_song = Track.new(object: RSpotify::Track.find('6AJlcxjEO2baFC24GPsJjg'), added_at: nil) # Bonnie Tyler - Holding Out for a Hero
  end

  test 'should return 1 as relationship between user and his song' do
    value = @user.send(:relationship, @user_track)
    assert value == 1, 'Expected 1 but found ' + value.to_s
  end

  test 'should return 0.67 as relationship between user and song sang by his artist' do
    value = @user.send(:relationship, @track_with_all_artists)
    assert value == 0.67, 'Expected 0.67 but found ' + value.to_s
  end

  test 'should return 0.33 as relationship between user and song where his artist is involved' do
    value = @user.send(:relationship, @track_with_one_artist)
    assert value == 0.33, 'Expected 0.33 but found ' + value.to_s
  end

  test 'should return 0 as relationship between user and song not within his songs and sang by artists not within his artists' do
    value = @user.send(:relationship, @random_song)
    assert value == 0, 'Expected 0 but found ' + value.to_s
  end
end