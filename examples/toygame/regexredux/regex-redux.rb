# The Computer Language Benchmarks Game
# http://benchmarksgame.alioth.debian.org
#
# regex-dna program contributed by jose fco. gonzalez
# optimized & parallelized by Rick Branson
# optimized for ruby2 by Aaron Tavistock
# converted from regex-dna program
# Modified by Michael Leimstädtner
MATCHERS = [
  /agggtaaa|tttaccct/,
  /[cgt]gggtaaa|tttaccc[acg]/,
  /a[act]ggtaaa|tttacc[agt]t/,
  /ag[act]gtaaa|tttac[agt]ct/,
  /agg[act]taaa|ttta[agt]cct/,
  /aggg[acg]aaa|ttt[cgt]ccct/,
  /agggt[cgt]aa|tt[acg]accct/,
  /agggta[cgt]a|t[acg]taccct/,
  /agggtaa[cgt]|[acg]ttaccct/
]


def regexredux(input_path, output_file)
  seq = File.readlines(input_path).join
  ilen = seq.size

  seq.gsub!(/>.*\n|\n/,"")
  clen = seq.length


  threads = MATCHERS.map do |f|
    Thread.new do
      Thread.current[:result] = "#{f.source} #{seq.scan(f).size}"
    end
  end

  threads.each do |t|
    t.join
  end

  match_results = threads.map do |t|
    t[:result]
  end

  {
    /tHa[Nt]/ => '<4>',
    /aND|caN|Ha[DS]|WaS/ => '<3>',
    /a[NSt]|BY/ => '<2>',
    /<[^>]*>/ => '|',
    /\|[^|][^|]*\|/ => '-'
  }.each { |f,r| seq.gsub!(f,r) }

  output_file.puts "#{match_results.join("\n")}\n\n#{ilen}\n#{clen}\n#{seq.length}"
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

def run(size)
  fasta_output_path = File.expand_path(File.dirname(__FILE__) + "/../fasta/#{size}_sequence.txt")
  output_path = File.expand_path(File.dirname(__FILE__) + "/#{size}_replaced_sequence.txt")
  output_file = File.open(output_path, "w")
  regexredux(fasta_output_path, output_file)
  output_file.close
end

TCompare::Worker.parametrized_iteration_measured do |size|
  run(size)
end.start