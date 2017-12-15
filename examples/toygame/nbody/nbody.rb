# The Computer Language Benchmarks Game
# http://benchmarksgame.alioth.debian.org
#
# Optimized for Ruby by Jesse Millikan
# From version ported by Michael Neumann from the C gcc version,
# which was written by Christoph Bauer.
# modified by Michael Leimstädtner

SOLAR_MASS = 4 * Math::PI**2
DAYS_PER_YEAR = 365.24
DT = 0.01

class Planet
 attr_accessor :x, :y, :z, :vx, :vy, :vz, :mass

 def initialize(x, y, z, vx, vy, vz, mass)
  # Positions
  @x, @y, @z = x, y, z
  # Velocities
  @vx, @vy, @vz = vx * DAYS_PER_YEAR, vy * DAYS_PER_YEAR, vz * DAYS_PER_YEAR
  # Absolute Mass
  @mass = mass * SOLAR_MASS
 end

 def calculate_influences_of_missing_i(bodies, i)
  while i < bodies.size
   other_body = bodies[i]
   dx = @x - other_body.x
   dy = @y - other_body.y
   dz = @z - other_body.z

   distance = Math.sqrt(dx * dx + dy * dy + dz * dz)
   mag = DT / (distance * distance * distance)
   b_mass_mag, other_body_mass_mag = @mass * mag, other_body.mass * mag

   @vx -= dx * other_body_mass_mag
   @vy -= dy * other_body_mass_mag
   @vz -= dz * other_body_mass_mag
   other_body.vx += dx * b_mass_mag
   other_body.vy += dy * b_mass_mag
   other_body.vz += dz * b_mass_mag
   i += 1
  end

  @x += DT * @vx
  @y += DT * @vy
  @z += DT * @vz
 end
end

def energy(bodies)
  e = 0.0
  nbodies = bodies.size

  for i in 0 ... nbodies
    b = bodies[i]
    e += 0.5 * b.mass * (b.vx * b.vx + b.vy * b.vy + b.vz * b.vz)
    for j in (i + 1) ... nbodies
      other_body = bodies[j]
      dx = b.x - other_body.x
      dy = b.y - other_body.y
      dz = b.z - other_body.z
      distance = Math.sqrt(dx * dx + dy * dy + dz * dz)
      e -= (b.mass * other_body.mass) / distance
    end
  end
  e
end

def offset_momentum(bodies)
  px, py, pz = 0.0, 0.0, 0.0

  for b in bodies
    m = b.mass
    px += b.vx * m
    py += b.vy * m
    pz += b.vz * m
  end

  b = bodies[0]
  b.vx = - px / SOLAR_MASS
  b.vy = - py / SOLAR_MASS
  b.vz = - pz / SOLAR_MASS
end

def move_one_tic
  BODIES.size.times do |i|
    BODIES[i].calculate_influences_of_missing_i(BODIES, i + 1)
  end
end

BODIES = [
  # sun       x    y    z   vx   vy   vz   mass
  Planet.new(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0),

  # jupiter
  Planet.new(
    4.84143144246472090e+00,  # x
    -1.16032004402742839e+00, # y
    -1.03622044471123109e-01, # z
    1.66007664274403694e-03,  # vx = x velocity per day
    7.69901118419740425e-03,  # vy
    -6.90460016972063023e-05, # vz
    9.54791938424326609e-04), # mass proportional to solar mass

  # saturn
  Planet.new(
    8.34336671824457987e+00,  # x
    4.12479856412430479e+00,  # y
    -4.03523417114321381e-01, # z
    -2.76742510726862411e-03, # vx = x velocity
    4.99852801234917238e-03,  # vy
    2.30417297573763929e-05,  # vz
    2.85885980666130812e-04), # mass

  # uranus
  Planet.new(
    1.28943695621391310e+01,  # x
    -1.51111514016986312e+01, # y
    -2.23307578892655734e-01, # z
    2.96460137564761618e-03,  # vx = x velocity
    2.37847173959480950e-03,  # vy
    -2.96589568540237556e-05, # vz
    4.36624404335156298e-05), # mass

  # neptune
  Planet.new(
    1.53796971148509165e+01,  # x
    -2.59193146099879641e+01, # y
    1.79258772950371181e-01,  # z
    2.68067772490389322e-03,  # vx = x velocity
    1.62824170038242295e-03,  # vy
    -9.51592254519715870e-05, # vz
    5.15138902046611451e-05)  # mass
]


def nbody(movements)
  offset_momentum(BODIES)

  puts "%.9f" % energy(BODIES)

  movements.times do
    move_one_tic
  end

  puts "%.9f" % energy(BODIES)
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

TCompare::Worker.parametrized_iteration_measured do |n|
  nbody(n.to_i)
end.start