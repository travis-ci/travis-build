shared_examples_for 'build script stages' do
  def assert_stage?(stage)
    %w(before_install install before_script).include?(stage)
  end

  %w(before_install install before_script script after_script after_success).each do |stage|
    before :each do
      data[:config][stage] = ["#{stage}.1.sh", "#{stage}.2.sh"]
    end

    1.upto(2) do |num|
      it "runs the given :#{stage} script #{stage}.#{num}.sh" do
        options = { echo: true, timing: true }
        options[:assert] = true if assert_stage?(stage)
        should include_sexp [:cmd, "#{stage}.#{num}.sh", options]
      end
    end

    next if stage == 'script'

    1.upto(2) do |num|
      it "adds a fold marker for the :#{stage} script #{num}" do
        expect(sexp_find(subject, [:fold, "#{stage}.#{num}"])).to_not be_empty
      end
    end
  end
end
