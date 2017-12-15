#  The Computer Language Benchmarks Game
#  http://benchmarksgame.alioth.debian.org/
#
#  contributed by Karl von Laudermann
#  modified by Jeremy Echols
#  modified by Detlef Reichl
#  modified by Joseph LaFata
#  modified by Peter Zotov
#  modified by Michael Leimstädtner
ITERATIONS = 50
ESCAPE_THRESHOLD = 4.0
class PixelIteration

  def initialize(x, y, size)
    @y_offset = (2.0*y/size)-1.0
    @x_offset = (2.0*x/size)-1.5
    @a_squared = @a = 0.0
    @b_squared = @b = 0.0
    @escaped = false
  end

  def try_to_escape
    @a, @b = iterate
    @a_squared, @b_squared = @a * @a, @b * @b
    @escaped = @a_squared + @b_squared > ESCAPE_THRESHOLD
  end

  def iterate
    f_real = @a_squared - @b_squared + @x_offset
    f_imag = 2.0 * @a * @b + @y_offset
    [f_real, f_imag]
  end

  def escape_bit
    @escaped ? 0b0 : 0b1 # White or Black
  end
end

def mandelbrot(size, output_file)
  output = File.open(output_file, "w")
  output.puts "P4\n#{size} #{size}"

  byte_acc = 0
  bit_num = 0
  # Explanation of all this madness:
  # http://xahlee.info/cmaci/fractal/mandelbrot.html
  size.times do |y_pixel|
    size.times do |x_pixel|
      mandelbrot = PixelIteration.new(x_pixel, y_pixel, size)

      ITERATIONS.times do
        break if mandelbrot.try_to_escape
      end

      byte_acc = (byte_acc << 1) | mandelbrot.escape_bit
      bit_num += 1

      # Code is very similar for these cases, but using separate blocks
      # ensures we skip the shifting when it's unnecessary, which is most cases.
      if bit_num == 8
        output.print byte_acc.chr
        byte_acc = 0
        bit_num = 0
      elsif x_pixel == size - 1
        byte_acc <<= (8 - bit_num)
        output.print byte_acc.chr
        byte_acc = 0
        bit_num = 0
      end
    end
  end
  output.close
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
  output_file = File.expand_path(File.dirname(__FILE__) + '/output.bmp')
  mandelbrot(size, output_file)
end.start