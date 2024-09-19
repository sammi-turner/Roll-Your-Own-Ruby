#!/usr/bin/env ruby

require 'ruby2d'
require 'stringio'

set title: "RYOR Shell"
set background: 'navy'
set width: 800
set height: 600

FONT_SIZE = 18
PROMPT = "  > "
LINE_HEIGHT = FONT_SIZE + 4
MAX_LINES = (Window.height / LINE_HEIGHT).floor

$buffer = ["", "  WELCOME TO THE RYOR SHELL", ""]
$input = ""
$cursor_pos = 0  # New variable to track cursor position
$text_objects = []
$shift_pressed = false
$cursor_visible = true
$cursor_blink_time = 0
$command_history = []
$history_pointer = -1

SHIFT_MAP = {
  '1' => '!', '2' => '@', '3' => '#', '4' => '$', '5' => '%',
  '6' => '^', '7' => '&', '8' => '*', '9' => '(', '0' => ')',
  '-' => '_', '=' => '+', '[' => '{', ']' => '}', '\\' => '|',
  ';' => ':', "'" => '"', ',' => '<', '.' => '>', '/' => '?',
  '`' => '~'
}

def update_display
  $text_objects.each(&:remove)
  $text_objects.clear

  visible_lines = $buffer.last(MAX_LINES - 1)

  visible_lines.each_with_index do |line, i|
    $text_objects << Text.new(
      line,
      x: 10, y: i * LINE_HEIGHT,
      size: FONT_SIZE,
      color: 'teal'
    )
  end

  current_line = "#{PROMPT}#{$input}"
  cursor_indicator = $cursor_visible ? "_" : " "
  current_line = current_line.insert($cursor_pos + PROMPT.length, cursor_indicator)
  $text_objects << Text.new(
    current_line,
    x: 10, y: (visible_lines.size * LINE_HEIGHT),
    size: FONT_SIZE,
    color: 'silver'
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

def update_cursor
  $cursor_blink_time += 1
  if $cursor_blink_time >= 30  # Adjust this value to change blink speed
    $cursor_visible = !$cursor_visible
    $cursor_blink_time = 0
    update_display
  end
end

on :key_down do |event|
  case event.key
  when 'backspace'
    if $cursor_pos > 0
      $input.slice!($cursor_pos - 1)
      $cursor_pos -= 1
    end
  when 'return'
    unless $input.strip.empty?
      $command_history << $input
      $history_pointer = -1
    end
    $buffer << "#{PROMPT}#{$input}"
    result = execute_ruby($input)
    $buffer += result
    $buffer << ""  # Add a blank line after the result
    $input = ""
    $cursor_pos = 0
  when 'space'
    $input.insert($cursor_pos, ' ')
    $cursor_pos += 1
  when 'left shift', 'right shift'
    $shift_pressed = true
  when 'up'
    if $history_pointer < $command_history.size - 1
      $history_pointer += 1
      $input = $command_history[$command_history.size - 1 - $history_pointer]
      $cursor_pos = $input.length
    end
  when 'down'
    if $history_pointer > -1
      $history_pointer -= 1
      $input = $history_pointer == -1 ? "" : $command_history[$command_history.size - 1 - $history_pointer]
      $cursor_pos = $input.length
    end
  when 'left'
    $cursor_pos -= 1 if $cursor_pos > 0
  when 'right'
    $cursor_pos += 1 if $cursor_pos < $input.length
  else
    if event.key.length == 1
      char = $shift_pressed ? (SHIFT_MAP[event.key] || event.key.upcase) : event.key
      $input.insert($cursor_pos, char)
      $cursor_pos += 1
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

update do
  update_cursor
end

show