#!/usr/bin/env ruby

@light = '/sys/class/leds/tpacpi::thinklight/brightness' #the path to the corresponding brightness file in /sys/class/, change to the light you want to blink

@loop = false

@log = false

class Morse
    @encoder = {
        #underscores for inter-element gaps
        'a' => '_._-_',
        'b' => '_-_._._._',
        'c' => '_-_._-_._',
        'd' => '_-_._._',
        'e' => '_._',
        'f' => '_._._-_._',
        'g' => '_-_-_._',
        'h' => '_._._._._',
        'i' => '_._._',
        'j' => '_._-_-_-_',
        'k' => '_-_._-_',
        'l' => '_._-_._._',
        'm' => '_-_-_',
        'n' => '_-_._',
        'o' => '_-_-_-_',
        'p' => '_._-_-_._',
        'q' => '_-_-_._-_',
        'r' => '_._-_._',
        's' => '_._._._',
        't' => '_-_',
        'u' => '_._._-_',
        'v' => '_._._._-_',
        'w' => '_._-_-_',
        'x' => '_-_._._-_',
        'y' => '_-_._-_-_',
        'z' => '_-_-_._._',
        '0' => '_-_-_-_-_-_',
        '1' => '_._-_-_-_-_',
        '2' => '_._._-_-_-_',
        '3' => '_._._._-_-_',
        '4' => '_._._._._-_',
        '5' => '_._._._._._',
        '6' => '_-_._._._._',
        '7' => '_-_-_._._._',
        '8' => '_-_-_-_._._',
        '9' => '_-_-_-_-_._',
        '\'' => '_._-_-_-_-_._',
        '(' => '_-_._-_-_._',
        ')' => '_-_._-_-_._-_',
        '=' => '_-_._._._-_',
        '@' => '_._-_-_._-_._',
        ':' => '_-_-_-_._._._',
        ',' => '_-_-_._._-_-_',
        '.' => '_._-_._-_._-_',
        '-' => '_-_._._._._-_',
        '/' => '_-_._._-_._',
        '+' => '_._-_._-_._',
        '\"' => '_._-_._._-_._',
        '?' => '_._._-_-_._._',
        '&' => '_._-_._._._', 
        ' ' => '^' #convenient space handling
    }
    
    @base_interval = 0.15 #base interval for all timing, make it bigger for slower blinking and smaller for faster blinking
    @dot_time = @base_interval #encoded char: .
    @dash_time = @base_interval * 3 #encoded char: -
    @int_gap = @base_interval #between dot/dashes within letters, encoded char: _
    @short_gap = @base_interval * 3 #between letters, encoded char: |
    @med_gap = @base_interval * 7 #between words, encoded  char: ^

    @states = {
        #stores brightness, duration, and logging name values for each encoded character
        #the brightness value can be set to greater then 1 if the light you choose to use supports more then just on/off
        '.' => [1, @dot_time, 'dot'],
        '-' => [1, @dash_time, 'dash'],
        '_' => [0, @int_gap, 'inter-element gap'],
        '|' => [0, @short_gap, 'short gap'],
        '^' => [0, @med_gap, 'medium gap']
    }

    #pretty print generated morse code
    def self.make_string_p(input)
        translated = '' #string to append to and then return as output

        input.strip.each_char do |char| #strip any potential trailing spaces
            if char == ' ' then 
                translated << char #append space
            elsif @encoder[char] then
                translated << @encoder[char].gsub('_','') #append morse code and strip undscores for pretty(er) printing
            end
        end
        
        return translated #return pretty(er) string
    end

    #the string generator used by the blink sequence generator
    def self.make_string(input)
        translated = '' #same usage as string in above function

        input.strip.each_char do |char| #strip any potential trailing spaces (not sure why I still have that here)
            if @encoder[char] then
                translated << @encoder[char]+'|' #append morse code and short gap between letters to output string
            end 
        end
        
        trimmed = translated.slice(1, translated.length-3) #trim off unnecesary trailing gap characters
        
        if @loop then
            trimmed << '^'
        end

        trimmed.gsub!('_|^|_', '^')

        trimmed.gsub!('_|_', '|')

        return trimmed #return string
    end

    #generates the sequence of brightness values and durations for each one
    def self.sequence(input)
        sequence = [] #instantial array to return

        morse_string = make_string input #string generated by make_string

        morse_string.each_char do |char|
            state = @states[char] #fetch target brightness/on/off state and duration from @states
            sequence << [state[0], state[1], state[2]] #add state info to final array to output
        end

        return sequence # return final output
    end
end

def quit
    begin
        while c = STDIN.read_nonblock(1) do
            if c == 'q' then
                @loop = false
            end
        end
    rescue
    end
end

#check if a message was actualy enterd as the arg
if ARGV.join(' ').strip.empty? then
    puts 'no text to blink entered' #error condition
else
    if @loop then
        sequence = Morse.sequence ARGV.join(' ') #get input string from ARGV and combine substrings

        old_state = IO.read(@light) #read current state before flashing

        while @loop do
            sequence.each do |mode|
                if @log then
                    puts "#{mode[2]} #{mode[0]} for #{mode[1]} seconds" #print brightness values and state duration
                end
                
                IO.write(@light, mode[0]) #write state to light

                quit

                sleep mode[1] #pause for duration
            end
        end

        IO.write(@light, old_state) #reset light to previous state
    else
        sequence = Morse.sequence ARGV.join(' ') #get input string from ARGV and combine substrings

        old_state = IO.read(@light) #read current state before flashing

        sequence.each do |mode|
            if @log then
                puts "#{mode[2]} #{mode[0]} for #{mode[1]} seconds" #print brightness values and state duration
            end
            IO.write(@light, mode[0]) #write state to light
            sleep mode[1] #pause for duration
        end

        IO.write(@light, old_state) #reset light to previous state
    end
end
