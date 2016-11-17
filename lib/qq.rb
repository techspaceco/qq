require 'pp'
require 'tmpdir'
require 'thread'
require 'parser'
require 'unparser'

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
module Q
  #--
  # TODO: Calling Q twice on the same line will cause issues because
  # Thread::Backtrace::Location doesn't give us a character only a line.
  class QQ < Parser::AST::Processor
    NORMAL, YELLOW, CYAN = "\x1b[0m", "\x1b[33m", "\x1b[36m"

    @@mutex ||= Mutex.new
    @@start ||= Time.now
    @@location ||= nil

    def initialize location, args
      @location, @args = location, args
      process(Parser::CurrentRuby.parse(File.read(location.absolute_path)))
    end

    def on_send ast_node
      return unless ast_node.loc.line == @location.lineno
      ast_receiver, ast_method, *ast_args = *ast_node

      if ast_receiver # Q.q
        _, ast_const, _ = *ast_receiver
        return unless ast_const == :Q && ast_method == :q
      else # qq
        return unless ast_method == :qq
      end

      @@mutex.synchronize do
        File.open(File.join(Dir.tmpdir, 'q'), 'a') do |fh|
          now = Time.now
          if @@start <= now - 2 || @@location&.label != @location.label
            fh.write "\n%s[%s] %s\n" % [NORMAL, now.strftime('%T'), @location]
            @@start = now
          end
          @args.zip(ast_args).each do |arg, ast_arg|
            fh.write [YELLOW, "%1.3fs " % (now - @@start), NORMAL, ast_arg.loc.expression.source, ' = ', CYAN].join
            PP.pp(arg, fh)
            fh.write NORMAL
          end
          @@location = @location
        end
      end
    end
  end

  # Pretty print statements with QQ.
  #
  # @example
  #  Q.q('hello world')
  def self.q *args
    _q(caller_locations(1, 1).first, args)
  end

  def self._q location, args
    QQ.new(location, args)
  end
end

module Kernel
  # Pretty print statements with QQ.
  #
  # @example
  #   qq('hello world')
  # @see Q.q
  def qq *args
    Q._q(caller_locations(1, 1).first, args)
  end
end
