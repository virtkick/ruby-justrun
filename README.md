# ruby-justrun
Wraps popen3 in a nice interface that allows to just run a command and get live stdout and stderr on line by line basis using a callback

## Install
```
gem install justrun
```
or add to your Gemfile
```
gem 'justrun', '~> 1.0.1'
```

## Examples
* Just run and forget
```rb
JustRun.command 'echo foo && echo bar>&2' do |line, type|
  puts "#{type}: #{line}"
end
```

* Using writer to communicate with the process
```rb
JustRun.command 'read line; echo $line; read line; echo $line',
init: ->(writer) { writer.puts 'hello' } do |line, _, writer|
    if line == 'hello'
      writer.puts 'world'
    elsif line == 'world'
      puts "GOT WORLD, THE CHAT WORKS!"
    end
  end
end
```

### Writer interface
* `writer.end str = ''` - end stdin once every byte is written, optionally provide some data to write before end
* `writer.write str` - queue some data to write to the process, data will be written automatically as the process reads it
* `writer.puts str` - same as write but add newline to str

## License
MIT
