#!/usr/bin/env ruby
# encoding: UTF-8
require 'open3'
require 'optparse'
require 'ostruct'
####################################################################
# This small library was written to resize all png and jpeg
# images inside a directory. Just require 'resizer.rb' and
# provide the path as an argument when used within an application.
#
# ==== Example if using inside a ruby application
#
#   resizer = Resize::ImageMagick.new
#   resizer.find_and_resize!(<path-to-image-directory>)
#
#
# ==== Example for using via command line
#
#   ruby resizer.rb --path <path-to-image-directory>
#
####################################################################

class ResizeError < StandardError; end
class NotResizeTool < StandardError; end
class NoPathSpecified < StandardError; end

# The handlers used for modification of image
# files. We can add extra, or custom libraries.
#
# Ideally these handlers would be written independent of the Resize
# module and using include, included into the Resize module
# adding additional handlers to existing Resize module.
#
# We could create a directory containing the new handlers and using
# Ruby's meta-programming features iterate over each file inside the
# directory and include them automatically
#
# We would need to implement an interface for each of the handlers
# so there is always only one method to be called and that method
# must be implemented in any new handlers added to the directory.
TOOLS = [
  'ImageMagick',
  'SomeOtherTool' # You get the idea?
]

# Re-factoring can be accomplished by creating an array
# of directories which can never be accessed
#
# A white & black list
ALLOWED_DIRS = [
  # Add allowed directories
]

#--
# the Resize module
module Resize
  # Resize module
  #
  # We would like to be able to grow with different types of `handlers`
  # allowing other developers to add their own handler to the Resize module.
  #
  #
  # Just an example --
  #
  # Of course we would use include to add extra handlers into the
  # Resize module along with any other tools we need.
  #
  # The key is to make it maintainable, allow to easily grow
  # and complete decoupling and simplicity at it's core.
  class SomeOtherTool
  end

  # Use ImageMgick to process the images
  #
  # -- To use within an application
  #
  #   require 'resizer.rb'
  #   resizer = Resize::ImageMagick.new
  #   resizer.find_and_resize!(path)
  #
  # or
  #
  # -- To use via command line
  #
  #   ruby resize.rb -p <path>
  #   ruby resize.rb --path <path>
  #
  class ImageMagick
    # stores the extensions
    attr_accessor :extensions

    # The formats we will be looking for
    #
    # We can re-factor this to use a Format class
    # and include the formats into the Resize module.
    #
    # Each format class will follow and interface
    VALID_FORMATS = [
      'jpg',
      'jpeg',
      'png'
    ]

    def initialize
      # extensions will contain the extensions of the
      # file files we check; valid extensions are set in VALID_FORMATS
      self.extensions = []
    end

    # One public method for each handler
    #
    # Takes `path` as a single parameter and will send
    # check_and_resize_images(path) to the ImageMagick class
    def find_and_resize!(path)
      check_and_resize_images(path)
    end

  private

    def resize!(path)
      begin
        # this will only iterate over the extensions we have
        # stored in extensions, and only resize the files with valid extensions
        # which have been checked by check_and_resize_images()
        extensions.each do |ext|
          begin
            output, err, status = Open3.capture3("mogrify -resize 50% -format 'resized.#{ext[:name]}' #{path}/*.#{ext[:name]}")
            raise ResizeError, err unless status.success?
          rescue ResizeError => e
            puts e.message
            exit! true
          end
        end
        # exit after resize
        exit! true
      rescue StandardError => e
        puts e.message
        exit! true
      end
    end

    # is it an image we're going to resize
    # or is it something else... who knows?
    def image?(src)
      !File.directory?(src)
    end

    # Checks the images in specified directory.
    # Will only validate the image formats specified in VALID_FORMATS
    def check_and_resize_images(path)
      # We don't want to modify the path so create
      # a temporary glob path and retain the original
      #
      # Just a simple hack to allow us to pass `path` to
      # the resize! method at the end of this method.
      glob_path = path
      glob_path += '/**/*'

      # Check the images before including the extensions
      # into the extensions attribute
      Dir.glob(glob_path) do |img|
        if image?(img)
          # get the extension of the file and making sure it is
          # included in the formats we have required to be valid
          ext = File.extname(img).gsub('.', '').downcase

          # This could be improved
          if VALID_FORMATS.map { |format| format.downcase }.include?(ext)
            extension = { name: ext }
            self.extensions << extension unless self.extensions.include?(extension)
          end
        end
      end

      # only resize if there are any files
      resize!(path) unless extensions.empty?
    end

  end
end

# -- Command line
#
# Only run the following code when this file is the main file being run
# instead of having been required or loaded by another file
if __FILE__ == $0

USAGE = <<ENDUSAGE
Usage:

  To use resizer in a ruby application simply include it into your project:

      require 'resizer.rb'

      sizer = Resize::<Tool>.new
      sizer.find_and_resize!(<path to images>)

  Or to use it via command line:

      ruby resize.rb [-p <path to images>] --path <path to images>
ENDUSAGE

HELP = <<ENDHELP

  Help information:

      -h, --help       Show help.
      -p, --path       Specify the path to the directory containing the images

ENDHELP

  # We build our options to pass to the script
  #
  # We can add to this, for example we could add tool to use,
  # what size we should resize to, the directory to put the resized file.
  #
  # Passing options can allow us to customize the script for more use when
  # it is required in the future.
  begin
    options = OpenStruct.new
    OptionParser.new do |opt|
      opt.on('-h') { |o| options.help = o }
      opt.on('--help') { |o| options.help = o }
      opt.on('-p directory containing the images') { |o| options.path = o }
      opt.on('--path directory containing the images') { |o| options.path = o }
    end.parse!
  rescue OptionParser::MissingArgument => e
    # skip and let the options check take care of letting the
    # user know what to do next
  rescue OptionParser::InvalidOption => e
    puts e.message
    exit! true
  end

  # Check if the --path option is specified
  # if not raise NoPathSpecified error
  begin
    if !options.help and options.path.nil?
      raise NoPathSpecified, "You must specify --path"
    end
  rescue NoPathSpecified => e
    puts e.message
    exit! true
  end

  # Options check
  if options.help
    puts USAGE
    puts
    puts HELP if options.help
    exit! true
  end

  # Begin processing the image
  unless options.path.nil?
    # We can add the --tool option if we wanted to
    # for now we will set it as ImageMagick
    #
    #   TOOL = options.tool
    TOOL = 'ImageMagick'

    # We can if we wanted to, add other options
    # For now we'll just take the path
    #
    # We need to make sure that the parameter they are passing in
    # is not a system command and is actually a directory as we are
    # using eval to execute a string as Ruby code
    #
    # We can add a check to make sure a white-list of commands are
    # only allowed and apply the check
    # Leave that out for brevity
    begin
      # Check the tool passed as argument is a valid tool
      unless TOOLS.include?(TOOL)
        raise NotResizeTool, "You must pass a valid tool option, read the help for the available tools"
      end
    rescue  NotResizeTool => e
      puts e.message
      exit! true
    end

    # Take the path from the option provided
    directory = options.path

    # First scan the directory we're looking for
    # and make sure it's a directory
    begin
      # if the file is not a directory end the script
      # and exit without resizing
      unless File.directory? directory
        raise ResizeError, "Is not a directory"
      end
      # Collect and resize the images using the Resize::<tool> class
      tool = eval("Resize::#{TOOL}.new")
      tool.find_and_resize!(directory)
    rescue ArgumentError => e
      puts e.message
    rescue ResizeError => e
      puts "#{e.message} - please specify a directory"
      exit! true
    end
  end
end
