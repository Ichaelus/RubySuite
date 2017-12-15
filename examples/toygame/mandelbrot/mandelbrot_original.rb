#  The Computer Language Benchmarks Game
#  http://benchmarksgame.alioth.debian.org/
#
#  contributed by Karl von Laudermann
#  modified by Jeremy Echols
#  modified by Detlef Reichl
#  modified by Joseph LaFata
#  modified by Peter Zotov

def mandelbrot(size, output_file)
  output = File.open(output_file, "w")

  output.puts "P4\n#{size} #{size}"

  byte_acc = 0
  bit_num = 0

  y = 0
  while y < size
    ci = (2.0*y/size)-1.0

    x = 0
    while x < size
      zrzr = zr = 0.0
      zizi = zi = 0.0
      cr = (2.0*x/size)-1.5
      escape = 0b1

      z = 0
      while z < 50
        tr = zrzr - zizi + cr
        ti = 2.0*zr*zi + ci
        zr = tr
        zi = ti
        # preserve recalculation
        zrzr = zr*zr
        zizi = zi*zi
        if zrzr+zizi > 4.0
          escape = 0b0
          break
        end
        z += 1
      end

      byte_acc = (byte_acc << 1) | escape
      bit_num += 1

      # Code is very similar for these cases, but using separate blocks
      # ensures we skip the shifting when it's unnecessary, which is most cases.
      if (bit_num == 8)
        output.print byte_acc.chr
        byte_acc = 0
        bit_num = 0
      elsif (x == size - 1)
        byte_acc <<= (8 - bit_num)
        output.print byte_acc.chr
        byte_acc = 0
        bit_num = 0
      end
      x += 1
    end
    y += 1
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