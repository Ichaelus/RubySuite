# The Computer Language Benchmarks Game
# http://benchmarksgame.alioth.debian.org/

#   contributed by Michael Barker
#   based on a Java contribution by Luzius Meisser
#   converted to C by dualamd
#   converted to Ruby by Eugene Pimenov
#   modified by Michael Leimstädtner

require 'thread'

COLORS     = [:blue, :red, :yellow, :invalid].freeze
COMPLEMENT = {
  :blue => {:blue => :blue, :red => :yellow, :yellow => :red}.freeze,
  :red => {:blue => :yellow, :red => :red, :yellow => :blue}.freeze,
  :yellow => {:blue => :red, :red => :blue, :yellow => :yellow}.freeze
}.freeze

$creature_id = 0

NUMBERS = %w{zero one two three four five six seven eight nine}.freeze

def chameneosredux(size)
  print_colors_table
  run_game size, [:blue, :red, :yellow]
  run_game size, [:blue, :red, :yellow, :red, :yellow, :blue, :red, :yellow, :red, :blue]
end

# convert integer to number string: 1234 -> "one two three four"
def format_number(num)
  out = []
  begin
    out << NUMBERS[num%10]
    num /= 10
  end while num > 0
  out.reverse.join(" ")
end

class MeetingPlace
  attr_reader :mutex
  attr_accessor :meetings_left, :first_creature

  def initialize(meetings)
    @mutex = Mutex.new
    @meetings_left = meetings
  end
end

class Creature
  attr_accessor :place, :thread, :count, :same_count, :color, :id, :two_met, :sameid

  def initialize(place, color)
    @place = place
    @count = @same_count = 0

    @id = ($creature_id += 1)
    @color = color
    @two_met = FALSE

    @thread = Thread.new do
      loop do
        if meet
          Thread.pass while @two_met == false

          @same_count += 1 if @sameid
          @count += 1
        else
          break
        end
      end
    end
  end

  def meet
    @place.mutex.lock

    if @place.meetings_left > 0
      if @place.first_creature
        first = @place.first_creature
        new_color = COMPLEMENT[@color][first.color]

        @sameid  = first.sameid  = @id == first.id
        @color   = first.color   = new_color
        @two_met = first.two_met = true

        @place.first_creature = nil
        @place.meetings_left -= 1
      else
        @two_met = false
        @place.first_creature = self
      end
      true
    else
      false
    end
  ensure
    @place.mutex.unlock
  end

  def result
    '' << @count.to_s << ' ' << format_number(@same_count)
  end
end

def run_game(n_meeting, colors)
  place = MeetingPlace.new(n_meeting)

  creatures = []
  colors.each do |color|
    print color, " "
    creatures << Creature.new(place, color)
  end

  # wait for them to meet
  creatures.each { |c| c.thread.join}

  total = 0
  #print meeting times of each creature
  creatures.each do |c|
    puts c.result
    total += c.count
  end

  # print total meeting times, should be equal n_meeting
  print ' ', format_number(total), "\n\n"
end

def print_colors_table
  [:blue, :red, :yellow].each do |c1|
    [:blue, :red, :yellow].each do |c2|
      puts "#{c1} + #{c2} -> #{COMPLEMENT[c1][c2]}"
    end
  end
end


# Todo This is the jruby version. Find a proper ruby version
# Also, puts and print commands have been commented out

unless Kernel.respond_to?(:require_relative)
  module Kernel
    def require_relative(path)
      require File.join(File.dirname(caller[0]), path.to_str)
    end
  end
end

WORKER_PATH = "../../../app/t_compare/worker"
require_relative WORKER_PATH

TCompare::Worker.parametrized_iteration_measured do |size|
  chameneosredux(size.to_i)
end.start