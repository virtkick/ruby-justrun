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
      did = {}
      lorem_ipsum = LoremIpsum.lorem_ipsum(paragraphs: 100000)
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
  end
end

