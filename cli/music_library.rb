require 'rspec'

class MusicLibrary
  attr_accessor :input, :albums

  Album = Struct.new(:title, :artist, :played)

  def initialize
    @input  = nil
    @albums = []
  end

  def execute!
    puts "Welcome to your music collection!"
    puts "Type HELP for helpful instructions, or start adding music if you know what to do."
    prompt_user
  end

  def prompt_user
    @input = gets.chomp
    parse_user_input
  end

  def display_help_options
    help = []
    help << "You can add albums (type: add \"$ALBUM_TITLE\" \"$ARTIST\")"
    help << "You can play some music (type: play \"$ALBUM_TITLE\")"
    help << "You can find which tunes you haven't heard yet (type: show unplayed OR show unplayed by \"$ARTIST\"])"
    help << "And you can look at your whole collection, too (type: show all OR show all by \"$ARTIST\"])"
    puts help
  end

  def parse_album_info
    @input.scan(/"([^"]*)"/).flatten
  end

  def parse_user_input
    title, artist = parse_album_info

    case @input.split(' ')[0]
    when "add"
      add_album(title, artist)
      prompt_user
    when "play"
      play_album(title, artist)
      prompt_user

    when 'show'
      artist = @input.include?('by') ? parse_album_info.first : nil
      display_albums(artist: artist, show_unplayed_only: @input.include?('unplayed'))
      prompt_user

    when /(q|Q|quit|Quit)/
      puts "Are you sure you want to leave? Type y/n"
      response = gets.chomp
      if response == 'y'
        puts "Okay! Bye!"
        exit
      else
        puts "Glad you're sticking around. Add some more music or play something!"
        prompt_user
      end

    when "HELP"
      display_help_options
      prompt_user

    else
      puts "I'm sorry, I didn't understand your request. Type HELP for available options!"
      prompt_user
    end
  end

  def find_albums(title, artist)
    @albums.select do |album|
      (
        album.title == title ||
        album.artist == artist
      ) && album
    end
  end

  def display_albums(artist: nil, show_unplayed_only: false)
    # default to all albums
    albums = @albums

    # filter by artist
    albums = find_albums(nil, artist) if artist

    # filter by play-state
    if show_unplayed_only
      unplayed = proc { |a| !a.played && a }
      albums = albums.select(&unplayed)
    end

    # parse album information for legibility
    albums = albums.map do |album|
      if show_unplayed_only == true
        played_state = ''
      else
        played_state = album.played == true ? ' (played)' : ' (unplayed)'
      end
      "\"#{album.title.capitalize}\" by #{album.artist.capitalize}#{played_state}"
    end

    # make sure we have something to show
    if albums.empty?
      puts "I'm sorry, you don't have any albums to show. Add some!"
    else
      puts albums
    end
  end

  def play_album(title, artist)
    if @albums.empty?
      puts "I'm sorry, you don't have any albums to play. Add some!"
      prompt_user
    end
    # validate album exists for this music library
    album = find_albums(title, artist).first

    if album
      # set play state
      album.played = true
      puts "You're listening to \"#{title}\""
    else
      puts "Could not find \"#{title}\". Try adding it now!"
    end
  end

  def add_album(title, artist)
    album = Album.new(title, artist, false)
    if @albums.include?(album)
      puts "Already Added"
    else
      puts "Added \"#{title.capitalize}\" by #{artist.capitalize}"
      @albums << album
    end
  end
end

# TESTS
describe 'adding music to my Musical Library' do
  let(:title) { 'Graceland' }
  let(:artist) { 'Paul Simon' }

  it "adds new music to my library" do
    music_library = MusicLibrary.new

    music_library.add_album(title, artist)
    expect(music_library.albums.length).to eq 1
    expect(music_library.albums.select do |album|
      album.title == title && album.artist == artist
    end.length).to eq 1
  end

  it "does not add duplicate albums to my library" do
    music_library = MusicLibrary.new

    music_library.add_album(title, artist)
    expect(music_library.albums.length).to eq 1

    music_library.add_album(title, artist)
    expect(music_library.albums.length).to eq 1
  end
end

describe 'playing music from my Musical Library' do
  let(:music_library) { MusicLibrary.new }
  before do
    music = {
      "Ride the Lightning": "Metallica",
      "Licensed to Ill": "Beastie Boys",
      "Pauls Boutique": "Beastie Boys",
      "The Dark Side of the Moon": "Pink Floyd"
    }
    music.each do |title, artist|
      music_library.add_album(title, artist)
    end
  end

  it "plays music from library found by album title" do
    first_album = music_library.albums.first
    title, artist = first_album.title, first_album.artist

    # NOTE ruby puts adds a new line, so to match exactly we must add that here
    expected_output = "You're listening to \"#{title}\"\n"
    expect do
      music_library.play_album(title, artist)
    end.to output(expected_output).to_stdout
  end

  it "does not play music from my library if it doesn't exist" do
    fake_album = MusicLibrary::Album.new('Really Good Album', 'Justin Bieber', false)
    title, artist = fake_album.title, fake_album.artist
    expected_output = "Could not find \"#{title}\". Try adding it now!\n"

    expect do
      music_library.play_album(title, artist)
    end.to output(expected_output).to_stdout

    expect(music_library.albums.select do |album|
      album.title == title && fake_album
    end.length).to eq 0
  end
end

describe 'searching through my Musical Library' do
  let(:music_library) { MusicLibrary.new }
  before do
    music = {
      "Ride the Lightning": "Metallica",
      "Licensed to Ill": "Beastie Boys",
      "Pauls Boutique": "Beastie Boys",
      "The Dark Side of the Moon": "Pink Floyd"
    }
    music.each do |title, artist|
      music_library.add_album(title, artist)
    end
  end
  it "displays my whole album collection" do
    full_collection = music_library.albums
    expect do
      music_library.display_albums
    end.to output(puts full_collection).to_stdout
  end

  it "displays my whole album collection filtered by artist" do
    first_artist = music_library.albums.first.artist
    # we only have one Metallica album, sad, I know
    expect do
      music_library.display_albums(artist: first_artist)
    end.to output(puts music_library.albums.first).to_stdout
  end

  it "displays my unplayed album collection" do
    full_collection = music_library.albums
    expect do
      music_library.display_albums(show_unplayed_only: true)
    end.to output(puts full_collection).to_stdout

    first_album = music_library.albums.first
    music_library.play_album(first_album.title, first_album.artist)

    expect do
      music_library.display_albums(show_unplayed_only: true)
    end.to output(puts full_collection - [first_album]).to_stdout
  end

  it "displays my unplayed album collection filtered by artist" do
    full_collection = music_library.albums
    first_album = music_library.albums.first
    play_album_params = { artist: first_album.artist, show_unplayed_only: true }

    expect do
      music_library.display_albums(play_album_params)
    end.to output(puts first_album).to_stdout

    music_library.play_album(first_album.title, first_album.artist)

    expect do
      music_library.display_albums(play_album_params)
    end.to output("I'm sorry, you don't have any albums to show. Add some!\n").to_stdout
  end

  it "handles display requests when my collection is empty" do
    music_library.albums = []
    expect do
      music_library.display_albums()
    end.to output("I'm sorry, you don't have any albums to show. Add some!\n").to_stdout
  end

  it "handles display requests when artist does not exist" do
    fake_album = MusicLibrary::Album.new('Really Good Album', 'Justin Bieber', false)
    title, artist = fake_album.title, fake_album.artist

    expect do
      music_library.display_albums(artist: artist)
    end.to output("I'm sorry, you don't have any albums to show. Add some!\n").to_stdout
  end
end
