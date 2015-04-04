require 'open3'

class JustRun


  def self.command(command, init: lambda { |stdin|
    stdin.close_write
  }, &block)
    ret_code = -1
    Open3.popen3 command do |stdin, stdout, stderr, wait_thr|
      init.call stdin
      fileno_lines = {}
      begin
        files = [stdout, stderr]
        fileno2name = {
            stdout.fileno => :stdout,
            stderr.fileno => :stderr
        }
        until all_eof files do
          ready = IO.select files
          if ready
            readable = ready[0]
            readable.each do |f|
              fileno = f.fileno
              fileno_lines[fileno] ||= []
              lines = fileno_lines[fileno]
              name = fileno2name[fileno]
              begin
                data = f.read_nonblock BLOCK_SIZE
                lines_new = data.lines
                if lines.length > 0 and lines[-1] !~ /\n\r?$/
                  lines[-1] = lines[-1] + lines_new.shift
                end
                lines.push(*lines_new)
                while lines[0] =~ /\n\r?/
                  block.call lines.shift.chomp, name, stdin
                end
              rescue EOFError => e
                # expected
              end
            end
          end
        end
        fileno_lines.each do |fileno, lines|
          name = fileno2name[fileno]
          if lines.length > 0
            block.call lines.shift.chomp, name, stdin
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
  BLOCK_SIZE = 4096*4

end