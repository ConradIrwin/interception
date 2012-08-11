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

  it "should catch the correct binding" do
    shoulder = :bucket
    begin
      raise "foo"
    rescue => e
      #
    end

    @exceptions.map{ |e, b| b.eval('shoulder') }.should == [:bucket]
  end

  it "should catch the binding on the correct line" do
    shoulder = :bucket

    line = nil
    begin
      line = __LINE__; raise "foo"
    rescue => e
      #
    end

    @exceptions.map{ |e, b| b.eval('__LINE__') }.should == [line]
  end

  it "should catch all nested exceptions" do

    begin
      begin
        raise "foo"
      rescue => e1
        raise "bar"
      end
    rescue => e2
      #
    end

    @exceptions.map(&:first).should == [e1, e2]
  end
end
