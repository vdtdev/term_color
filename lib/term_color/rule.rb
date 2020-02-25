module TermColor
    ##
    # Rule processor
    # @example Basic Rule
    #   # Foreground color set to blue
    #   # Underline style turned on
    #   # Not broken into `a:` and `z:`, so rules will
    #   # be treated as `a:`, `z:` will be auto-generated
    #   # to reset forground color and disable underline
    #   rule = { fg: :blue, enable: :underline }
    # @example Full after reset
    #   # Insize: (`a:`) Foreground yellow, bg red, dark style on
    #   # After: Resets all color and style options to default,
    #   # including those set by other rules
    #   rule = { 
    #       a: {
    #           fg: :yellow, bg: :red, enable: :dark 
    #       },
    #       z: {
    #           reset: :all
    #       }
    #  }
    # @example Italic red, only clearing color at end
    #   # Inside: red fg, italic style
    #   # After: color will reset to default, italic will remain on
    #   rule = { a: { fg: :red, enable: :italic }, z: { reset: :fg }}
    # @author Wade H. <vdtdev.prod@gmail.com>
    # @license MIT
    module Rule
        extend self

        ##
        # Rule color constants
        Colors = {
            black: 0,
            red: 1,
            green: 2,
            yellow: 3,
            blue: 4,
            magenta: 5,
            cyan: 6,
            white: 7
        }

        ##
        # Color modes (added to color values to target fg/bg)
        #
        # Used to determine what props can be used accepting colors
        ColorModes = { fg: 30, bg: 40 }

        ##
        # Advanced color value options. Can be used as key name in hash value
        # passed to fg or bg to use advanced color modes
        ColorsAdvanced = {
            # ANSI 256 color mode (expects value to be integer color)
            # Use like: `{c256: 308}`
            c256: :color_256,
            # ANSI 16m color mode (expects value to be array of integers [r,g,b])
            # Use like: `{c16m: [25,30,25]}`
            c16m: :color_16m
        }

        ##
        # Style option constants
        Styles = {
            bold: 1,
            intense: 1,
            dark: 2,
            italic: 3,
            underline: 4,
            inverse: 7,
            strikethrough: 9
        }

        ##
        # Styke modes (values added to style values)
        #
        # Used to determine what props can accept styles
        StyleModes = { enable: 0, disable: 20 }

        ##
        # Options for `reset:`
        Resets = {
            # Reset everything
            all: 0,
            # Reset foreground color only
            fg: 39,
            # Reset background color only
            bg: 49
        }

        ##
        # Descriptive aliases for part names
        Parts = {
            # Style applied on rule open
            before: :a,
            # Style appled when rule close is given
            after: :z
        }

        ##
        # Valid rule operations mapped to accepted const values
        # (colors [fg, bg] can also accept integers)
        Ops = {
            # Foreground color
            fg: Colors.keys,
            # Background color
            bg: Colors.keys,
            # Enable style(s)
            enable: Styles.keys,
            # Disable style(s)
            disable: Styles.keys,
            # Resets
            reset: [:fg, :bg, :style, :all]
        }

        ##
        # Evaluate rule, returning new hash containing list of numerical
        # codes to use for before (`:a`) and after (`:z`)
        # @param [Hash] rule Rule hash to evaluate
        # @return [Hash] evaluated version of rule, containing code numbers
        def evaluate(rule)
            # error if not hash
            return nil if !rule.is_a?(Hash)

            before_part_key = Parts[:before]
            after_part_key = Parts[:after]
            
            before_part = {}; after_part = {}

            rule_keys = rule.keys.map{|k|k.to_sym}                
            if !rule_keys.include?(before_part_key) && !rule_keys.include?(after_part_key)
                before_part = rule
            else
                before_part = rule.fetch(before_part_key, {})
                after_part = rule.fetch(after_part_key, {})
            end

            # Attempt to auto-generate 'after' rules if 'before' is given but
            # no 'after' is. Auto includes resets for used bg/fg if used
            # and disable for any enabled styles
            if before_part.keys.length > 0 && after_part.keys.length == 0
                resets = before_part.keys.filter{|k| ColorModes.keys.include?(k) }
                disables = before_part.fetch(:enable, [])
                
                after_part[:reset] = resets if resets.length > 0
                after_part[:disable] = disables if disables.length > 0
            end

            parts = {}

            parts[before_part_key] = evaluate_ops(before_part)
            parts[after_part_key] = evaluate_ops(after_part)

            return parts

        end
        
        ##
        # Return ANSI color codes from evaluated rule
        # @param [Hash, Array] rule Full rule or part (Array)
        # @return [Hash, String] If full rule given, Hash with code strings
        #   for `:a` and `:z`, else code string for given array of codes
        def codes(rule)
            code = Proc.new {|c| "\e[#{c}m" }
            if rule.is_a?(Hash)
                {
                    a: rule[:a].map{|c| code.call(c) }.join(''),
                    z: rule[:z].map{|c| code.call(c) }.join('')
                }
            else
                rule.map{|c| code.call(c) }.join('')
            end
        end

        private

        def evaluate_ops(ops)
            codes = []
            v_ops = ops.filter{|k,v| Ops.keys.include?(k.to_sym)}
            color_keys = ColorModes.keys
            style_keys = StyleModes.keys
            reset_keys = Resets.keys
            v_ops.each_pair do |k,v|
                k=k.to_sym
                if color_keys.include?(k)
                    codes << resolve_color(v, k)
                elsif style_keys.include?(k)
                    [v].flatten.each do |val|
                        codes << resolve_style(val, k)
                    end
                elsif k == :reset
                    [v].flatten.each do |val|
                        codes << resolve_reset(val)
                    end
                end
            end
            codes = codes.flatten.compact.uniq
        end                

        def resolve_color(color, mode = :fg)
            if !color.is_a?(Integer)
                if color.is_a?(Hash) && ColorsAdvanced.keys.include?(color.keys[0])
                    return self.method(ColorsAdvanced[color.keys[0]]).call(color.values[0])
                end
                color = Colors[color.to_sym].to_i
            end
            (color + ColorModes[mode.to_sym].to_i)
        end

        def resolve_style(style, state = :enable)
            if !style.is_a?(Integer)
                style = Styles[style.to_sym].to_i
            end
            (style + StyleModes[state.to_sym].to_i)
        end

        def resolve_reset(target)
            if Resets.keys.include?(target.to_sym)
                return Resets[target.to_sym]
            elsif Styles.keys.include?(target.to_sym)
                return resolve_style(target, :disable)
            else
                return nil
            end
        end

        def color_256(val)
            "38;5;#{val}"
        end

        def color_16m(val)
            c = val.join(';')
            "38;2;#{c}"
        end

    end
end