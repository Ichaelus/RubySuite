# The Computer Language Benchmarks Game
# http://benchmarksgame.alioth.debian.org
#
# contributed by Jesse Millikan
# Modified by Wesley Moxam
# Modified by Scott Leggett
# Modified by Michael Leimstädtner
def binarytrees(size)

  max_depth = size.to_i
  min_depth = 4

  max_depth = [min_depth + 2, max_depth].max

  stretch_depth = max_depth + 1
  stretch_tree = bottom_up_tree(stretch_depth)

  puts "stretch tree of depth #{stretch_depth}\t check: #{item_check(*stretch_tree)}"

  long_lived_tree = bottom_up_tree(max_depth)

  min_depth.step(max_depth, 2) do |depth|
    iterations = 2**(max_depth - depth + min_depth)

    check = 0

    (1..iterations).each do |i|
      check += item_check(*bottom_up_tree(depth))
    end

    puts "#{iterations}\t trees of depth #{depth}\t check: #{check}"
  end

  puts "long lived tree of depth #{max_depth}\t check: #{item_check(*long_lived_tree)}"
end

def item_check(left, right)
    if left
        1 + item_check(*left) + item_check(*right)
    else
        1
    end
end

def bottom_up_tree(depth)
    if depth > 0
        depth -= 1
        [bottom_up_tree(depth), bottom_up_tree(depth)]
    else
        [nil, nil]
    end
end

# TODO: There is a YARV version that spawns processes -> Make it work.

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
  binarytrees(size)
end.start