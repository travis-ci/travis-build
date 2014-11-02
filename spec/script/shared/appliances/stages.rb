shared_examples_for 'build script stages' do
  %w(before_install install before_script script after_script after_success).each do |script|
    it "runs the given :#{script} command" do
      data[:config][script] = script
      assert = %w(before_install install before_script).include?(script)
      options = { assert: assert, echo: true, timing: true }.select { |_, value| value }
      should include_sexp [:cmd, script, options]
    end

    next if script == 'script'

    it "adds fold markers for each of the :#{script} commands" do
      data[:config][script] = [script, script]
      expect(!!sexp_find(subject, [:fold, "#{script}.2"])).to eql(true)
    end
  end
end
