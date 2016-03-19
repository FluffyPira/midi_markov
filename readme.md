#MIDI Markov v0.2
Creates a corpus from midi files which is uses to create markov generated midi music!

##How to use
To store midi files in the corpus.

```
./generator.rb store "<midi>.mid"
```

To generate a midi file.
```
./generator.rb build "<midi>.mid" <tempo> <# of tracks>
```