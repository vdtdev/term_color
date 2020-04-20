rule_ref = TermColor::Rule

RSpec.describe "TermColor::Rule" do
    before(:all) do
        @rs = TermColor::RuleSet.new({})
        @colors = rule_ref::Colors
        @targets = rule_ref::ColorTargets
        @styles = rule_ref::Styles
        @actions = rule_ref::StyleActions
        @xt_target = rule_ref::XTERM_COLOR_TARGET
        @xt_256 = rule_ref::XTERM_COLOR_256
        @xt_16m = rule_ref::XTERM_COLOR_16M
    end
    context "compiled using compile" do
        context "with basic flat rule" do
            context "evaulated property" do
                before(:each) do
                    @rule = { fg: :red, bg: :blue, enable: [:italic, :dim] }
                    @compiled = TermColor::Rule.compile(@rule,@rs)
                end
                it "has :inside" do
                    expect(@compiled.evaluated[:inside]).not_to be_nil
                end
                
                context "with standard colors" do
                    it "applies fg" do
                        expect(@compiled.evaluated[:inside]).to include(
                            rule_ref::ColorTargets[:fg] + rule_ref::Colors[@rule[:fg]]
                        )
                    end
                    it "applies bg" do
                        expect(@compiled.evaluated[:inside]).to include(
                            rule_ref::ColorTargets[:bg] + rule_ref::Colors[@rule[:bg]]
                        )
                    end
                end

                context "with XTerm 256 colors" do
                    before(:each) do
                        @rule2 = @rule.merge({ fg: [208], bg: [209] })
                        @comp2 = TermColor::Rule.compile(@rule2,@rs)
                    end
                    it "applies fg" do
                        expect(@comp2.evaluated[:inside]).to include(
                            [
                                rule_ref::ColorTargets[:fg] + rule_ref::XTERM_COLOR_TARGET,
                                rule_ref::XTERM_COLOR_256,
                                @rule2[:fg][0]
                            ].join(';')
                        )
                    end
                    it "applies bg" do
                        expect(@comp2.evaluated[:inside]).to include(
                            [
                                rule_ref::ColorTargets[:bg] + rule_ref::XTERM_COLOR_TARGET,
                                rule_ref::XTERM_COLOR_256,
                                @rule2[:bg][0]
                            ].join(';')
                        )
                    end
                end

                context "with XTerm 16m colors" do
                    before(:each) do
                        @rule2 = @rule.merge({ fg: [30,80,128], bg: [30,80,128] })
                        @comp2 = TermColor::Rule.compile(@rule2, @rs)
                    end
                    it "applies fg" do
                        expect(@comp2.evaluated[:inside]).to include(
                            [
                                rule_ref::ColorTargets[:fg] + rule_ref::XTERM_COLOR_TARGET,
                                rule_ref::XTERM_COLOR_16M,
                                @rule2[:fg]
                            ].flatten.join(';')
                        )
                    end
                    it "applies bg" do
                        expect(@comp2.evaluated[:inside]).to include(
                            [
                                rule_ref::ColorTargets[:bg] + rule_ref::XTERM_COLOR_TARGET,
                                rule_ref::XTERM_COLOR_16M,
                                @rule2[:bg]
                            ].flatten.join(';')
                        )
                    end
                end
                
                it "enables styles" do
                    @rule[:enable].each do |s|
                        expect(@compiled.evaluated[:inside]).to include(
                            rule_ref::StyleActions[:enable] + rule_ref::Styles[s]
                        )
                    end
                end

                it "generates correct :after" do
                    eval_after = @compiled.evaluated[:after]
                    codes = [
                        rule_ref::Resets[:fg],
                        rule_ref::Resets[:bg],
                        @rule[:enable].map {|v| @actions[:disable] + @styles[v]}
                    ].flatten
                    expect(eval_after).to match_array(codes)
                end
            end
            context "codes method" do
                before(:each) do
                    @rule = {
                        fg: :red, bg: [128,64,0],
                        enable: :italic
                    }
                    @compiled = TermColor::Rule::compile(@rule, @rs)
                end
                it "includes expected :inside codes" do
                    codes = @compiled.codes(:inside)
                    
                    [
                        "\e[#{@targets[:fg]+@colors[:red]}m",
                        "\e[#{@targets[:bg]+@xt_target};#{@xt_16m};#{@rule[:bg].join(';')}m",
                        "\e[#{@actions[:enable]+@styles[@rule[:enable]]}m"
                    ].each do |code|
                        expect(codes).to include(code)
                    end
                end
            end
        end
    end

end