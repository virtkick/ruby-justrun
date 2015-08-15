require 'open3'

#TODO: Run multiple commands at the same time

class JustRun
  def self.command(command, block_size: 4096*4, init: ->(writer) {}, env: ENV, &block)
    ret_code = -1
    Open3.popen3 env, command do |stdin, stdout, stderr, wait_thr|
      writer = JustRun::Writer.new stdin
      init.call writer

      fileno_lines = {}
      begin
        files = [stdout, stderr]
        fileno2name = {
            stdout.fileno => :stdout,
            stderr.fileno => :stderr
        }
        until all_eof files do
          ready = IO.select files, stdin.closed? ? [] : [stdin], [], 0.1
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
                  block.call lines.shift.chomp, name, writer
                end
              rescue EOFError => e
                # expected
              end
              writable = ready[1]
              writable.each do |stdin|
                writer.process
              end
            end
          end
        end
        fileno_lines.each do |fileno, lines|
          name = fileno2name[fileno]
          if lines.length > 0
            block.call lines.shift.chomp, name, writer
          end
        end
      rescue IOError => e
        raise e
      end
      ret_code = wait_thr.value
    end
    ret_code.exitstatus
  end

  private
  def self.all_eof(files)
    files.find { |f| !f.eof }.nil?
  end

  class Writer
    def initialize stdin
      @buffer = ''
      @stdin = stdin
    end

    def puts str
      write "#{str}\n"
    end

    def write str
      @buffer << str;
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
        break if written == 0
      end
    rescue IO::WaitWritable, Errno::EINTR
    end
  end
end