#/usr/local/lib/ruby/site_ruby/1.8/sandbox/irb.rb
require 'sandbox/irb'

# ArchitectIRB is a special Interactive Ruby client used by the Architect. The Architect is able to modify the Daimoku Game World.
# Code written by the Architect, using the ArchitectIRB, is not viewable by the Players withi the Game World.
class ArchitectIRB < Sandbox::IRB

  def simulation_client= sc
    @simulation_client = sc
  end

  def start(io)

    raise if !@simulation_client  #must set simulation client
    scanner = RubyLex.new
    scanner.exception_on_syntax_error = false
    scanner.set_prompt do |ltype, indent, continue, line_no|
      if ltype
        f = @prompt[:string]
      elsif continue
        f = @prompt[:continue]
      elsif indent > 0
        f = @prompt[:nested]
      else
        f = @prompt[:start]
      end
      f = "" unless f
      @p = prompt(f, ltype, indent, line_no)
    end
    scanner.set_input(io) do
      signal_status(:IN_INPUT) do
        io.print @p
        result = io.gets if io.closed? == false && io
        if result
          result.gsub(/[\x00-\x09\x0B\x0C\x0E-\x1F\x80-\xFF]/,'')
        else
          ""
        end
      end
    end
    scanner.each_top_level_statement do |line, line_no|
      signal_status(:IN_EVAL) do
        line.untaint
        line.chomp!
        puts line
        p line
        return if line == "quit"
        return if line == 'q'
        begin
          val = box_eval(line)
          io.puts @prompt[:return] % [val.inspect]
        rescue Sandbox::Exception, Sandbox::TimeoutError => e
          # Possible MUD command
          case
          when line =~ /^take /
            cooked = line.gsub(/^take /,'')
            @simulation_client.take cooked
          when line =~ /^drop /
            cooked = line.gsub(/^drop /,'')
            @simulation_client.drop cooked
          when line =~ /^look$/ || line =~ /^l$/
            @simulation_client.look
          when line =~ /^inventory$/ || line =~ /^i$/
            @simulation_client.inventory
          when line =~ /^say /
            cooked = line.gsub(/^say/,'')
            @simulation_client.say cooked
          when line =~ /^emote /
            cooked = line.gsub(/^emote/,'')
            @simulation_client.emote cooked
          when line =~ /^up$/ || line =~ /^u$/
            @simulation_client.up
          when line =~ /^down$/ || line =~ /^d$/
            @simulation_client.down
          when line =~ /^north$/ || line =~ /^n$/
            @simulation_client.north
          when line =~ /^south$/ || line =~ /^s$/
            @simulation_client.south
          when line =~ /^east$/ || line =~ /^e$/
            @simulation_client.east
          when line =~ /^west$/ || line =~ /^w$/
            @simulation_client.west
          when line =~ /^exits$/
            @simulation_client.exits
          when line =~ /^io/
            @simulation_client.io
          when line =~ /^help$/ || line =~ /^\?$/
            io.puts
            io.puts "Commands:\n l-ook\n exits\n n-orth\n s-outh\n e-ast\n w-est\n u-p\n d-own\n io\n take\n drop\n emote\n i-nventory\n"
            io.puts "Your IO object is #{@simulation_client.player_io}. i.e. #{@simulation_client.player_io}.puts 'hello world'"
            io.puts "Your LEGO object is #{@simulation_client.player_lego_io }. i.e. h = HardLine.new(#{@simulation_client.player_lego_io})"
            io.puts
          else
            # Not a MUD command, therefore handle the error output normally
            io.print e, "\n"
          end
        end
      end
    end
  end
end


