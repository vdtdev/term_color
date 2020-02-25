module TermColor
    ##
    # TermColor style rule setc class
    # @author Wade H. <vdtdev.prod@gmail.com>
    # @license MIT
    class RuleSet

        ##
        # Symbol used as prefix for rule name to denote rule start
        RULE_SYMBOL='%'
        ##
        # String used to denote rule close / reset
        RESET_SYMBOL='%%'

        DEFAULT_RESET_RULE = {z: {reset: :all} }

        attr_reader :rules, :regexs

        ##
        # Construct new rule set
        # @param [Hash] rules Hash of rule names mapping to rule hashes,
        #   which can define before rules (`a:`), after rules (`z:`) or both.
        #   - If neither are given, content is treated as though it was inside a `a:` key.
        #   - If `a:` only is given, {TermColor::Rule#evaluate Rule evaluate method} attempts to
        #       auto guess `z:`, resetting any used color or style rules from `a:`
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
        #       weird: { a: { fg: :red }, z: { fg: :blue }}
        #   })
        #
        #   print rules.colorize("%nameJohn%%: '%%quoteRoses are %%weirdRed%% (blue)%%.\n")
        #   # Result will be:
        #   #   fg green+underline "John"
        #   #   regular ":  "
        #   #   italic "Roses are "
        #   #   fg red (still italic) "Red"
        #   #   (fg blue)(still italic) "(blue)"
        #   #   (regular) "."
        def initialize(rules)
            @base_rules = rules
            @base_rules[:default] = @base_rules.fetch(:default, DEFAULT_RESET_RULE)
            evaluate_rules
            build_regexs
        end

        ##
        # Colorize string using rule set
        # @param [String] text Text to colorize
        # @return [String] Text with ANSI color codes injected
        def colorize(text)
            raw = process_text(text)
            last_rule = nil
            str = ''
            raw.each do |r|
                if r.is_a?(Symbol)
                    # if (r == :close_rule && !last_rule.nil?)
                    #     str.concat(Rule.codes(@rules[last_rule][:z]))
                    #     last_rule = nil
                    # elsif  r == :default
                    #     str.concat(Rule.codes(@rules[r][:z]))
                    #     last_rule = nil
                    # else
                    #     last_rule = r
                    #     str.concat(Rule.codes(@rules[r][:a]))
                    # end
                    if (r == :default) && !last_rule.nil?
                        str.concat(Rule.codes(@rules[last_rule][:z]))
                        last_rule = nil
                    elsif  r == :default
                        str.concat(Rule.codes(@rules[r][:z]))
                        last_rule = nil
                    else
                        last_rule = r
                        str.concat(Rule.codes(@rules[r][:a]))
                    end
                else
                    str.concat(r)
                end
            end
            str
        end

        private

        def evaluate_rules
            @rules = {}
            @base_rules.each_pair do |k,v|
                @rules[k] = Rule.evaluate(v)
            end
        end

        def build_regexs
            @regexs = {}
            src = @rules
            src.each_pair do |k,v|
                @regexs[k] = Regexp.compile(
                    "(?<#{k.to_s}>(#{RULE_SYMBOL}#{k.to_s}))"
                )
            end
            @regexs[:default] = Regexp.compile(
                "(?<default>(#{RESET_SYMBOL}))"
            )
            @regexs[:close_rule] = Regexp.compile(
                "(?<close_rule>(#{CLOSE_SYMBOL}))"
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