require 'csv'
require 'fileutils'
require_relative 'term_color'

class Task
  attr_reader :id, :list_id, :name, :created_at, :modified_at
  attr_accessor :selected, :completed_at

  def initialize(options = {})
    @id = options[:id].to_i
    @list_id = options[:list_id].to_i
    @name = options[:name]
    @selected = false
    @completed_at = options[:completed_at]
    @created_at = options.fetch(:created_at, Time.now)
    @modified_at = options.fetch(:modified_at, Time.now)
  end

  def toggle_complete
    if !completed_at
      @completed_at = Time.now
    else
      @completed_at = nil
    end
    update_modified_at
  end

  def toggle_selected
    @selected = !selected
  end

  def to_s
    name
  end

  private

  def update_modified_at
    @modified_at = Time.now
  end

end

class List
  attr_reader :id, :name, :created_at, :modified_at
  attr_accessor :selected

  def initialize(options = {})
    @id = options[:id].to_i
    @name = options[:name]
    @selected = false
    @created_at = options.fetch(:created_at, Time.now)
    @modified_at = options.fetch(:modified_at, Time.now)
  end

  def toggle_selected
    @selected = !selected
  end

  def to_s
    name
  end

  private

  def update_modified_at
    @modified_at = Time.now
  end

end

class ToDoDB
  attr_reader :tasks_filename, :tasks, :tasks_headers, :lists_filename, :lists, :lists_headers

  def initialize(filename)
    @tasks_filename = "#{filename}_tasks.csv"
    @tasks = [nil] # Initializes new array with first element as nil such that task ids start at 0
    @tasks_headers = ["id", "list_id", "name", "completed_at", "created_at", "modified_at"] # Write a method to parse these
    @lists_filename = "#{filename}_lists.csv"
    @lists = [nil] # Initializes new array with first element as nil such that list ids start at 0
    @lists_headers = ["id", "name", "created_at", "modified_at"] # Write a method to parse these
  end

  def import_files
    FileOperations.touch_files(tasks_filename, lists_filename)
    FileOperations.parse_all(tasks, lists, tasks_filename, lists_filename)
  end

  def add_list(list_name)
    id = lists.length
    options = {id: id, name: list_name}
    lists << List.new(options)
  end

  def select_list(list_id)
    lists[list_id].toggle_selected
  end

  def delete_selected_lists
    lists.each do |list|
      if list && list.selected
        lists[list.id] = nil
        delete_list_tasks(list.id)
      end
    end
  end

  def delete_list_tasks(list_id)
    tasks.reject! {|task| task.list_id == list_id if task}
  end

  def pull_list_tasks(list_id)
    tasks.compact.select {|task| task.list_id == list_id}
  end

  def add_task(list_id, name)
    id = tasks.length
    options = {id: id, list_id: list_id, name: name}
    tasks[id] = Task.new(options)
  end

  def select_task(task_id)
    tasks[task_id].toggle_selected
  end

  def complete_selected_tasks
    tasks.each {|task| task.toggle_complete if task && task.selected}
    unselect_all_tasks
  end

  def delete_selected_tasks
    tasks.each_with_index {|task, index| tasks[index] = nil if task && task.selected}
  end

  def delete_task(task_id)
    tasks[task_id] = nil
  end

  def unselect_all
    unselect_all_lists
    unselect_all_tasks
  end

  def unselect_all_lists
    lists.each {|list| list.selected = false if list}
  end

  def unselect_all_tasks
    tasks.each {|task| task.selected = false if task}
  end

  def save_files
    FileOperations.save_all(tasks, lists, tasks_filename, lists_filename, tasks_headers, lists_headers)
  end

end

class FileOperations

  def self.touch_files(*filenames)
    filenames.each {|filename| FileUtils.touch filename}
  end

  def self.parse_all(tasks, lists, tasks_filename, lists_filename)
    parse_tasks(tasks, tasks_filename)
    parse_lists(lists, lists_filename)
  end

  def self.save_all(tasks, lists, tasks_filename, lists_filename, tasks_headers, lists_headers)
    save_tasks(tasks, tasks_filename, tasks_headers)
    save_lists(lists, lists_filename, lists_headers)
  end

  def self.parse_tasks(tasks, tasks_filename)
    CSV.foreach(tasks_filename, headers: true, header_converters: :symbol) do |row_data|
      index = row_data[:id].to_i
      tasks[index] = Task.new(row_data)
    end
  end

  def self.parse_lists(lists, lists_filename)
    CSV.foreach(lists_filename, headers: true, header_converters: :symbol) do |row_data|
      index = row_data[:id].to_i
      lists[index] = List.new(row_data)
    end
  end

  def self.save_tasks(tasks, tasks_filename, headers)
    CSV.open(tasks_filename, 'w', :write_headers => true, :headers => headers) do |csv|
      tasks.each do |task|
        csv << task_csvify(task) if task
      end
    end
  end

  def self.save_lists(lists, lists_filename, headers)
    CSV.open(lists_filename, 'w', :write_headers => true, :headers => headers) do |csv|
      lists.each do |list|
        csv << list_csvify(list) if list
      end
    end
  end

  def self.task_csvify(task) # Need to find a better way to do this
    [task.id, task.list_id, task.name, task.completed_at, task.created_at, task.modified_at]
  end

  def self.list_csvify(list) # Need to find a better way to do this
    [list.id, list.name, list.created_at, list.modified_at]
  end

end

