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

  it "should be able to listen for the duration of a block" do

    e1, e2 = nil
    block = proc{
      begin
        raise "foo"
      rescue => e1
        #
      end
    }
    Interception.listen(block) do |e, b|
      e2 = e
    end

    e1.should == e2
  end

  it "should allow nested calls to listen with a block" do
    e1, e2 = nil
    b1, b2 = nil
    block = proc{
      begin
        raise "foo"
      rescue => e1
        #
      end
    }
    block2 = proc{
      Interception.listen(block) do |e, b|
        e2 = e
        b1 = b
      end
    }
    Interception.listen(block2) do |e, b|
      b2 = b
    end

    e1.should == e2
    b1.should == b2
  end

  it "should be able to handle NoMethodErrors" do
    shoulder = :bucket

    begin
      line = __LINE__; "snorkle".desnrok
    rescue => e1
      #
    end

    @exceptions.map{ |e, b| [e] + b.eval('[__LINE__, shoulder]') }.should == [[e1, line, :bucket]]
    e1.message.should =~ /desnrok/
  end

  it "should be able to handle division by 0 errors" do
    shoulder = :bucket

    begin
      line = __LINE__; 1 / 0
    rescue => e1
      #
    end

    @exceptions.map{ |e, b| [e] + b.eval('[__LINE__, shoulder]') }.should == [[e1, line, :bucket]]
    ZeroDivisionError.should === e1
  end
end
