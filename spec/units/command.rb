require 'justrun'
require 'lorem_ipsum_amet'

describe JustRun do
  it 'command should do :stdout and :stderr types' do
    did = {}
    JustRun.command 'echo foo && echo bar>&2' do |line, type|
      did[type] = line
    end
    expect(did).to eq({
      stdout: 'foo',
      stderr: 'bar'
    })
  end

  it 'command should livereport lines' do
    did = {}
    JustRun.command 'echo foo && sleep 1 && echo bar' do |line, type|
      did[line] = Time.now.to_i
    end
    expect(did['foo']).to eq(did['bar']-1)
  end

  it 'command should support big outputs and custom stdin' do
    did = {}
    lorem_ipsum = LoremIpsum.lorem_ipsum(paragraphs: 100)
    JustRun.command 'cat', init: lambda { |stdin|
      stdin.write lorem_ipsum
      stdin.close_write
     } do |line, type|
      did[type] ||= []
      did[type] << line
    end
    expect(did[:stdout].join("\n")).to eq(lorem_ipsum)
  end
end

