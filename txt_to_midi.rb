
require 'midilib'

seq = MIDI::Sequence.new()

track = MIDI::Track.new(seq)
seq.tracks << track

track.events << MIDI::Tempo.new(MIDI::Tempo.bpm_to_mpq(150))
track.events << MIDI::MetaEvent.new(MIDI::META_SEQ_NAME, 'lol')

class Writer
  def initialize(track)
    @track = track
    @last = 0
    @note_on = { }
    @last_on = { }
  end
  def write(time, is_on, note)
    if is_on && @note_on[note]
      # $stderr.puts "Note #{note} already on!"
      write(time, false, note)
    elsif !is_on && !@note_on[note]
      # $stderr.puts "Note #{note} already off!"
      return
    end
    delta = time - @last
    @last = time
    @note_on[note] = is_on
    @last_on[note] = time if is_on
    @track.events << (is_on ? MIDI::NoteOn : MIDI::NoteOff).new(0, note, 64, delta)
  end
end

data = ((ARGV[1] || '') + File.read(ARGV[0])).scan(/[\+\-]\d[a-gA-G]|\n/)
current_time = 0
quarter_note_length = seq.note_to_delta('quarter')
timestep_length = quarter_note_length / 12
current_time = 0
writer = Writer.new(track)
data.each do |item|
  if item == "\n"
    current_time += timestep_length
  elsif item.length == 3
    is_on = item[0] == '+'
    octave = item[1].to_i
    pitch = 'cCdDefFgGaAb'.index(item[2])
    note = (octave + 1) * 12 + pitch
    writer.write(current_time, is_on, note)
  end
end

File.open('output.mid', 'wb') { |file| seq.write(file) }
