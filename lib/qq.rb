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
#--
# TODO: Calling Q twice on the same line will cause issues because
# Thread::Backtrace::Location doesn't give us a character only a line.
class QQ < Parser::AST::Processor
  NORMAL, YELLOW, CYAN = "\x1b[0m", "\x1b[33m", "\x1b[36m"

  @@mutex ||= Mutex.new
  @@start ||= Time.now
  @@location ||= nil

  # @see Kernel#qq
  #--
  # TODO: Complain if called directly.
  def initialize location, args
    @location, @args = location, args
    process(Parser::CurrentRuby.parse(File.read(location.absolute_path)))
  end

  def on_send ast_node
    return unless ast_node.loc.line == @location.lineno
    ast_receiver, ast_method, *ast_args = *ast_node

    return if ast_receiver || ast_method != :qq
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

module Kernel
  # Pretty print statements with QQ.
  #
  # @example qq('hello world')
  def qq *args
    QQ.new(caller_locations(1, 1).first, args)
  end
end
