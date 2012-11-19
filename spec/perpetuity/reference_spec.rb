require 'perpetuity/reference'

module Perpetuity
  describe Reference do
    let(:reference) { Reference.new Object, 1 }
    subject { reference }

    its(:klass) { should be Object }
    its(:id)    { should be == 1 }

    describe 'comparability' do
      describe 'equality' do
        let(:duplicate) { reference.dup }
        it { should be == duplicate }
        it { should eql duplicate }
      end

      describe 'inequality' do
        it { should_not be == Reference.new(String, reference.id) }
        it { should_not eql Reference.new(String, reference.id) }
        it { should_not be == Reference.new(reference.klass, 2) }
        it { should_not eql Reference.new(reference.klass, 2) }
      end
    end
  end
end