class Display

  def self.main_menu(lists)
    reset_screen!
    header
    all_lists(lists)
  end

  def self.list_menu(list, list_name)
    reset_screen!
    header
    display_list(list, list_name)
  end

  def self.header
    puts "ToDo List".red
    puts
  end

  def self.all_lists(lists)
    puts "All Lists:\n".bold.cyan
    lists.each_with_index do |list, index|
      if list && list.selected
        puts "#{index}. #{list.name}".underline
      elsif list
        puts "#{index}. #{list.name}"
      end
    end
    puts "It looks like you don't have any lists yet!" if lists.length == 1
  end

  def self.display_list(list, list_name)
    puts "List: #{list_name}:\n".bold.yellow
    puts "It looks like you don't have anything on your list yet!" if list.length == 0
    list.each_with_index do |task, index|
      task(task, index)
    end
  end

  def self.task(task, index)
    output = "#{index + 1}."
    output += " " if index < 9
    output += "["
    if task.completed_at
      output += "X"
    else
      output += " " unless task.completed_at
    end
    output += "] "
    output += "#{task}"
    if task.completed_at && task.selected
      puts output.thin.underline
    elsif task.completed_at
      puts output.thin
    elsif task.selected
      puts output.underline
    else
      puts output
    end
  end

  def self.user_prompt(cmd = nil)
    print "#{cmd}> "
  end

  def self.reset_screen!
    clear_screen!
    move_to_home!
  end

  private

  def self.input_helper(menu_symbol)
    puts
    case menu_symbol
    when :main_menu
      puts "Commands:".blue
      print "a => add list, ".blue
      print "s => toggle-select list, ".blue
      print "q => quit".blue
    when :list_menu
      puts "Commands".blue
      print "a => add task, ".blue
      print "s => toggle-select task, ".blue
      print "c => complete selected tasks, ".blue
      print "d => delete selected tasks, ".blue
      print "b => back to main menu".blue
    when :add_list
      puts
      print "Enter name for your list:".blue
    when :select_list
      puts
      print "Enter a list number:".blue
    when :add_task
      puts
      print "Enter a name for your task:".blue
    when :select_task
      puts
      print "Enter a task number:".blue
    end
    puts
  end

  def self.clear_screen!
    print "\e[2J"
  end

  def self.move_to_home!
    print "\e[H"
  end

end

class ToDo
  attr_reader :database, :current_list, :current_list_tasks, :cmd

  def initialize(filename)
    @database = ToDoDB.new(filename)
    @current_list = nil
    @current_list_tasks = nil
    @cmd = nil
    main_menu
  end

  private

  def main_menu
    database.import_files
    until user_input_quit?
      Display.main_menu(database.lists)
      Display.input_helper(:main_menu)
      cmd_input_prompt
      evaluate_cmd(:main_menu)
      database.save_files
    end
    Display.reset_screen!
  end

  def list_menu(list_id)
    database.unselect_all
    until user_input_back?
      @current_list = database.lists[list_id]
      @current_list_tasks = database.pull_list_tasks(list_id)
      Display.list_menu(current_list_tasks, current_list.name)
      Display.input_helper(:list_menu)
      cmd_input_prompt
      evaluate_cmd(:list_menu)
      database.save_files
    end
    database.unselect_all
  end

  def cmd_input_prompt
    @cmd = $stdin.gets.chomp
  end

  def evaluate_cmd(menu_symbol)
    case menu_symbol
    when :main_menu
      case cmd
      when "quit", "q"
        return
      when "add", "a"
        add_list
      when "select", "s"
        select_list
      when "delete", "d"
        database.delete_selected_lists
      else
        list_id = cmd.to_i
        list_menu(list_id) if valid_list?(list_id)
      end
    when :list_menu
      case cmd
      when "back", "b"
        return
      when "add", "a"
        add_task
      when "select", "s"
        select_task
      when "completed", "c"
        database.complete_selected_tasks
      when "delete", "d"
        database.delete_selected_tasks
      end
    end
  end

  def add_list
    Display.main_menu(database.lists)
    Display.input_helper(:add_list)
    Display.user_prompt("add")
    list_name = $stdin.gets.chomp
    database.add_list(list_name)
  end

  def add_task
    Display.list_menu(current_list_tasks, current_list.name)
    Display.input_helper(:add_task)
    Display.user_prompt("add")
    task_name = $stdin.gets.chomp
    database.add_task(current_list.id, task_name)
  end

  def select_list
    Display.main_menu(database.lists)
    Display.input_helper(:select_list)
    Display.user_prompt("select")
    list_id = $stdin.gets.chomp.to_i
    if valid_list?(list_id)
      database.select_list(list_id)
    end
  end

  def select_task
    Display.list_menu(current_list_tasks, current_list.name)
    Display.input_helper(:select_task)
    Display.user_prompt("select")
    task_number = $stdin.gets.chomp.to_i
    if valid_task?(task_number)
      task_id = current_list_tasks[task_number - 1].id
      database.select_task(task_id)
    end
  end

  def valid_list?(list_id)
    list_id.between?(1, database.lists.length - 1)
  end

  def valid_task?(task_number)
    task_number.between?(1, current_list_tasks.length)
  end

  def user_input_quit?
    cmd == "quit" || cmd == "q"
  end

  def user_input_back?
    cmd == "back" || cmd == "b"
  end

end

if ARGV.any?
  filename = ARGV[0]
  ToDo.new(filename) # Accepts existing file or new filename as an argument
else
  ToDo.new("example_todo") # Runs my_todo by default if no filename is specified as argument
end
