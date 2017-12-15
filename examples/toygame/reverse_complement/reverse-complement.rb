# Todo: There is a faster threaded version of this

# The Computer Language Benchmarks Game
# http://benchmarksgame.alioth.debian.org
#
# Contributed by Peter Bjarke Olsen
# Modified by Doug King
# Modified by Joseph LaFata
# Modified by Michael Leimstädtner

CODES =       'wsatugcyrkmbdhvnATUGCYRKMBDHVN'
COMPLEMENTS = 'WSTAACGRYMKVHDBNTAACGRYMKVHDBN'

def revcomp_segment(seq, output_file)
  seq.reverse!.tr!(CODES, COMPLEMENTS)
  stringlen=seq.length-1
  0.step(stringlen,60) {|x|
    output_file.print seq[x,60] , "\n"
  }
end

def revcomp(input_file, output_file)
  seq = ""
  lines = File.readlines(input_file)
  lines.each do |line|
    if line[0] == '>'
      unless seq.empty?
        revcomp_segment(seq, output_file)
        seq=""
      end
      output_file.puts line
    else
      line.chomp!
      seq << line
    end
  end
  revcomp_segment(seq, output_file) unless seq.empty?
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
  fasta_output_path = File.expand_path(File.dirname(__FILE__) + "/../fasta/#{size}_sequence.txt")
  reversed_fasta_path = File.expand_path(File.dirname(__FILE__) + "/#{size}_rev_sequence.txt")
  output_file = File.open(reversed_fasta_path, "w")
  revcomp(fasta_output_path, output_file)
  output_file.close
end.start