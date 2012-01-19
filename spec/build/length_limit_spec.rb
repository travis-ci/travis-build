require 'spec_helper'
require 'travis/build/length_limit'

describe "Output length limit helper" do
  context "with the limit of 100" do
    subject do
      Travis::Build::LengthLimit.of(100)
    end

    context "originally" do
      it "is not hit" do
        subject.should_not be_hit
        subject.length.should == 0
      end
    end


    it "is not reached after 4 updates 20 bytes of output each" do
      subject.should_not be_hit

      subject.update("a" * 20)
      subject.should_not be_hit

      subject.update("a" * 20)
      subject.should_not be_hit

      subject.update("a" * 20)
      subject.should_not be_hit

      subject.update("a" * 20)
      subject.should_not be_hit

      subject.length.should == 80
    end

    it "is not reached after 3 updates 30 bytes of output each" do
      subject.should_not be_hit

      subject.update("a" * 30)
      subject.should_not be_hit

      subject.update("a" * 30)
      subject.should_not be_hit

      subject.update("a" * 30)
      subject.should_not be_hit
    end

    it "is not reached after 1 update 99 bytes of output each" do
      subject.should_not be_hit

      subject.update("a" * 99)
      subject.should_not be_hit
    end

    it "is reached after 5 updates 20 bytes of output each" do
      subject.should_not be_hit

      4.times do
        subject.update("a" * 20)
        subject.should_not be_hit
      end

      subject.update("a" * 20)
      subject.should be_hit
    end

    it "is reached after 2 updates 100 bytes of output each" do
      subject.should_not be_hit

      subject.update("a" * 100)
      subject.should be_hit

      subject.update("a" * 20)
      subject.should be_hit
    end

    it "is reached after 16 updates 1024 * 1024 bytes of output each" do
      subject.should_not be_hit

      16.times { subject.update("a" * (1024 * 1024)) }
      subject.should be_hit
    end
  end
end
