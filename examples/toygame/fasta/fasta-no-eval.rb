# The Computer Language Benchmarks Game
# http://benchmarksgame.alioth.debian.org/
# Contributed by Sokolov Yura
# Modified by Joseph LaFata
# Modified by Michael Leimstädtner

ALU = 'GGCCGGGCGCGGTGGCTCACGCCTGTAATCCCAGCACTTTGGGAGGCCGAGGCGGGCGGATCACCTGAGGTCAGGAGTTCGAGACCAGCCTGGCCAACATGGTGAAACCCCGTCTCTACTAAAAATACAAAAATTAGCCGGGCGTGGTGGCGCGCGCCTGTAATCCCAGCTACTCGGGAGGCTGAGGCAGGAGAATCGCTTGAACCCGGGAGGCGGAGGTTGCAGTGAGCCGAGATCGCGCCACTGCACTCCAGCCTGGGCGACAGAGCGAGACTCCGTCTCAAAAA'

IUB = [
  ['a', 0.27],
  ['c', 0.12],
  ['g', 0.12],
  ['t', 0.27],
  ['B', 0.02],
  ['D', 0.02],
  ['H', 0.02],
  ['K', 0.02],
  ['M', 0.02],
  ['N', 0.02],
  ['R', 0.02],
  ['S', 0.02],
  ['V', 0.02],
  ['W', 0.02],
  ['Y', 0.02],
]

HOMOSAPIENS = [
  ['a', 0.3029549426680],
  ['c', 0.1979883004921],
  ['g', 0.1975473066391],
  ['t', 0.3015094502008],
]

class RandomSequence

  GR_IM = 139968.0
  GR_IA = 3877.0
  GR_IC = 29573.0

  attr_reader :value

  def initialize(seed_value, map, size, output_file)
    @size = size
    @map = map
    @output_buffer = ''
    @output_file = output_file
    @value = seed_value
  end

  def render(label)
    @output_file.puts ">#{label}"

    total_probability = 0.0
    @map.each{|acid_prob_pair|
      acid_prob_pair[1]= (total_probability += acid_prob_pair[1])
    }
    @size.times do
      rand = next_item
      @map.each do |acid_prob_pair|
        if acid_prob_pair[1] > rand
          @output_buffer << acid_prob_pair[0]
          break
        end
      end
    end
    0.step(@output_buffer.length-1,60) { |row|
      @output_file.puts @output_buffer[row,60]
    }
  end

  private

  def next_item
    @value = (@value * GR_IA + GR_IC) % GR_IM
    @value / GR_IM
  end

end

class RepeatSequence

  def initialize(seed_sequence, size, output_file)
    repeats = (size / seed_sequence.size).to_i + 1
    seq = seed_sequence * repeats
    @sequence = seq[0,size]
    @output_file = output_file
  end

  def render(label)
    @output_file.puts ">#{label}"
    seq_size = @sequence.size - 1
    0.step(seq_size, 60) do |x|
      @output_file.puts @sequence[x, 60]
    end
  end

end

def fasta_no_eval(size, output_file)
  one = RepeatSequence.new(ALU, size*2, output_file)
  one.render('ONE Homo sapiens alu')

  two = RandomSequence.new(42, IUB, size*3, output_file)
  two.render('TWO IUB ambiguity codes')

  three = RandomSequence.new(two.value, HOMOSAPIENS, size*5, output_file)
  three.render('THREE Homo sapiens frequency')
end

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
  output_path = File.expand_path(File.dirname(__FILE__) + "/#{size}_sequence.txt")
  output_file = File.open(output_path, "w")
  fasta_no_eval(size.to_i, output_file)
  output_file.close
end.start
