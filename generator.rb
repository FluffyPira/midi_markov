#!/usr/bin/env ruby

require 'midilib/sequence'
require 'midilib/io/seqreader'
require 'midilib/io/seqwriter'
require 'midilib/sequence'
require 'midilib/consts'
require 'marky_markov'
include MIDI

SEQUENCE = MIDI::Sequence.new()
@command = ARGV[0]
@midi_file = ARGV[1]
@tempo = ARGV[2].to_i
@tracks = ARGV[3].to_i

# Here's where we make our corpus of songs. It stores the midi number of the note (+64 because that's how this library works?)
if ARGV[0].include?('store')
  
  tracks = []
  
  # I forget why this needs to exist. I used to use it for debugging to see the number of tracks nad what tracks are def loaded
  # Still used for opening the file though!

  File.open(@midi_file, 'r') do |file|
    SEQUENCE.read(file) do |num_tracks, i|
      tracks << i
    end
  end
  
  # Empty array for posterity.
  # FUTURE GENERATIONS MUST KNOW!!
  notes = []

  # Store note information
  SEQUENCE.each do |track|
    track.each do |event|
      if event.kind_of?(MIDI::NoteEvent)
        🎵 = Struct.new(:channel, :value, :length)
        🎵.new(event.channel, event.note, event.delta_time)
        notes << 🎵.new(event.channel, event.note, event.delta_time)
      end
    end
  end

  # Get only the active channel nunbers
  channels = notes.map(&:channel).uniq

  # For each one, store their note and length into separate corpus files.
  # Could be one but I suck dicks at programming.
  channels.each do |channels|
    🎶 = notes.select { |x| x.channel == channels }.map(&:value)
    corpus_notes = 🎶.map(&:inspect).join(' ')

    open('note_corpus.txt', 'a') { |f|
      f.puts corpus_notes
    }
    
    ⏰ = notes.select { |x| x.channel == channels }.map(&:length)
    corpus_length= ⏰.map(&:inspect).join(' ')
    
    open('length_corpus.txt', 'a') { |f|
      f.puts corpus_length
    }
  end

# Here is where we make music. Mostly lifted from the example that came with the library and heavily edited to do silly things.
# This is a silly thing.  
elsif ARGV[0].include?('build')
  
  # Round notes to only allow lengths we can deal with. 
  # Not as free as it was before but makes a lot more sense and sounds better.
  def rounded_note_length(delta, length)
    return length if delta.include?(length)

    # This is the bit that rounds the note. 
    # Given a set of 2 note lengths in sequence, we know the lowest note can only ever be 0.5 the highest def note
    # Thus, dead centre between the two is 0.75. Less, we round down. Higher we round up.
    
    delta.each_cons(2) do |x, y|
      if length >= x && length <= y
        if length / y < 0.7499
          return x
        else
          return y
        end
      end
    end
  end

  # How we figure out the length of a note. May be different based on temp but not sure. This library is silly.
  def delta(length)
    value = SEQUENCE.note_to_delta(length)
    return value
  end
  
  # Make our dictionaries, and parse our corpus.
  note_markov = MarkyMarkov::Dictionary.new('note_corpus', 4)
  note_markov.parse_file "note_corpus.txt"
  length_markov = MarkyMarkov::Dictionary.new('length_corpus', 4)
  length_markov.parse_file "length_corpus.txt"
  
  # Initialize the midi file and name our song.
  track = Track.new(SEQUENCE)
  SEQUENCE.tracks << track
  
  # If you don't specify tempo this sets it. It's probably wrong, I added this while doing comments.
  if @tempo < 0
    @tempo = 120
  end
  
  track.events << Tempo.new(Tempo.bpm_to_mpq(@tempo))
  track.events << MetaEvent.new(META_SEQ_NAME, 'Ghost Dad')
  
  # If you don't specify how many tracks you want, it sets it to 1. PROBABLY NEED A NIL CASE HERE LIZ!
  if @tracks < 1
    @tracks = 1
  end
  
  # Reasons™
  track_number = 0
  
  # Here we build our array of possible note lengths.
  # No idea how small we can get here.
  delta_array = [delta("eighth"), delta("quarter"), delta("half"), delta("whole")]
  
  # Here's where we actually make music.
  @tracks.times do
    track_number += 1
    
    # TO DO LATER: Better way of selecting how many notes there will be.
    notes = note_markov.generate_n_words rand(50..70)
    
    track = Track.new(SEQUENCE)
    SEQUENCE.tracks << track

    track.name = "Machine Track #{track_number}"
    
    # I wish this worked.
    inst = rand(0..127)
    track.instrument = GM_PATCH_NAMES[inst]

    track.events << Controller.new(0, CC_VOLUME, 127)

    track.events << ProgramChange.new(0, 1, 0)
    
    # Turn our notes into an array of itegers from a string.
    notes2 = notes.split(" ").map(&:to_i)
    
    notes2.each do |note|
      # Generate us some note lengths!
      length = length_markov.generate_n_words 3
      # Eliminate garbage, although this is kinda redundant now.
      length2 = length.split(" ").map(&:to_i).delete_if { |a| a < delta("eighth") }.delete_if { |a| a > delta("whole") }
      
      if length2.empty?
        length2 = delta_array
      end
      
      # Get ourselves a rounded length.
      length = rounded_note_length(delta_array, length2.sample)
      
      # Channel, Note, Velocity, Delta? 
      track.events << NoteOn.new(0, note, 127, 0)
      track.events << NoteOff.new(0, note, 127, length)
    end
  end
  
  File.open(@midi_file, 'wb') { |f| SEQUENCE.write(f) }
else 
  # TO DO. Better command names.
  puts "Use a valid command such as 'store' or 'build' "
end