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
            hidden: 8,
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
        }.freeze

        ##
        # Reset option constants
        # (Values for `reset` rule option attribute)
        Resets = {
            # Reset everything
            all: 0,
            # Reset foreground color only
            fg: 39,
            # Reset background color only
            bg: 49,
            # Reset style
            style: StyleActions[:disable]
        }.freeze

        ##
        # Operations associated with reset
        ResetOps = [ :reset, :keep ].freeze

        ResetsExtra = [ :style ].freeze

        ##
        # Descriptive aliases for part names
        Parts = {
            # Style applied on rule open
            inside: :inside,
            # Style appled when rule close is given
            after: :after
        }.freeze

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
            reset: Resets.keys,
            # Keep action (opposite of reset)
            keep: Resets.keys
        }.freeze

        ##
        # Normalize rules for ops; either `:keep` to
        # not change original value, or `:array` to
        # wrap single value inside array
        OpNormalize = {
          fg: :keep,
          bg: :keep,
          enable: :array,
          disable: :array,
          reset: :array,
          keep: :array
        }.freeze

        ##
        # Allowed ops by part
        PartOps = {
          inside: [:fg, :bg, :enable, :disable],
          after: [:fg, :bg, :enable, :disable, :reset, :keep]
        }.freeze

        ##
        # Operations allowed within 'after'
        AfterOps = (Ops.filter{|k,v| PartOps[:after].include?(k)}).freeze

        ##
        # Operations allowed within 'inside'
        InsideOps = (Ops.filter {|k,v| PartOps[:inside].include?(k)}).freeze

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
        # @param [RuleSet] rs Rule set
        # @param [Boolean] is_reset Set to true to indicate rule is for reset
        #   operation, and should ignore default after resolution
        # @return [Compiled] Frozen instance of `Compiled` struct
        #   containing compiled rule
        def compile(rule, rs, is_reset=false)
            evaluated = evaluate(rule,rs,is_reset)
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
        # @param [RuleSet] rs Rule set
        # @return [Hash] evaluated version of rule, containing code numbers
        def evaluate(rule, rs, is_reset)
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
            after_part = rule.fetch(after_part_key, {})

            # Resolve after, either from template mixed with any
            # overrides or an automatically generated version mixed with
            # overrides
            if rs.default_after == :auto
                after_part = build_auto_after(inside_part, after_part)
            else
                after_part = override_after(after_part, rs.default_after)
            end

            parts = {}

            parts[inside_part_key] = evaluate_ops(inside_part)
            parts[after_part_key] = evaluate_ops(after_part)

            return parts.merge({evaluated: true})
        end

        def normalize_part(hash,part,clean=false)
            h = hash.dup
            PartOps[part].each do |o|
              if OpNormalize[o] == :array
                h[o] = [h.fetch(o,[])].flatten
              else
                h[o] = h.fetch(o,nil)
              end
            end
          
            if clean
              h = h.filter {|k,v| (v.is_a?(Array))? v.length > 0 : !v.nil? }
            end
          
            return h
          end
          
          def override_after(override, after)
            c_ovr = normalize_part(override, :after)
            c_aft = normalize_part(after, :after)
          
            # change reset :all to specific resets
            if c_aft[:reset].include?(:all)
              c_aft[:reset] = Resets.keys - [:all]
            end
            # change keep :all to specific resets
            if c_ovr[:keep].include?(:all)
              c_ovr[:keep] = Resets.keys - [:all]
            end
          
            c_aft[:reset] = (c_aft[:reset] + c_ovr[:reset]).uniq
            # remove keeps from resets
            c_aft[:reset] -= c_ovr[:keep]
          
            # clear disable if keep :style
            if c_ovr[:keep].include?(:style) ||
              c_aft[:disable] = []
            end
          
            # if override disables styles, remove blanket style reset
            if c_ovr[:disable].length >= 1
              c_aft[:reset] -= [:style]
            end
          
            # prevent enables from conflicting with disables
            en = (c_aft[:enable] + c_ovr[:enable] - c_ovr[:disable])
            di = (c_aft[:disable] + c_ovr[:disable] - c_ovr[:enable])
          
            en -= di
            di -= en
          
            result = { enable: en, disable: di, reset: c_aft[:reset] }
            ColorTargets.keys.each do |k|
              val = (c_ovr[k] || c_aft[k])
              result[k] = val unless val.nil?
            end
          
            return normalize_part(result, :after, true)
          
          end
          
          def build_auto_after(inside, after={})
            c_inside = normalize_part(inside, :inside)
            n_after = normalize_part({}, :after)
          
            if c_inside[:enable].length > 0
              n_after[:reset] += [:style]
            end
          
            ColorTargets.keys.each do |k|
              if !c_inside[k].nil?
                n_after[:reset] += [k]
              end
            end
          
            override_after(after, n_after)
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
