abstract class Admiral::Command
  private macro inherited
    HELP = {
      "description" => "",
      "overview" => ""
    }

    protected def self.left_col_len
      [
        Flags::SPECS.values.each_with_object({} of String => String) { |spec, obj| obj[spec[:description][0]] = spec[:description][1] },
        Arguments::DESCRIPTIONS,
        SubCommands::DESCRIPTIONS
      ].flat_map(&.keys).map(&.size).sort[-1]? || 0
    end

    protected def puts_help
    end

    private def help_usage
      String.build do |str|
        # Add Usage
        str << "Usage:"
        commands = [] of String
        commands << begin
          String.build do |cmd|
            Arguments::NAMES.each do |attr|
              attr = attr.gsub(/_([A-Z_]+)_/, "\\1")
              cmd << " <#{attr}>"
            end
            cmd << " [arg...]"
          end
        end
        commands.each do |cmd|
          str << "\n  #{@program_name}"
          str << " [flags...]" unless Flags::SPECS.empty?
          str << cmd unless cmd.empty?
        end
        str << "\n"
      end
    end

    private def help_flags
      String.build do |str|
        unless Flags::SPECS.empty?
          str << "Flags:\n"
          Flags::SPECS.values.sort_by { |spec| spec[:long] }.each do |spec|
            string = spec[:description][0]
            desc = spec[:description][1]
            str << "  #{string}"
            if desc.size > 1
              str << " " * (self.class.left_col_len - string.size)
              str << "  # #{desc}"
            end
            str << "\n"
          end
        end
      end
    end

    private def help_arguments
      String.build do |str|
        unless Arguments::NAMES.empty?
          str << "Arguments:\n"
          Arguments::DESCRIPTIONS.each do |string, desc|
            str << "  #{string}"
            if desc.size > 1
              str << " " * (self.class.left_col_len - string.size)
              str << "  # #{desc}"
            end
            str << "\n"
          end
        end
      end
    end

    private def help_sub_commands
      String.build do |str|
        unless SubCommands::NAMES.empty?
          str << "Subcommands:\n"
          SubCommands::DESCRIPTIONS.keys.sort.each do |key|
            string = key
            desc = SubCommands::DESCRIPTIONS[key]
            str << "  #{string}"
            if desc.size > 1
              str << " " * (self.class.left_col_len - string.size)
              str << "  # #{desc}"
            end
            str << "\n"
          end
        end
      end
    end
  end

  macro define_help(custom, description = "", flag = help, short = nil)
    {{ raise "Description too long, limit: 80 chars." if description.stringify.size > 80 }}
    HELP["description"] = {{ description }}
    {% if flag %}
      define_flag __help__ : Bool,
                  description: "Displays help for the current command.",
                  long: {{flag}},
                  short: {{short}}

      protected def puts_help : Nil
        if flags.__help__
          puts help
          exit
        end
      end
    {% end %}

    def help
      {{ custom }}
    end
  end

  # ## Auto-generated Help

  # Adds a help to the command.
  #
  # ```crystal
  # # hello.cr
  # class Hello < Admiral::Command
  #   define_help description: "A command that says hello"
  #   define_argument planet, default: "World"
  #
  #   def run
  #     puts "Hello #{arguments.planet}"
  #   end
  # end
  # ```
  #
  # ```sh
  # $ crystal build ./hello.cr
  # $ ./hello --help
  # Usage:
  #   ./hello [flags...] <planet> [arg...]
  #
  # A command that says hello
  #
  # Flags:
  #   --help
  #
  # Arguments:
  #   planet (default: World)
  # ```
  #
  # ### Custom Help
  # You can also generate your own custom help text.
  #
  # ```crystal
  # # hello.cr
  # class Hello < Admiral::Command
  #   define_help custom: "This is the help for my command"
  #
  #   def run
  #   end
  # end
  # ```
  macro define_help(description = "", flag = help, short = nil)
    define_help(
      [help_usage, {{ description }} + "\n", help_flags, help_arguments, help_sub_commands].reject(&.strip.empty?).join("\n"),
      {{ description }},
      {{ flag }},
      {{ short }}
    )
  end
end
