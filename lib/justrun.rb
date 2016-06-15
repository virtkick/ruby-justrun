require 'open3'

#TODO: Run multiple commands at the same time

class JustRun
  class CommandTimeout < Exception
  end

  def self.command(command, timeout: 0, block_size: 4096*4, buffer_output: false, chdir: Dir.pwd, init: ->(writer) {}, env: ENV, &block)
    ret_code = -1

    buffers = {
        stdout: [],
        stderr: [],
        all: []
    }

    beginning_time = Time.now
    Open3.popen3 env, command, chdir: chdir do |stdin, stdout, stderr, wait_thr|
      writer = JustRun::Writer.new stdin
      init.call writer
      line_handler = -> line, name {
        if buffer_output
          buffers[name].push line
          buffers[:all].push line
        end
        if block
          block.call line, name, writer
        end
      }

      fileno_lines = {}
      begin
        files = [stdout, stderr]
        fileno2name = {
            stdout.fileno => :stdout,
            stderr.fileno => :stderr
        }

        was_eof = []
        until was_eof[stdout.fileno] && was_eof[stderr.fileno] do
          ready = IO.select files, stdin.closed? ? [] : [stdin], [], 0.1
          if timeout > 0 && (Time.now - beginning_time) > timeout
            `kill -9 #{wait_thr.pid}` # note: Process.kill does not work
            raise CommandTimeout, "Command: '#{command}' timed out with timeout #{timeout}s"
          end

          if ready
            readable = ready[0]
            readable.each do |f|
              fileno = f.fileno
              fileno_lines[fileno] ||= []
              lines = fileno_lines[fileno]
              name = fileno2name[fileno]

              begin
                data = f.read_nonblock block_size
                lines_new = data.lines
                if lines.length > 0 and lines[-1] !~ /\n\r?$/
                  lines[-1] = lines[-1] + lines_new.shift
                end
                lines.push(*lines_new)
                while lines[0] =~ /\n\r?/
                  line = lines.shift.chomp
                  line_handler.call line, name
                end
              rescue EOFError => e
                was_eof[fileno] = true
              end
            end
            writable = ready[1]
            writable.each { |stdin|  writer.process }
          end
        end
        fileno_lines.each do |fileno, lines|
          name = fileno2name[fileno]
          if lines.length > 0
            line_handler.call lines.shift.chomp, name
          end
        end
      rescue IOError => e
        raise e
      end
      ret_code = wait_thr.value
    end

    if buffer_output
      {
        code: ret_code.exitstatus,
        stderr: buffers[:stderr],
        stdout: buffers[:stdout],
        all: buffers[:all]
      }
    else
      ret_code.exitstatus
    end
  end

  private

  class Writer
    def initialize stdin
      @buffer = ''
      @stdin = stdin
    end

    def puts str
      write "#{str}\n"
    end

    def write str
      @buffer << str
      process
    end

    def on_empty callback
      @on_empty = callback
    end

    def end str = ''
      if str.length > 0
        write str
      end
      if @buffer.length > 0
        on_empty -> {
          self.end
        }
      else
        @stdin.close_write
      end
    end

    def process
      return unless @buffer.length > 0
      loop do
        written = @stdin.write_nonblock @buffer
        @buffer = @buffer[written..-1]
        if @buffer.length == 0 and @on_empty
          @on_empty.call
          return
        end
        return true if written == 0
      end
    rescue IO::WaitWritable, Errno::EINTR
    end
  end
end
