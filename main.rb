require 'ruby2d'
require 'stringio'

set title: "Ruby Pseudo CLI"
set background: 'black'
set width: 800
set height: 600

FONT_SIZE = 20
PROMPT = "  > "
LINE_HEIGHT = FONT_SIZE + 4
MAX_LINES = (Window.height / LINE_HEIGHT).floor

$buffer = ["", "  Welcome to Ruby Pseudo CLI", "  Type Ruby code and press Enter to execute", ""]
$input = ""
$text_objects = []
$shift_pressed = false
$scroll_offset = 0

def update_display
  $text_objects.each(&:remove)
  $text_objects.clear

  total_lines = $buffer.size + 1  # +1 for the input line
  if total_lines > MAX_LINES
    start_index = [total_lines - MAX_LINES - $scroll_offset, 0].max
    visible_lines = $buffer[start_index, MAX_LINES - 1]
  else
    visible_lines = $buffer
  end

  visible_lines.each_with_index do |line, i|
    $text_objects << Text.new(
      line,
      x: 10, y: i * LINE_HEIGHT,
      size: FONT_SIZE,
      color: 'green'
    )
  end

  current_line = "#{PROMPT}#{$input}"
  $text_objects << Text.new(
    current_line,
    x: 10, y: (visible_lines.size * LINE_HEIGHT),
    size: FONT_SIZE,
    color: 'white'
  )
end

def execute_ruby(code)
  begin
    old_stdout = $stdout
    $stdout = StringIO.new
    result = eval(code)
    output = $stdout.string
    $stdout = old_stdout
    output = result.inspect if output.empty?
    output.split("\n").map { |line| "  #{line}" }  # Add two spaces to each line
  rescue => e
    ["  Error: #{e.message}"]  # Also add two spaces to error messages
  end
end

SHIFT_MAP = {
  '1' => '!', '2' => '@', '3' => '#', '4' => '$', '5' => '%',
  '6' => '^', '7' => '&', '8' => '*', '9' => '(', '0' => ')',
  '-' => '_', '=' => '+', '[' => '{', ']' => '}', '\\' => '|',
  ';' => ':', "'" => '"', ',' => '<', '.' => '>', '/' => '?',
  '`' => '~'
}

on :key_down do |event|
  case event.key
  when 'backspace'
    $input.chop!
  when 'return'
    $buffer << "#{PROMPT}#{$input}"
    result = execute_ruby($input)
    $buffer += result
    $buffer << ""  # Add a blank line after the result
    $input = ""
    $scroll_offset = 0  # Reset scroll offset when new content is added
  when 'space'
    $input << ' '
  when 'left shift', 'right shift'
    $shift_pressed = true
  when 'up'
    $scroll_offset = [$scroll_offset + 1, [$buffer.size - MAX_LINES + 1, 0].max].min
  when 'down'
    $scroll_offset = [$scroll_offset - 1, 0].max
  else
    if event.key.length == 1
      if $shift_pressed
        if SHIFT_MAP.key?(event.key)
          $input << SHIFT_MAP[event.key]
        else
          $input << event.key.upcase
        end
      else
        $input << event.key
      end
    end
  end
  update_display
end

on :key_up do |event|
  if event.key == 'left shift' || event.key == 'right shift'
    $shift_pressed = false
  end
end

update_display

show