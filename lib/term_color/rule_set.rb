module TermColor
    ##
    # TermColor style rule setc class
    # @author Wade H. <vdtdev.prod@gmail.com>
    # @license MIT
    class RuleSet

        DBG = false

        ##
        # Default rule symbols
        DEFAULT_SYMBOLS = {
          open: '{%',
          close: '%}',
          reset: '%@'
        }.freeze

        ##
        # Default reset rule
        DEFAULT_RESET_RULE = {after: {reset: :all} }.freeze

        ##
        # After preset options
        AFTER_PRESETS = {
          # Full reset
          reset: {reset: :all},
          # Automatically determine what to toggle off
          auto: :auto,
          # No reset
          keep: {keep: :all}
        }

        ##
        # Struct for rule and reset symbols
        SymbolOptions = Struct.new(:open,:close,:reset)

        ##
        # Default after preset choice
        DEFAULT_AFTER = :auto

        attr_reader :rules, :regexs, :default_after, :symbols

        ##
        # Construct new rule set
        # @param [Hash] rules Hash of rule names mapping to rule hashes,
        #   which can define before rules (`inside:`), after rules (`after:`) or both.
        #   - If neither are given, content is treated as though it was inside a `inside:` key.
        #   - If `inside:` only is given, {TermColor::Rule#evaluate Rule evaluate method} attempts to
        #       auto guess `after:`, resetting any used color or style rules from `inside:`
        # @param [Hash] opts Optional arguments
        # @option opts [Hash|Symbol] :after Override default `:after` rule behavior when rule has no `after:`
        #   Options:
        #   - `:reset` - Reset all color and styles
        #   - `:auto` (default) - Try to automatically determine what to reset based on applied colors/styles
        #   - `:keep` - Keel all rule styles intact
        #   - (`Hash`) - Custom rule (formatted as Rule `after` prop, e.g. `{ reset: :fg, keep: :style }`)
        # @option opts [Hash] :symbols Override styling symbols
        #   Options:
        #   - `:open` - Rule open symbol (used as symbolRulename) (default `{%`)
        #   - `:close` - Rule close symbol (default `%}`)
        #   - `:reset` - Symbol that can be used between rule blocks to fully reset everything (default `%@`)
        # @see TermColor::Rule
        # @example
        #   rules = RuleSet.new({
        #       # Green underlined text; will auto reset fg and disable underline
        #       # for close, since no z: is provided
        #       name: {fg: :green, enable: :underline},
        #       # Italic text; will auto generate z: that disables italic
        #       quote: { enable: :italic },
        #       # A weird rule that will make fg red inside rule,
        #       # and change fg to blue after rule block ends
        #       weird: { inside: { fg: :red }, after: { fg: :blue }}
        #   })
        #
        #   print rules.colorize("{%nameJohn%}: '{%quoteRoses are {%weirdRed%} (blue)%}.\n")
        #   # Result will be:
        #   #   fg green+underline "John"
        #   #   regular ":  "
        #   #   italic "Roses are "
        #   #   fg red (still italic) "Red"
        #   #   (fg blue)(still italic) "(blue)"
        #   #   (regular) "."
        def initialize(rules=nil, **opts)
            if rules.nil?
              rules = opts
              opts = {}
            end
            @base_rules = rules
            @base_rules[:reset] = @base_rules.fetch(:reset, DEFAULT_RESET_RULE)
            # binding.pry
            after = opts.fetch(:after, nil)
            after = DEFAULT_AFTER if after.nil? || (after.is_a?(Symbol) && !AFTER_PRESETS.has_key?(after))
            @default_after = (after.is_a?(Hash))? after : AFTER_PRESETS[after]
            sym_opts = opts.fetch(:symbols,{})
            @symbols = SymbolOptions.new(
              sym_opts.fetch(:open, DEFAULT_SYMBOLS[:open]),
              sym_opts.fetch(:close, DEFAULT_SYMBOLS[:close]),
              sym_opts.fetch(:reset, DEFAULT_SYMBOLS[:reset])
            )
            evaluate_rules
            build_regexs
        end

        ##
        # Apply styling to string using rule set
        # @param [String] text Text to parse for stylization
        # @return [String] Text with ANSI style codes injected
        def apply(text)
            raw = process_text(text)
            rule_stack = []
            str = ''
            rule_names = @rules.keys
            raw.each do |r|
              if r.is_a?(Symbol)
                # Part is a rule
                dprint "\tRule Symbol #{r}\n"
                if r == :close && rule_stack.length >= 1
                  # Rule close with 1+ opened rules
                  opened = rule_stack.pop
                  opened_after = @rules[opened].codes(Rule::Parts[:after])
                  dprint "\t\tClose, opened rule '#{opened}'\n"
                  dprint "\t\t\tClosing rule '#{opened}' with After\n"
                  dprint 4,"After: #{opened_after.inspect}\n"
                  str.concat(opened_after)
                  unless rule_stack.length == 0
                    rule_stack.each do |outer|
                      outer_inside = @rules[outer].codes(Rule::Parts[:inside])
                      # Closed rule was nested in another open rule
                      dprint 3, "Outer rule '#{outer}' still open. Restoring Inside\n"
                      dprint 4, "Inside: #{outer_inside.inspect}\n}"
                      str.concat(outer_inside)
                    end
                  end
                    # binding.pry
                    # outer = rule_stack[-1]
                    # outer_inside = @rules[outer].codes(Rule::Parts[:inside])
                    # # Closed rule was nested in another open rule
                    # dprint 3, "Outer rule '#{outer}' still open. Restoring Inside\n"
                    # dprint 4, "Inside: #{outer_inside.inspect}\n}"
                    # str.concat(outer_inside)
                    # # binding.pry
                  # end
                elsif r == :reset && rule_stack.length == 0
                  # no opened outer rules, reset symbol given
                  dprint "\t\tReset, no opened rule\n"
                  str.concat(@rules[r].codes(Rule::Parts[:after]))
                elsif rule_names.include?(r)
                  # New rule to apply
                  dprint "\t\tApplying new rule '#{r}'\n"
                  dprint 3, "Previous active rule `#{rule_stack[-1]}`\n"
                  rule_stack.push r
                  str.concat(@rules[r].codes(Rule::Parts[:inside]))
                end
              else
                # Part is text
                str.concat(r)
              end
            end
            str
        end

        ##
        # Wraps STDOUT print method, passing output of `apply` to `print`
        # @param [Array] args Print arguments, including TermColor style tags
        # @param [Hash] opts Optional params
        # @option opts [IO] :out Optional override for IO class to call `print`
        #   on (default `$stdout`)
        def print(*args,**opts)
            stdout = opts.fetch(:out, $stdout)
            t = args.map{|a|apply(a)}
            stdout.print *t
        end

        ##
        # Wraps STDOUT printf method, passing output of `apply` to `print`
        # Doesn't actually use `printf`, instead passes result of
        # `format_string % args` to `print`.
        # @param [String] format_string printf format string,
        #   including TermColor style tags
        # @param [Array] args printf values to use with format string
        # @param [Hash] opts Optional params
        # @option opts [IO] :out Optional override for IO class to call `print`
        #   on (default `$stdout`)
        def printf(format_string,*args,**opts)
            stdout = opts.fetch(:out, $stdout)

            # Sanitize rule symbols
            sanitized = format_string.dup
            @rules.keys.each { |k| sanitized.gsub!("#{@symbols.rule}#{k.to_s}","#{255.chr}#{k.to_s}") }
            sanitized.gsub!(@symbols.reset, 255.chr*2)

            t = sanitized % args
            # Reinstate rule symbols
            @rules.keys.each { |k| t.gsub!("#{255.chr}#{k.to_s}","#{@symbols.rule}#{k.to_s}") }
            t.gsub!(255.chr*2,@symbols.reset)

            stdout.print apply(t)
        end

        private

        def dprint(*v)
          if DBG
            if v.length == 2
              tc,t=v
              tabs = "\t" * tc
              print "#{tabs}#{t}"
            else
              print v[0]
            end
          end
        end

        def evaluate_rules
            @rules = {}
            @base_rules.each_pair do |k,v|
                @rules[k] = Rule.compile(v, self)
            end
        end

        def build_regexs
            @regexs = {}
            src = @rules
            src.each_pair do |k,v|
                @regexs[k] = Regexp.compile(
                    "(?<#{k.to_s}>(#{@symbols.open}#{k.to_s}))"
                )
            end
            @regexs[:close] = Regexp.compile(
                "(?<default>(#{@symbols.close}))"
            )
            @regexs[:reset] = Regexp.compile(
                "(?<default>(#{@symbols.reset}))"
            )
        end

        def locate_rules_in_string(text)
            tracking = {}
            @regexs.keys.each do |k|
                tracking[k] = {index: 0, done: false}
            end
            tracking_done = Proc.new {
                tracking.values.select{|t|!t[:done]}.length == 0
            }
            is_done = false

            locations = []
            # binding.pry
            until is_done do
                @regexs.each_pair do |k,v|
                    t = tracking[k]
                    # print "Tracking #{k} (#{t})\n"
                    unless t[:done]
                        m = v.match(text,t[:index])
                        if m.nil?
                            # print "No matches found\n"
                            tracking[k][:done] = true
                        else
                            tracking[k][:index] = m.end(0)
                            a=m.begin(0);b=m.end(0)
                            locations << {
                                symbol: k,
                                begin: a,
                                sym_end: b - 1,
                                continue_pos: b
                            }
                            # print "\tMatch found (#{a}..#{b}): #{text[a..b]}\n"
                        end
                    end
                end
                is_done = tracking_done.call()
            end
            locations.sort{|a,b|a[:continue_pos]<=>b[:continue_pos]}
        end

        def process_text(text)
            locations = locate_rules_in_string(text)

            working = []
            return [text] if locations.length == 0

            if locations[0][:begin] > 0
                working << text[0..locations[0][:begin]-1]
            end

            locations.each_with_index do |l,i|
                is_last = locations.length - 1 - i == 0
                end_pos = -1
                if !is_last
                    end_pos = locations[i+1][:begin] - 1
                end

                working << l[:symbol]
                working << text[l[:continue_pos]..end_pos]
            end
            working
        end

    end
end
