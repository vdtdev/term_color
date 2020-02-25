require_relative './term_color/rule.rb'
require_relative './term_color/rule_set.rb'
##
# Main TermColor module
# @author Wade H. <vdtdev.prod@gmail.com>
# @license MIT
module TermColor
    extend self

    ##
    # Alias for constructing a new RuleSet
    # @see TermColor::RuleSet
    def create_rule_set(rules={})
        TermColor::RuleSet.new(rules)
    end

end