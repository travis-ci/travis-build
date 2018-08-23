shared_examples_for 'update libssl1.0.0' do
  let(:update_libssl) { "apt-get install ca-certificates libssl1.0.0" }

  context "when sudo is available" do
    it "does not update libssl1.0.0" do
      should_not include_sexp [:cmd, update_libssl, sudo: true, echo: true]
    end
  end
  context "when sudo is unavailable" do
    before :each do
      data[:paranoid] = true
    end

    context "on Precise" do
      let(:sexp) { sexp_find(subject, [:if, "-n $(command -v lsb_release) && $(lsb_release -cs) = 'precise'"]) }

      it 'updates libssl1.0.0' do
        expect(sexp).to include_sexp [:cmd, update_libssl, sudo: true, echo: true]
      end
    end

  end
end
