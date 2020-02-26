rule_ref = TermColor::Rule

RSpec.describe "TermColor::RuleSet" do
    before(:all) do
        @colors = rule_ref::Colors
        @targets = rule_ref::ColorTargets
        @styles = rule_ref::Styles
        @actions = rule_ref::StyleActions
        @xt_target = rule_ref::XTERM_COLOR_TARGET
        @xt_256 = rule_ref::XTERM_COLOR_256
        @xt_16m = rule_ref::XTERM_COLOR_16M
    end
    
    context "constructor" do
        before(:each) do
            @rules = {
                a: { fg: :red, enable: :italic },
                b: { fg: :red, enable: [:italic,:bold], after: { fg: :yellow} },
                c: { inside: { fg: :red, enable: [:italic,:bold] }, after: { fg: :yellow} }
            }
        end
        it "builds hash of compiled rules including all keys" do
            set = TermColor::RuleSet.new(@rules)
            expect(set.rules.keys).to match_array(@rules.keys)
        end
    end

end