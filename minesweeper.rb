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
    
    attr_accessor :height, :width, :count, :num_mines, :revealed, :marked, :exploded
    
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
        self.game_over? && !self.exploded
    end

    def game_over?
        self.exploded || self.marked == self.num_mines || self.revealed == self.height * self.width - self.num_mines
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
        raise ArgumentError, "Invalid coordinates #{pos}!" unless self.valid_coords(*pos)
        raise "Too many flags!" unless self.count < self.num_mines
        if self[pos] == "⚑"
            self[pos] = "☐"
            self.count -= 1
            self.marked -= 1 if self.mine?(pos)
        elsif self[pos] == "☐"
            self[pos] = "⚑"
            self.count += 1
            self.marked += 1 if self.mine?(pos)
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
        raise ArgumentError, "Invalid coordinates #{pos}!" unless self.valid_coords(*pos)
        raise "That position is flagged!" unless self[pos] != "⚑"

        if @mines == nil
            self.place_mines(num_mines, pos)
        end
        
        if self.mine?(pos)
            self.exploded = true
            @exploded_pos = pos
            return true
        end
        return false unless self[pos] == "☐"

        # Perform BFS to open up the grid
        queue = [pos]
        visited = Array.new(self.height * self.width, false)

        visited[pos[0] * self.width + pos[1]] = true

        while queue.size > 0
            i, j = queue.shift

            # Get neighbors
            neighbors = self.neighbors([i, j])

            # Count number of mines around current pos
            count = self.count_mines(neighbors)

            # Open current pos
            self[[i, j]] = count > 0 ? COLORS[count] : " "
            self.revealed += 1

            # Add neighbors to search
            if count == 0
                neighbors.each do |i_n, j_n|
                    if !self.mine?([i_n, j_n]) && !visited[i_n * self.width + j_n]
                        visited[i_n * self.width + j_n] = true
                        queue << [i_n, j_n]
                    end
                end
            end
        end
        
        false
    end

    def to_s
        str = ""
        str += "  " + " 0 1 2 3 4 5 6 7 8 9" * (self.width / 10) 
        str += " 0 1 2 3 4 5 6 7 8 9"[0...(self.width % 10) * 2] + "\n"
        (0...self.height).each do |i|
            str += i.to_s.rjust(2) 
            (0...self.width).each do |j|
                str += " #{self[[i, j]]}"
                # str += " " if (j + 1) % 5 == 0
            end
            str += "\n"
            # str += "\n" if (i + 1) % 5 == 0
        end
        str += "Mines: #{[0, self.num_mines - self.count].max}".rjust(self.width * 2)
        str 
    end

    def inspect
        str = ""
        str += "  " + " 0 1 2 3 4 5 6 7 8 9" * (self.width / 10) 
        str += " 0 1 2 3 4 5 6 7 8 9"[0...(self.width % 10) * 2] + "\n"
        (0...self.height).each do |i|
            str += i.to_s.rjust(2) 
            (0...self.width).each do |j|
                if self.mine?([i, j])
                    str += (@exploded_pos == [i, j] ? " ☢".red : " ☢")
                else
                    count = self.count_mines(self.neighbors([i, j]))
                    str += " " + (count > 0 ? COLORS[count] : " ")
                end
                # str += " " if (j + 1) % 5 == 0
            end
            str += "\n"
            # str += "\n" if (i + 1) % 5 == 0
        end
        str 
    end

    protected :height, :height=, :width, :width=, :count=, :num_mines=, :revealed=, :marked, :marked=, :exploded, :exploded=

    # Checks whether the given coordinates are within the dimensions of the grid
    #
    # @param i [Integer] the row coordinate
    # @param j [Integer] the column coordinate
    # @return [Boolean] whether the coordinates are valid or not
    def valid_coords(i, j)
        (0...self.height) === i && (0...self.width) === j
    end

    # Gets the value of the element at the position of the grid
    #
    # @param pos [Array<Numeric>] a 2D array indicating the position to look up
    # @return [String] the value at the given position
    # @raise [ArgumentError] if position is not an array of 2 numeric values in
    #   range of the grid
    def [](pos)
        raise ArgumentError, "Position should be an array of length 2!" unless pos.is_a?(Array) && pos.size == 2
        raise ArgumentError, "Coordinates should be numeric!" unless pos[0].is_a?(Numeric) && pos[1].is_a?(Numeric)
        raise ArgumentError, "Invalid coordinates #{pos}!" unless self.valid_coords(*pos)
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
    def []=(pos, value)
        raise ArgumentError, "Position should be an array of length 2!" unless pos.is_a?(Array) && pos.size == 2
        raise ArgumentError, "Coordinates should be numeric!" unless pos[0].is_a?(Numeric) && pos[1].is_a?(Numeric)
        raise ArgumentError, "Invalid coordinates #{pos}!" unless self.valid_coords(*pos)
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
        raise ArgumentError, "Invalid coordinates #{pos}!" unless self.valid_coords(*pos)
        dirs = [[-1,-1],[-1,0],[-1,1],[0,-1],[0,1],[1,-1],[1, 0],[1, 1]]
        i, j = pos
        dirs.map { |i_off, j_off| [i_off + i, j_off + j] }
            .select { |i, j| self.valid_coords(i, j) }
    end

    # Counts the number of mines in the list of positions
    #
    # @param pos [Array<Array<Numeric>>] a list of positions to check
    # @return [Numeric] the number of positions in the list which are mines
    def count_mines(positions)
        positions.count { |pos| self.mine?(pos) }
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
        raise ArgumentError, "Invalid coordinates #{pos}!" unless self.valid_coords(*pos)
        i, j = pos
        @mines[i][j]
    end

    # Places num_mines mines in the grid
    #
    # @param num_mines [Integer] the number of mines to place
    # @param pos [Array<Numeric>] position not to place a mine in
    # @return [nil]
    def place_mines(num_mines, pos)
        coords = Array.new(self.height * self.width) { |i| [i / self.width, i % self.width] }
        coords.delete(pos)
        coords.shuffle!
        @mines = Array.new(self.height) { Array.new(self.width, false) }
        num_mines.times { |i| @mines[coords[i][0]][coords[i][1]] = true }
        nil
    end
end