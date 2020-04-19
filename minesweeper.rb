require "byebug"
require "colorize"

# @author Michael Hollingworth
class Minesweeper
    COLORS = {
        1 => "1".blue,
        2 => "2".green,
        3 => "3".red,
        4 => "4".light_blue,
        5 => "5".light_red,
        6 => "6".light_green,
        7 => "7".yellow,
        8 => "8".light_black
    }
    
    def initialize(m, n, num_mines)
        raise ArgumentError, "Too many mines!" if num_mines >= m * n
        
        @height, @width = m, n
        @grid = Array.new(m) { Array.new(n, "☐") }
        @count = 0
        @marked = 0
        @revealed = 0
        @exploded = false
        @exploded_pos = [-1, -1]
        @num_mines = num_mines
    end

    def win?
        self.game_over? && !exploded
    end

    def game_over?
        exploded || marked == num_mines || revealed == height * width - num_mines
    end

    # Flags the given position or, if a flag is already, present, unflags it
    #
    # @param pos [Array<Numeric>] the position to flag
    # @return [nil]
    # @raise [ArgumentError] if position is not an array of 2 numeric values in
    #   range of the grid
    def flag(pos) 
        raise ArgumentError, "Position should be an array of length 2!" unless pos.is_a?(Array) && pos.size == 2
        raise ArgumentError, "Coordinates should be numeric!" unless pos[0].is_a?(Numeric) && pos[1].is_a?(Numeric)
        raise ArgumentError, "Invalid coordinates #{pos}!" unless valid_coords(*pos)
        raise "Too many flags!" unless count < num_mines
        if get(pos) == "⚑"
            set(pos, "☐")
            self.count = count - 1
            self.marked = marked - 1 if mine?(pos)
        elsif get(pos) == "☐"
            set(pos, "⚑")
            self.count = count + 1
            self.marked = marked + 1 if mine?(pos)
        end
        nil
    end


    # Checks the given position. Acts like a click in normal minesweeper
    #
    # @param pos [Array<Numeric>] the position to check
    # @return [Boolean] returns true if pos contains a mine, false otherwise
    # @raise [ArgumentError] if position is not an array of 2 numeric values in
    #   range of the grid
    def check(pos)
        raise ArgumentError, "Position should be an array of length 2!" unless pos.is_a?(Array) && pos.size == 2
        raise ArgumentError, "Coordinates should be numeric!" unless pos[0].is_a?(Numeric) && pos[1].is_a?(Numeric)
        raise ArgumentError, "Invalid coordinates #{pos}!" unless valid_coords(*pos)
        raise "That position is flagged!" unless get(pos) != "⚑"

        if mines == nil
            place_mines(num_mines, pos)
        end
        
        if mine?(pos)
            self.exploded = true
            self.exploded_pos = pos
            return true
        end
        return false unless get(pos) == "☐"

        # Perform BFS to open up the grid
        queue = [pos]
        visited = Array.new(height * width, false)

        visited[pos[0] * width + pos[1]] = true

        while queue.size > 0
            i, j = queue.shift

            # Get neighbors
            neighbors = neighbors([i, j])

            # Get the mines around the current pos
            mines = get_mines(neighbors)
            mine_count = mines.size

            # Open current pos
            set([i, j], mine_count > 0 ? COLORS[mine_count] : " ")
            self.revealed = revealed + 1

            # Add neighbors to search
            if mines.all? { |pos| get(pos) == "⚑" }
                neighbors.each do |i_n, j_n|
                    if !mine?([i_n, j_n]) && !visited[i_n * width + j_n] && get([i_n, j_n]) == "☐"
                        visited[i_n * width + j_n] = true
                        queue << [i_n, j_n]
                    end
                end
            end
        end

        false
    end

    def to_s
        str = ""
        str += "  " + " 0 1 2 3 4 5 6 7 8 9" * (width / 10) 
        str += " 0 1 2 3 4 5 6 7 8 9"[0...(width % 10) * 2] + "\n"
        (0...height).each do |i|
            str += i.to_s.rjust(2) 
            (0...width).each do |j|
                str += " #{get([i, j])}"
            end
            str += "\n"
        end
        str += "Mines: #{[0, num_mines - count].max.to_s.rjust(3)}".rjust(width * 2 + 2)
        str 
    end

    def inspect
        str = ""
        str += "  " + " 0 1 2 3 4 5 6 7 8 9" * (width / 10) 
        str += " 0 1 2 3 4 5 6 7 8 9"[0...(width % 10) * 2] + "\n"
        (0...height).each do |i|
            str += i.to_s.rjust(2) 
            (0...width).each do |j|
                if mine?([i, j])
                    str += (exploded_pos == [i, j] ? " ☢".red : " ☢")
                else
                    count = get_mines(neighbors([i, j])).size
                    str += " " + (count > 0 ? COLORS[count] : " ")
                end
            end
            str += "\n"
        end
        str 
    end

    private
    
    attr_reader :height, :width, :num_mines, :mines
    attr_accessor :count, :revealed, :marked, :exploded, :exploded_pos

    # Checks whether the given coordinates are within the dimensions of the grid
    #
    # @param i [Integer] the row coordinate
    # @param j [Integer] the column coordinate
    # @return [Boolean] whether the coordinates are valid or not
    def valid_coords(i, j)
        (0...height) === i && (0...width) === j
    end

    # Gets the value of the element at the position of the grid
    #
    # @param pos [Array<Numeric>] a 2D array indicating the position to look up
    # @return [String] the value at the given position
    # @raise [ArgumentError] if position is not an array of 2 numeric values in
    #   range of the grid
    def get(pos)
        raise ArgumentError, "Position should be an array of length 2!" unless pos.is_a?(Array) && pos.size == 2
        raise ArgumentError, "Coordinates should be numeric!" unless pos[0].is_a?(Numeric) && pos[1].is_a?(Numeric)
        raise ArgumentError, "Invalid coordinates #{pos}!" unless valid_coords(*pos)
        i, j = pos
        @grid[i][j]
    end

    # Sets the element at the position of the grid to the passed value
    #
    # @param pos [Array<Numeric>] a 2D array indicating the position to set
    # @param value [String] the string to set the position in the grid to
    # @return [String] the passed value
    # @raise [ArgumentError] if position is not an array of 2 numeric values in
    #   range of the grid
    def set(pos, value)
        raise ArgumentError, "Position should be an array of length 2!" unless pos.is_a?(Array) && pos.size == 2
        raise ArgumentError, "Coordinates should be numeric!" unless pos[0].is_a?(Numeric) && pos[1].is_a?(Numeric)
        raise ArgumentError, "Invalid coordinates #{pos}!" unless valid_coords(*pos)
        i, j = pos
        @grid[i][j] = value
    end

    # Gets all the neighbors of the given position
    #
    # @param pos [Array<Numeric>] a 2D array indicating the position to get
    #   neighbors for
    # @return [Array<Array<Numeric>>] a list of neighbor positions
    # @raise [ArgumentError] if position is not an array of 2 numeric values in
    #   range of the grid
    def neighbors(pos)
        raise ArgumentError, "Position should be an array of length 2!" unless pos.is_a?(Array) && pos.size == 2
        raise ArgumentError, "Coordinates should be numeric!" unless pos[0].is_a?(Numeric) && pos[1].is_a?(Numeric)
        raise ArgumentError, "Invalid coordinates #{pos}!" unless valid_coords(*pos)
        dirs = [[-1,-1],[-1,0],[-1,1],[0,-1],[0,1],[1,-1],[1, 0],[1, 1]]
        i, j = pos
        dirs.map { |i_off, j_off| [i_off + i, j_off + j] }
            .select { |i, j| valid_coords(i, j) }
    end

    # Selects the positions with mines out of the list of positions
    #
    # @param pos [Array<Array<Numeric>>] a list of positions to check
    # @return [Array<Array<Numeric>>] the positions that contain mines
    def get_mines(positions)
        positions.select { |pos| mine?(pos) }
    end

    # Returns whether there is a mine at the given position
    #
    # @param pos [Array<Numeric>] a 2D array indicating the position to check
    # @return [Boolean] whether there is a mine at the givne position
    # @raise [ArgumentError] if position is not an array of 2 numeric values in
    #   range of the grid
    def mine?(pos)
        raise ArgumentError, "Position should be an array of length 2!" unless pos.is_a?(Array) && pos.size == 2
        raise ArgumentError, "Coordinates should be numeric!" unless pos[0].is_a?(Numeric) && pos[1].is_a?(Numeric)
        raise ArgumentError, "Invalid coordinates #{pos}!" unless valid_coords(*pos)
        i, j = pos
        @mines[i][j]
    end

    # Places num_mines mines in the grid
    #
    # @param num_mines [Integer] the number of mines to place
    # @param pos [Array<Numeric>] position not to place a mine in
    # @return [nil]
    def place_mines(num_mines, pos)
        coords = Array.new(height * width) { |i| [i / width, i % width] }
        coords.delete(pos)
        coords.shuffle!
        @mines = Array.new(height) { Array.new(width, false) }
        num_mines.times { |i| @mines[coords[i][0]][coords[i][1]] = true }
        nil
    end
end