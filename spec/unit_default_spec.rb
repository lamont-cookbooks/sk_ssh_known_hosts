require 'spec_helper'

describe "unit::default" do
  let(:runner) do
    ChefSpec::Runner.new(
      step_into: 'sk_s3_file',
      platform: 'ubuntu',
      version: "13.04",
    )
  end

  let(:test) { runner.converge(described_recipe) }

  it "calls sk_s3_file" do
    expect(test).to create_template("ssh_known_hosts_template_file")
  end
end
