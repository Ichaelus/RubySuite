# The Computer Language Benchmarks Game
# http://benchmarksgame.alioth.debian.org
#
# contributed by jose fco. gonzalez
# optimized & parallelized by Rick Branson
# optimized for ruby2 by Aaron Tavistock

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

def regexdna(input_file)
  seq = File.read(input_file).force_encoding("ASCII-8BIT")

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
    'B' => '(c|g|t)',
    'D' => '(a|g|t)',
    'H' => '(a|c|t)',
    'K' => '(g|t)',
    'M' => '(a|c)',
    'N' => '(a|c|g|t)',
    'R' => '(a|g)',
    'S' => '(c|t)',
    'V' => '(a|c|g)',
    'W' => '(a|t)',
    'Y' => '(c|t)'
  }.each { |f,r| seq.gsub!(f,r) }

  puts "#{match_results.join("\n")}\n\n#{ilen}\n#{clen}\n#{seq.length}"
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

TCompare::Worker.n_iterations_measured do
  regexdna(File.expand_path(File.dirname(__FILE__) + '/input.txt'))
end.start