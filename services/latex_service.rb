require 'mathematical'
require 'mini_magick'

class LatexService

  def self.render?(message, path, file)
    # stripping it so you cant just put in one letter or a string of backslashs
    return false if message.strip.length == 1 || message.strip == '\\' * message.length

    # return a png
    # pixels per inch is 300
    renderer = Mathematical.new(format: :png, ppi: 300.0)

    # renders the image but it needs to be cleaned
    dirtyFile = renderer.render("$ #{message} $")
    
    # puts that image into mini_magick to be cleaned
    # change the background to white instead of alpha
    # trim so not a ton of space around
    # add a black border if i can figure that out
    cleanFile = MiniMagick::Image.read(dirtyFile[:data])


  end

  # renders the message
  def self.render?(message, path, file)
    # stripping it so you cant just put in one letter or a string of backslashs
    return false if message.strip.length == 1 || message.strip == '\\' * message.length

    write2file(message, path, file)

    # latex in nonstopmode so if error it just quits
    # put output into /dev/null gets rid of output
    did_comp = system("latex -interaction=nonstopmode -output-directory=#{path} #{File.join(path, file)}.tex >>/dev/null")

    # changes the .dvi to .png 
    # -q* makes it quiet
    # -D is resolution or "density" 
    # -T is image size
    # -o is output file
    return false unless did_comp
    system("convert -density 300 -flatten #{File.join(path, file)}.dvi #{File.join(path, file)}.png >>/dev/null")
  end

  # writes the message to the file
  def self.write2file(message, path, file)
    # reading the template file
    template = File.read(File.join(path, 'template.tex'))

    # changing the file template and writing it to a new file
    File.open(File.join(path, file + '.tex'), 'w') do |outfile|
      outfile.puts template.gsub('__DATA__', message)
    end
  end

  # deletes the extra files
  def self.cleanup(path, file)
    # these are the files that are created
    file_endings = ['.aux', '.log', '.dvi', '.png', '.tex']
    file_endings.each do |fending|
        File.delete(File.join(path, file + fending)) if File.exist? (File.join(path, file + fending))
    end
    # have to return nil or something will be send as a message
    nil
  end

  # sanitizes the message by putting a backslash in front of some chars
  def self.sanitize(message)
    # these are restricted commands
    # commands need to end with a { or it will match all commands that start with it
    # \text because it can let people put text in math mode and bog down it system
    # \text is replaced with \backslash text
    res_commands = [['\\text{', '\\backslash text~{']]
    res_commands.each do |res, replace|
      message = message.gsub(res, replace)
    end

    # each symbol is a different one that could cause problems
    # $ is to enter/exit math mode which would cause compilation problems
    # \\ is obvious
    # " could cause an escape of the latex function
    res_chars = ['$', '\\', '"']
    res_chars.each do |res|
      message = message.gsub(res, "\\#{res}")
    end
    message
  end
end
