# resizer
Resizes images using ImageMagick 6.9

# Usage

  To use resizer in a ruby application simply include it into your project:
			
```ruby
require 'resizer.rb'

sizer = Resize::ImageMagick.new
sizer.find_and_resize!(<path to images>)
````
  Or to use it via command line:

`ruby resize.rb [-p <path to images>] --path <path to images>`

# Help information

      -h, --help       Show help.
      -p, --path       Specify the path to the directory containing the images
