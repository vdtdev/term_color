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
    module Rule
        extend self

        ##
        # Named Standard ANSI Color constants
        # (Basic named values for `fg` and `bg` rule option attributes)
        Colors = {
            black: 0,
            red: 1,
            green: 2,
            yellow: 3,
            blue: 4,
            magenta: 5,
            cyan: 6,
            white: 7
        }.freeze

                ##
        # Numerical modifiers used with Color Values
        # to target foreground or background.
        # 
        # - For {Colors Named Standard Colors}, value is added to given
        #   color's numerical value
        # - For XTerm 256/16m color codes, value is added to mode base
        # 
        # @example Named Standard Color Background
        #   { bg: :red } #=> 40 + 1 = 41
        # @example XTerm 256 Foreground
        #   { fg: [208] } #=> 8 + 30 = 38
        ColorTargets = { 
            fg: 30, # Foreground target
            bg: 40  # Background target
        }.freeze

        ##
        # Style option constants
        # (Values that can be included in style `enable` and `disable` 
        # rule option attributes)
        Styles = {
            bold: 1,
            ##
            # Alias for bold
            intense: 1,
            dim: 2,
            ##
            # Alias for dim
            dark: 2,
            italic: 3,
            underline: 4,
            inverse: 7,
            strikethrough: 9
        }.freeze

        ##
        # Style action codes
        # (Numerical modifiers applied to {Styles Style Codes} to
        # enable/disable them based on which option attribute action
        # was used)
        # @example Disable italic
        #   (:disable) + (:italic) #=> 20 + 3 = 23
        StyleActions = { 
            # Enable style(s) action
            enable: 0,
            # Disable style(s) action
            disable: 20 
        }

        ##
        # Reset option constants
        # (Values for `reset` rule option attribute)
        Resets = {
            # Reset everything
            all: 0,
            # Reset foreground color only
            fg: 39,
            # Reset background color only
            bg: 49
        }.freeze

        ##
        # Descriptive aliases for part names
        Parts = {
            # Style applied on rule open
            inside: :inside,
            # Style appled when rule close is given
            after: :after
        }

        ##
        # Valid rule operations mapped to accepted const values
        # (colors [fg, bg] can also accept integers)
        Ops = {
            # Foreground color option
            fg: Colors.keys,
            # Background color option
            bg: Colors.keys,
            # Enable style(s) action
            enable: Styles.keys,
            # Disable style(s) action
            disable: Styles.keys,
            # Reset action
            reset: [
                :fg,    # Reset fg color 
                :bg,    # Reset bg color
                :style, # Reset all styles
                :all    # Reset colors and styles
            ]
        }

        ##
        # Value added to ColorTarget when using XTerm colors
        XTERM_COLOR_TARGET = 8
        ##
        # Mode constant for XTerm 256 Colors
        XTERM_COLOR_256 = 5
        ##
        # Mode constant for XTerm 16m Colors
        XTERM_COLOR_16M = 2

        ##
        # Structure used to hold compiled rule
        # @!attribute [r] original
        #   Original rule hash
        #   @return [Hash]
        # @!attribute [r] evaluated
        #   Evaluated copy of rule, including generated :after.
        #   Consists of code arrays
        #   @return [Hash]
        # @!attribute [r] rule
        #   Hash of inside and after ANSI code strings
        #   @return [Hash]
        Compiled = Struct.new(:original, :evaluated, :rule) do
            ##
            # Get codes for part of compiled rule
            def codes(part)
                rule[part]
            end
        end

        ##
        # Compile rule into frozen instance of `Compiled` struct
        # @param [Hash] rule Rule hash
        # @return [Compiled] Frozen instance of `Compiled` struct
        #   containing compiled rule
        def compile(rule)
            evaluated = evaluate(rule)
            return Compiled.new(
                rule,
                evaluated,
                codes(evaluated)
            ).freeze
        end

        private

        def evaluate_ops(ops)
            codes = []
            v_ops = ops.filter{|k,v| Ops.keys.include?(k.to_sym)}
            color_keys = ColorTargets.keys
            style_keys = StyleActions.keys
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

        def resolve_color(color, target = :fg)
            if color.is_a?(Array)
                color = color[0..2]
                return xterm_color(color, target)
            end
                
            if !color.is_a?(Integer)
                
                if color.is_a?(Hash) && ColorsAdvanced.keys.include?(color.keys[0])
                    return self.method(ColorsAdvanced[color.keys[0]]).call(color.values[0])
                end
                color = Colors[color.to_sym].to_i
            end
            (color + ColorTargets[target.to_sym].to_i)
        end

        def resolve_style(style, state = :enable)
            if !style.is_a?(Integer)
                style = Styles[style.to_sym].to_i
            end
            (style + StyleActions[state.to_sym].to_i)
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

        def xterm_color(val,target)
            r,g,b = [val].flatten
            if g.nil? && b.nil?
                [
                    ColorTargets[target] + XTERM_COLOR_TARGET,
                    XTERM_COLOR_256,
                    r
                ].join(';')
            else
                [
                    ColorTargets[target] + XTERM_COLOR_TARGET,
                    XTERM_COLOR_16M,
                    r,g,b
                ].join(';')
            end
        end

        ##
        # Evaluate rule, returning new hash containing list of numerical
        # codes to use for inside (`:inside`) and after (`:after`)
        # @param [Hash] rule Rule hash to evaluate
        # @return [Hash] evaluated version of rule, containing code numbers
        def evaluate(rule)
            # error if not hash
            return nil if !rule.is_a?(Hash)

            inside_part_key = Parts[:inside]
            after_part_key = Parts[:after]
            rule_keys = rule.keys.map{|k|k.to_sym}
            
            # Find 'inside' rule options
            if rule_keys.include?(inside_part_key)
                # 'inside' key explicitly defined, so pull from that
                inside_part = rule[:inside]
            else
                # no 'inside' key, so pull from entire hash excluding
                # 'after' key, if present
                inside_part = rule.filter { |k,v| k != after_part_key }
            end

            # Find 'after' rule options, using nil if not present
            # This means that if it is defined but as an empty hash,
            # no 'after' rule options will be auto-generated
            after_part = rule.fetch(after_part_key, nil)

            # Auto-generate 'after' rule options if not explicitly defined
            if after_part.nil?
                resets = inside_part.keys.filter { |k| ColorTargets.keys.include?(k) }
                disables = inside_part.fetch(:enable, [])
                after_part = {}
                after_part[:reset] = resets if resets.length > 0
                after_part[:disable] = disables if disables.length > 0
            end

            parts = {}

            parts[inside_part_key] = evaluate_ops(inside_part)
            parts[after_part_key] = evaluate_ops(after_part)

            return parts.merge({evaluated: true})

        end
        
        ##
        # Return ANSI color codes from evaluated rule
        # @param [Hash] rule Full rule
        # @return [Hash] Hash with code strings for `:inside` and `:after`
        def codes(rule)
            code = Proc.new {|c| "\e[#{c}m" }
            inside = Parts[:inside]
            after = Parts[:after]
            {
                (inside) => rule[inside].map{|c| code.call(c) }.join(''),
                (after) => rule[after].map{|c| code.call(c) }.join('')
            }
        end
    end
end