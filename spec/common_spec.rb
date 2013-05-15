require 'spec_helper'

describe LinuxAdmin::Common do
  context ".sanitize" do
    it "with string input" do
      expect(described_class.sanitize("some long   string here ")).to eq("some long string here")
    end

    it "with array input" do
      expect(described_class.sanitize(["letters a", "b", nil, [[nil], [[["c"]]]]])).to eq("letters a b c")
    end
  end

  context ".write" do
    it "no file no content" do
      expect { described_class.write("", "") }.to raise_error(ArgumentError)
    end
  end

  context ".run" do
    it "command ok exit ok" do
      expect(described_class.run("true")).to be_true
    end

    it "command ok exit bad" do
      expect { described_class.run("false") }.to raise_error
    end

    it "command bad" do
      expect { described_class.run("XXXXX") }.to raise_error
    end

    context "with :return_exitstatus => true" do
      it "command ok exit ok" do
        expect(described_class.run("true", :return_exitstatus => true)).to eq(0)
      end

      it "command ok exit bad" do
        expect(described_class.run("false", :return_exitstatus => true)).to eq(1)
      end

      it "command bad" do
        expect(described_class.run("XXXXX", :return_exitstatus => true)).to be_nil
      end
    end

    context "with :return_output => true" do
      it "command ok exit ok" do
        expect(described_class.run("echo \"Hello World\"", :return_output => true)).to eq("Hello World\n")
      end

      it "command ok exit bad" do
        expect { described_class.run("false", :return_output => true) }.to raise_error
      end

      it "command bad" do
        expect { described_class.run("XXXXX", :return_output => true) }.to raise_error
      end
    end
  end
end