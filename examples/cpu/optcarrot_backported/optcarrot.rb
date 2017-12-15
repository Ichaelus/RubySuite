unless Kernel.respond_to?(:require_relative)
  module Kernel
    def require_relative(path)
      require File.join(File.dirname(caller[0]), path.to_str)
    end
  end
end

WORKER_PATH = "../../../app/t_compare/worker"
require_relative WORKER_PATH


require_relative "lib/optcarrot"
require_relative "tools/shim"
require 'stringio'

TCompare::Worker.n_iterations_with_value do
  # Actually the contents of bin/optcarrot
  iobuffer = StringIO.new
  $stdout = iobuffer
  Optcarrot::NES.new(["--benchmark", "examples/cpu/optcarrot_backported/examples/Lan_Master.nes"]).run
  benchmark_result = $stdout.string
  benchmark_result[/fps: (\d+\.\d+)/, 1].to_f
end.start