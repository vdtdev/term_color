rule_ref = TermColor::Rule

RSpec.describe "TermColor::Rule" do
    before(:all) do
        @rs = TermColor::RuleSet.new({})
        @colors = rule_ref::Colors
        @targets = rule_ref::ColorTargets
        @styles = rule_ref::Styles
        @actions = rule_ref::StyleActions
        @resets = rule_ref::Resets
        @xt_target = rule_ref::XTERM_COLOR_TARGET
        @xt_256 = rule_ref::XTERM_COLOR_256
        @xt_16m = rule_ref::XTERM_COLOR_16M
    end
    context "compiled using compile" do
        context "with basic, preset flat rule" do
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
    context "setting single property for" do
        context "color" do
            context "to named color" do
                it "is applied to fg" do
                    @colors.keys.each do |ck|
                        # Color code targetting FG
                        c_code = @targets[:fg] + @colors[ck]
                        # FG Reset code
                        r_code = @resets[:fg]
                        rs = TermColor.create_rule_set(ctest: {
                            fg: ck
                        })
                        a_txt = rs.apply('test{%ctestTEXT%}')
                        idx = a_txt.index('TEXT')
                        pre_txt = a_txt[0..idx-1] # rule start coe
                        post_txt = a_txt[idx..-1] # rule reset code
                        pre_code = pre_txt[-(c_code.to_s.length + 1)..-1]
                        expect(pre_code).to eq "#{c_code}m"
                        post_code = post_txt[-(r_code.to_s.length + 1)..-1]
                        expect(post_code).to eq "#{r_code}m"
                    end
                end
                it "is applied to bg" do
                    @colors.keys.each do |ck|
                        # Color code targetting BG
                        c_code = @targets[:bg] + @colors[ck]
                        # BG Reset code
                        r_code = @resets[:bg]
                        rs = TermColor.create_rule_set(ctest: {
                            bg: ck
                        })
                        a_txt = rs.apply('test{%ctestTEXT%}')
                        idx = a_txt.index('TEXT')
                        pre_txt = a_txt[0..idx-1] # rule start coe
                        post_txt = a_txt[idx..-1] # rule reset code
                        pre_code = pre_txt[-(c_code.to_s.length + 1)..-1]
                        expect(pre_code).to eq "#{c_code}m"
                        post_code = post_txt[-(r_code.to_s.length + 1)..-1]
                        expect(post_code).to eq "#{r_code}m"
                    end
                end
            end
            # TODO: test x256 and x16M colors
        end

        context "text style" do
            context "for AUTO after mode" do
                it "enables and resets styles" do
                    @styles.keys.each do |sk|
                        # style enable code
                        s_on_code = @actions[:enable] + @styles[sk]
                        # style disable code (using style disable 
                        # min code as min style code to add to style disable code)
                        s_off_code = @actions[:disable] + [@styles[sk], rule_ref::StyleDisableMinimumCode].max
                        rs = TermColor.create_rule_set({
                            r: { enable: sk }
                        })
                        a_txt = rs.apply('test{%rTEXT%}')
                        idx = a_txt.index('TEXT')
                        # applied rule starting code text
                        pre_txt = a_txt[0..idx-1]
                        # applied rule reset code text
                        post_txt = a_txt[idx..-1]
                        # applied starting code
                        pre_code = pre_txt[-(s_on_code.to_s.length + 1)..]
                        # applied reset code
                        post_code = post_txt[-(s_off_code.to_s.length + 1)..]
                        expect(pre_code).to eq "#{s_on_code}m"
                        expect(post_code).to eq "#{s_off_code}m"
                    end
                end
            end
            context "for RESET after mode" do
                before :all do
                    rules = {}
                    @styles.keys.each do |sk|
                        rule_basic = { enable: sk }
                        rule_override = { enable: sk, after: { keep: :style } }
                        rules[sk] = rule_basic
                        rules["#{sk.to_s}_override".to_sym] = rule_override
                    end
                    @rs = TermColor.create_rule_set(
                        rules,
                        after: :reset
                    )
                end
                
                it "enables and resets styles using default after" do
                    @styles.keys.each do |sk|
                        rule_name = sk.to_s
                        post_code = [@actions[:disable] + @styles[sk], @actions[:disable] + rule_ref::StyleDisableMinimumCode].max
                        t = "test{%#{rule_name}TEXT%}"
                        a_txt = @rs.apply(t)
                        idx = a_txt.index('TEXT')
                        pre = a_txt[0..idx-1]
                        post = a_txt[idx..]
                        expect(pre).to match(Regexp.new("#{@styles[sk]}m"))
                        expect(post).to match(Regexp.new("#{post_code}m"))
                    end
                end

                it "enables and resets styles using custom after" do
                    @styles.keys.each do |sk|
                        @styles.keys.each do |sk|
                            rule_name = "#{sk.to_s}_override"
                            post_code = [@actions[:disable] + @styles[sk], @actions[:disable] + rule_ref::StyleDisableMinimumCode].max
                            t = "test{%#{rule_name}TEXT%}"
                            a_txt = @rs.apply(t)
                            idx = a_txt.index('TEXT')
                            pre = a_txt[0..idx-1]
                            post = a_txt[idx..]
                            expect(pre).to match(Regexp.new("#{@styles[sk]}m"))
                            expect(post).to_not match(Regexp.new("#{post_code}m"))
                        end
                    end
                end
                
            end
        end
    end

end