require_relative 'helper'
require 'shiba'
require 'shiba/fuzzer'
require 'shiba/configure'
require 'open3'
require 'tempfile'

describe "Connection" do
  it "doesn't blow up" do
    assert_equal Shiba.database, Shiba.connection.query("select database() as db").first["db"]

    stats = Shiba::Fuzzer.new(Shiba.connection).fuzz!
    assert stats.any?, stats.inspect
  end

  it "logs queries" do
    file = Tempfile.new('foo')
    test_app_path = File.join(File.dirname(__FILE__), 'app', 'app.rb')

    # This is auto-removed, so uncomment / use debugger to debug output issues.
    env = { 'SHIBA_PATH' => File.dirname(file.path), 'SHIBA_OUT' => File.basename(file.path)}
    Open3.popen2e(env, "ruby", test_app_path) {|_,eo,thread|
      out = eo.readlines
      if ENV['SHIBA_DEBUG']
        $stderr.puts out
      end
      assert_equal 0, thread.value.exitstatus, out
    }

    queries = File.read(file.path)
    # Should be 1, but there's schema loading garbage that's hard to remove
    assert_equal 9, queries.lines.size, "No queries logged"
  end

  it "logs queries on CI" do
    skip if !Shiba::Configure.ci?
    test_app_path = File.join(File.dirname(__FILE__), 'app', 'app.rb')

    env = {}
    Open3.popen2e(env, "ruby", test_app_path) {|_,eo,thread|
      out = eo.readlines
      if ENV['SHIBA_DEBUG']
        $stderr.puts out
      end
    }

    assert File.exist?(File.join(Shiba.path, 'ci.json')), "No log file found at #{Shiba.path}"
   end
end
