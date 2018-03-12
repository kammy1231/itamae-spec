require 'spec_helper'

describe file('/tmp/sample') do
  it { should be_file }
  it { should be_mode 755 }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  its(:content) { should match /This is a sample./ }
end
