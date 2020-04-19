require_relative "./minesweeper.rb"

class PlayMinesweeper
    COMMANDS = {
        "[s]tart <height> <width> <mines> | [s]tart <easy | medium | expert>" => "When given a difficulty, starts a game at that difficulty. Otherwise starts a game with the given dimensions.",
        "[c]heck <row> <col>" => "Checks the tile at the given row and column. If it is a mine, the game is lost.",
        "[f]lag <row> <col>" => "Flags the tile at the given row and column. Prevents you from accidentally checking the flagged position.",
        "[q]uit" => "Quits the game."
    }
    
    def get_command
        print "> "
        cmd, *args = gets.chomp.split
        system("clear") || system("cls")

        case cmd
        when "s", "start"
            if args.size == 3 
                if args.all? { |arg| /\d+/ === arg }
                    h, w, m = args.map(&:to_i)
                    if ((10..50) === h && (10..50) === w) 
                        begin
                            @minesweeper = Minesweeper.new(h, w, m)
                        rescue ArgumentError => e
                            puts "> #{e}"
                        end
                    else
                        puts "> Height #{h} and width #{w} out of range 10-50!"
                    end
                else
                    puts "> Arguments should be numbers!"
                end
            elsif args.size == 1
                if ["easy", "medium", "expert"].any? { |diff| diff == args[0].downcase }
                    case args[0].downcase
                    when "easy"
                        @minesweeper = Minesweeper.new(8, 8, 10)
                    when "medium"
                        @minesweeper = Minesweeper.new(15, 13, 40)
                    when "expert"
                        @minesweeper = Minesweeper.new(30, 16, 99)
                    end
                else
                    puts "> Invalid difficulty #{args[0]}! Expected easy, medium, or expert."
                end
            else
                puts "> Invalid number of arguments #{args.size}!"
                puts "> Correct usage is: "
                puts ">  - start <height> <width> <mines>"
                puts ">  - start <easy | medium | expert>"
            end
        when "c", "check"
            if @minesweeper == nil
                puts "> You need to start a game first!"
            elsif args.size == 2
                if args.all? { |arg| /\d+/ === arg }
                    i, j = args.map(&:to_i)
                    begin
                        @minesweeper.check([i, j])
                    rescue ArgumentError, RuntimeError => e
                        puts "> #{e}"
                    end
                else
                    puts "> Arguments should be numbers!"
                end
            else
                puts "> Invalid number of arguments #{args.size}!"
                puts "> Correct usage is: check <row> <col>."
            end
        when "f", "flag"
            if @minesweeper == nil
                puts "> You need to start a game first!"
            elsif args.size == 2
                if args.all? { |arg| /\d+/ === arg }
                    i, j = args.map(&:to_i)
                    begin
                        @minesweeper.flag([i, j])
                    rescue ArgumentError, RuntimeError => e
                        puts "> #{e}"
                    end
                else
                    puts "> Arguments should be numbers!"
                end
            else
                puts "> Invalid number of arguments #{args.size}!"
                puts "> Correct usage is: flag <row> <col>."
            end
        when "h", "help"
            if args.size == 1
                arg = args[0].downcase
                name = ""
                entry = ""
                COMMANDS.each do |key, value|
                    if arg.size == 0 && key[1] == arg || key.include?("[#{arg[0]}]#{arg[1..-1]}")
                        name = key
                        entry = value
                        break
                    end
                end
                if name != ""
                    puts "> #{name}"
                    puts ">  - #{entry}"
                else
                    puts "> Unrecognized command #{arg}! Use \"help\" to get a list of commands!"
                end
            else
                puts "> [h]elp [cmd]: Lists all available commands if no cmd is specified. Otherwise gives detailed information on the passed command."
                COMMANDS.each do |key, _|
                    puts ">  - #{key}"
                end
            end
        when "q", "quit"
            return false
        else
            puts "> Unrecognized command #{cmd}! Use \"help\" to get a list of commands!"
        end

        true
    end

    def play
        puts "> Welcome to Minesweeper!"
        while true
            break unless self.get_command
            if @minesweeper
                unless @minesweeper.game_over? 
                    puts @minesweeper
                else
                    puts "> Game over! #{@minesweeper.win? ? "You won!" : "You lost."}"
                    p @minesweeper
                    @minesweeper = nil
                end
            else
                puts "> Start a game with the start command."
            end
        end

        puts "> Thank you for playing!"
        puts "> Bye bye!"
    end
end

PlayMinesweeper.new.play