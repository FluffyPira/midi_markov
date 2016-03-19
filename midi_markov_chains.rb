#!/usr/bin/env ruby

class MidiMarkovMaker
  def initialize(file)
    
    @opened_file = File.read(file)
    
    @number = Hash.new
    numberlist = @opened_file.split
    numberlist.each_with_index do |number, index|
      add(number, numberlist[index + 1]) if index <= numberlist.size - 2
    end
  end

  def add(number, next_number)
    @number[number] = Hash.new(0) if !@number[number]
    @number[number][next_number] += 1
  end

  def generate()
    number = @opened_file.split.sample
    
    return "" if !@number[number]
    followers = @number[number]
    sum = followers.inject(0) {|sum,kv| sum += kv[1]}
    random = rand(sum)+1
    partial_sum = 0
    next_number = followers.find do |word, count|
      partial_sum += count
      partial_sum >= random
    end.first
    next_number
  end
  
  def create(notecount)
    notes = ""
    until notes.count(" ") == notecount
      number = generate()
      notes << number << " "
    end
    return notes
  end
end