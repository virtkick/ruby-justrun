require 'justrun'
require 'lorem_ipsum_amet'

describe JustRun do

  describe 'command' do
    it 'should do :stdout and :stderr types' do
      did = {}
      JustRun.command 'echo foo && echo bar>&2' do |line, type|
        did[type] = line
      end
      expect(did).to eq({
        stdout: 'foo',
        stderr: 'bar'
      })
    end

    it 'should livereport lines' do
      did = {}
      JustRun.command 'echo foo && sleep 1 && echo bar' do |line, type|
        did[line] = Time.now.to_i
      end
      expect(did['foo']).to eq(did['bar']-1)
    end

    it 'should support big outputs and custom stdin' do
      did = {}
      lorem_ipsum = LoremIpsum.lorem_ipsum(paragraphs: 100000)
      JustRun.command 'cat', init: ->(writer) {
        writer.end lorem_ipsum
       } do |line, type|
        did[type] ||= []
        did[type] << line
      end
      expect(did[:stdout].join("\n")).to eq(lorem_ipsum)
    end


    it 'should support live chat with the started command' do
      got_world = false
      JustRun.command 'read line; echo $line; read line; echo $line',
                      init: ->(writer) {
                        writer.puts 'hello'
                      } do |line, _, writer|
        if line == 'hello'
          writer.puts 'world'
        elsif line == 'world'
          got_world = true
        end
      end
      expect(got_world).to eq(true)
    end

    it 'should pass current environment by default' do
      did = {}
      ENV['JUSTRUN_TEST'] = 'test'
      JustRun.command 'echo $JUSTRUN_TEST' do |line, type|
        did[type] = line
      end
      ENV.delete('JUSTRUN_TEST')
      expect(did).to eq({
          stdout: 'test'
      })
    end

    it 'should allow to pass environment variable without affecting current environment' do
      did = {}
      JustRun.command 'echo $JUSTRUN_TEST2', env: {
        'JUSTRUN_TEST2' => 'test2'
      } do |line, type|
        did[type] = line
      end
      expect(ENV['JUSTRUN_TEST2']).to eq(nil)
      expect(did).to eq({
        stdout: 'test2'
      })
    end

    # it 'should log all stdout of command if requested' do
    #   did = {}
    #   lorem_ipsum = LoremIpsum.lorem_ipsum(paragraphs: 100000)
    #   status = JustRun.command 'cat', init: ->(writer) {
    #         writer.end lorem_ipsum
    #       }, buffer_output: true
    #   expect(status[:stdout].join("\n")).to eq(lorem_ipsum)
    # end

    it 'should log all stderr of command if requested' do
      status = JustRun.command 'cat foo/bar/foo', buffer_output: true
      expect(status[:stderr].join("\n")).to eq('cat: foo/bar/foo: No such file or directory')
    end
    
    it 'should support chdir' do
      parent_dir = File.expand_path("..", Dir.pwd)
      
      status = JustRun.command 'pwd', chdir: '..', buffer_output: true
      expect(status[:stdout].join("\n")).to eq(parent_dir)
    end

    it 'should handle timeout' do
      JustRun.command 'usleep 100000', timeout: 1.1
      expect {
        JustRun.command 'sleep 200 && echo dupa', timeout: 0.1
      }.to raise_error JustRun::CommandTimeout
    end
  end
end
