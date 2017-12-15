# The Computer Language Benchmarks Game
# http://benchmarksgame.alioth.debian.org/
#
# Contributed by Aaron Tavistock
# Modified by Michael Leimstädtner

unless ''.respond_to?(:ord)
  class String
    def ord
      self[0].ord
    end
  end
end

unless ''.respond_to?(:clear)
  class String
    def clear
      self.replace('')
    end
  end
end

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
    @value = seed_value
    @output_buffer = ''
    generate_map_value_method(map)
    @output_file = output_file
  end

  def render(label)
    @output_file.puts ">#{label}"
    full_row_count, last_row_size = @size.divmod(60)
    while (full_row_count > 0)
      @output_file.puts output_row(60)
      full_row_count -= 1
    end
    @output_file.puts output_row(last_row_size) if last_row_size > 0
  end

  private

  def generate_map_value_method(map)
    accum_percentage = 0.0

    conditions = []
    map.each do |letter, percentage|
      accum_percentage += percentage
      conditions << %[(value <= #{accum_percentage} ? #{letter.ord} : ]
    end
    conditions[-1] = "#{map.last.first.ord}" # Substitute last condition for fixed value
    conditions << ')' * (map.size - 1)

    instance_eval %[def map_value(value); #{conditions.join}; end]
  end

  def next_item
    @value = (@value * GR_IA + GR_IC) % GR_IM
    @value / GR_IM
  end

  def output_row(size)
    @output_buffer.clear
    while (size > 0)
      @output_buffer << map_value(next_item)
      size -= 1
    end
    @output_buffer
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

def fasta(size, output_file)
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
  fasta(size.to_i, output_file)
  output_file.close
end.start