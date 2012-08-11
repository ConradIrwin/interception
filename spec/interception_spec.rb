describe Interception do

  before do
    @exceptions = []
    Interception.listen do |e, b|
      @exceptions << [e, b]
    end
  end

  after do
    Interception.listeners.each do |l|
      Interception.unlisten l
    end
  end

  it "should allow keeping a log of all exceptions raised" do
    begin
      raise "foo"
    rescue => e
      #
    end

    @exceptions.map(&:first).should == [e]
  end
end
