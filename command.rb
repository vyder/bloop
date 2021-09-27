#!/usr/bin/env ruby

require 'FileUtils'
require 'yaml'

CONFIG_DIRNAME = '.blooprc'
CONFIG_PATH = File.expand_path(CONFIG_DIRNAME, "~")
CONFIG_FILENAME = File.expand_path('config.json', CONFIG_PATH)

HELP_FILENAME  = File.expand_path('../help.txt', __FILE__)
DEFAULT_CONFIG = YAML.load_file(File.expand_path('../defaultConfig.yml', __FILE__))

unless Dir.exists? CONFIG_PATH
    FileUtils.mkdir_p CONFIG_PATH
    FileUtils.touch CONFIG_FILENAME
end

CONFIG = YAML.load_file(CONFIG_FILENAME) || DEFAULT_CONFIG
CONFIG['templates'] ||= {}

def print_help_and_exit
    puts File.read(HELP_FILENAME)
    exit 0
end

if ARGV[0] === '--help'
    print_help_and_exit

elsif ARGV[0] === '--list'
    templates = CONFIG['templates'].keys

    puts "\nAvailable Templates:"
    if templates.empty?
        puts "  (No templates registered yet)"
    else
        output = "  - #{templates.join("\n  - ")}"
        puts output
    end
    exit 0

elsif ARGV[0] === '--register'
    template_path = ARGV[1]
    template_name = ARGV[2]
    type = ARGV[4]
    template_path = File.expand_path(template_path, Dir.pwd)

    unless File.exists?(template_path) || Dir.exists?(template_path)
        puts "ERROR: Template Path not found: #{template_path}"
        puts "Run `bloop help` for more info"
        exit 1
    end

    template = {
        name: template_name,
        type: type,
        path: template_path,
    }
    CONFIG['templates'][template_name] = template

    puts "Created template '#{template[:name]}':"
    pp template
else
    possible_template_name = ARGV[0]
    template = CONFIG['templates'][possible_template_name]
    if !template || template.nil?
        puts "ERROR: Unknown Template Name '#{possible_template_name}'"
        puts "Run `bloop help` for more info"
        exit 1
    elsif !template[:type] || !CONFIG['types'][template[:type]]
        puts "ERROR: Template type not found '#{template[:type]}'"
        exit 1
    else
        destination_input = ARGV[1] || template[:name]
        destination = File.expand_path(destination_input, Dir.pwd)

        if File.exists?(destination) || Dir.exists?(destination)
            puts "ERROR: Destination path already exists: #{destination}"
            exit 1
        end

        # Create dest dir
        FileUtils.mkdir_p destination

        type_config = CONFIG['types'][template[:type]]
        ignore_list = type_config['ignore'] || ['.git']

        # Loop through each of source files/dirs
        source_files = Dir.glob("#{template[:path]}/*", File::FNM_DOTMATCH)
        source_files.each do |source|
            basename = File.basename(source)
            next if basename === '.' || basename === '..'
            next if ignore_list.include? basename

            target = File.expand_path(basename, destination)
            FileUtils.cp_r(source, target)
        end

        sample_env = File.expand_path('sample.env', destination)
        dotenv     = File.expand_path('.env', destination)
        if File.exists?(sample_env) && !File.exists?(dotenv)
            FileUtils.cp(sample_env, dotenv)
        end

        current_dir = Dir.pwd
        FileUtils.cd destination

        %x(git init)
        %x(git add .)
        %x(git commit -m "Generated from blueprint '#{template[:name]}'")

        if template[:type] === 'node'
            %x(npm i)
        end

        FileUtils.cd current_dir
    end
end

File.open(CONFIG_FILENAME, "w+") { |f| f.write(CONFIG.to_yaml) }
