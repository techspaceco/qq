require 'pp'
require 'tmpdir'
require 'thread'

# QQ improves puts debugging.
#
# All output goes to 'q' in your `Dir.tempdir`, normally '/tmp/q'.
#
# touch /tmp/q && tail -f /tmp/q
#
# To print the value of something require 'qq' and use qq() anywhere you would
# have previously used  pp(), puts etc and searched log files, $stderr, $stdout
# etc. for your debugging.
#
# @example
#   require 'qq'; qq('hello world')
# @see Python https://github.com/zestyping/q
# @see Go https://github.com/y0ssar1an/q
#--
# TODO: Multiple line statement matching.
# TODO: Compact printing for single line < 80 chars.
Q = Object.new
class << Q
  # Best effort call source cleanup without AST.
  # As the saying goes, "Only perl can parse Perl" and the same applies to Ruby.
  # Parsing Ruby source is always a bad idea so just print the file:line if we
  # can't match a basic statement.
  RE = %r{
    (?<parens>\( (?:[^()]+ | \<parens>)+ \)){0}
    (?<bare>[\t ]+ (?:[^;]+ | \<parens>)+ (?=[\n;])){0}
    (?:Q\.|;|\s|\A|q)q(?<statement>\g<parens>|\g<bare>)
  }x

  NORMAL, YELLOW, CYAN = "\x1b[0m", "\x1b[33m", "\x1b[36m"

  # Pretty print statements with QQ.
  #
  # @example
  #   qq('hello world')
  def q *args
    _q(*args)
  end

  #--
  # Lazy hack so we can define multiple names and caller(2) will be the correct
  # stack depth.
  def _q *args
    @instance ||= begin
      @mu     = Mutex.new
      @buffer = Queue.new
      @start  = Time.now
      @tid    = Thread.new do
        running = true
        at_exit{running = false; @tid.join}

        while running || !@buffer.empty?
          event = @buffer.pop
          File.open(File.join(Dir.tmpdir, 'q'), 'a') do |fh|
            fh.write event.to_s + NORMAL
          end
        end
      end
    end

    location, now, event = caller_locations(2, 1).first, Time.now, ''
    @mu.synchronize do
      if @start <= now - 2 || @location&.label != location.label
        event << "\n%s[%s] %s\n" % [NORMAL, now.strftime('%T'), location.label]
        @start = now
      end

      source = File.open(location.absolute_path){|fh| location.lineno.times{fh.gets}; $_}
      source = RE.match(source) ? $~[:statement].strip : ''
      source = "(#{source})" unless source =~ /\A\(/

      event << [YELLOW, "%1.3fs " % (now - @start), NORMAL, source, ' = ', CYAN].join
      args.each{|arg| PP.pp(arg, event)}

      @location = location
      @buffer << event
    end
  end
end

module Kernel
  # Pretty print statements with QQ.
  #
  # @example
  #   qq('hello world')
  # @see Q.q
  def qq *args
    Q._q(*args)
  end
end

