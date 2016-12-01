require 'minitest/spec'
require 'minitest/autorun'

require 'qq'
require 'tmpdir'
require 'erb'

describe 'qq' do
  before do
    @qfile = File.join(Dir.tmpdir, 'q')
    File.truncate(@qfile, 0)
  end

  it 'must qq to temp directory file q' do
    assert !File.size?(@qfile), 'must be truncated'
    qq('qq must qq')

    assert File.size?(@qfile), 'must have size after qq'
    assert output = File.read(@qfile)

    assert_match(%r{\[(?:\d\d:){2}\d\d\]}sm, output, 'qq prints header time')
    assert_match(%r{qq_test.rb:\d+}sm, output, 'qq prints header stack trace label')

    assert_match(%r{'qq must qq'}sm, output, 'qq prints expression')
    assert_match(%r{=[^"]+"qq must qq"}sm, output, 'qq prints expression result')
  end

  it 'must qq embedded ruby' do
    ERB.new(File.read(File.join(File.dirname(__FILE__), 'fixtures', 'qq_test.html.erb'))).result

    assert File.size?(@qfile), 'must have size after qq'
    assert output = File.read(@qfile)

    assert_match(%r{line:\d+ arg:\d+}, output, 'qq prints argument position')
    assert_match(%r{=[^"]+"qq erb"}sm, output, 'qq prints expression from evaled erb')
  end
end
