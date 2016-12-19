require 'pp'
require 'tmpdir'
require 'thread'

# Suppress Ruby parser warnings.
# If the parser fails we have reasonable defaults.
begin
  stderr = $stderr
  $stderr = StringIO.new
  require 'parser'
  require 'unparser'
ensure
  $stderr = stderr
end

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
    @@mutex.synchronize do
      begin
        # Parse the statement that generated the argument from source.
        process(Parser::CurrentRuby.parse(File.read(location.absolute_path)))
      rescue StandardError
        # Failed to parse or embedded Ruby (HAML, ERB, ...) prints the position of each argument in qq()
        # location preamble/header.
        # line:0 arg:0 = ...
        # line:0 arg:1 = ...
        write args.each_with_index.map{|arg, position| [arg, 'line:%d arg:%d' % [@location.lineno, position]]}
      end
    end
  end

  def on_send ast_node
    return unless ast_node.loc.line == @location.lineno
    ast_receiver, ast_method, *ast_args = *ast_node

    return if ast_receiver || ast_method != :qq
    write @args.zip(ast_args).map{|arg, ast_arg| [arg, ast_arg.loc.expression.source]}
  end

  protected
  def write args
    File.open(File.join(Dir.tmpdir, 'q'), 'a') do |fh|
      now = Time.now

      if @@start <= now - 2 || @@location&.label != @location.label
        fh.write "\n%s[%s] %s\n" % [NORMAL, now.strftime('%T'), @location]
        @@start = now
      end

      args.each do |arg, arg_source|
        if defined?(ActiveRecord) && arg.is_a?(ActiveRecord::Base) && arg.respond_to?(:attributes)
          arg = arg.attributes
        end
        fh.write [YELLOW, "%1.3fs " % (now - @@start), NORMAL, arg_source, ' = ', CYAN].join
        PP.pp(arg, fh)
        fh.write NORMAL
      end

      @@location = @location
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
