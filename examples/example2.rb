$:.unshift File.expand_path '../../lib', __FILE__
require 'pryception'

def alpha
  x = 1
  beta
end

def beta
  y = 30
  gamma(1, 2)
end

def gamma(x)
  greeting = x
end

Interception.prycept do
  alpha
end
