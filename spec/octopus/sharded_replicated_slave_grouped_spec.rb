require "spec_helper"

describe "when the database is both sharded and replicated" do
  before(:each) do
    Octopus.stub(:env).and_return("sharded_replicated_slave_grouped")
    OctopusHelper.clean_connection_proxy()
  end

  it "should not send all queries to the specified slave" do
    pending()
    # User.create!(:name => "Thiago")
    #
    # using_environment :not_entire_sharded do
    #   Octopus.using(:russia) do
    #     User.create!(:name => "Thiago")
    #   end
    # end
    #
    # User.count.should == 2
  end

  it "should pick the shard based on current_shard when you have a sharded model" do
    Cat.create!(:name => "Thiago1")

    OctopusHelper.using_environment :sharded_replicated_slave_grouped do
      Octopus.using(:russia) do
        Cat.create!(:name => "Thiago2")
      end
    end

    # We must stub here to make it effective (not in the `before(:each)` block)
    Octopus.stub(:env).and_return("sharded_replicated_slave_grouped")

    Cat.using(:russia).count.should == 2
    Cat.using(shard: :russia, slave_group: :slaves1).count.should == 0
    Cat.using(shard: :russia, slave_group: :slaves2).count.should == 0

    Cat.using(:europe).count.should == 0
    Cat.using(shard: :europe, slave_group: :slaves1)
      .count.should == 0
    Cat.using(shard: :europe, slave_group: :slaves2)
      .count.should == 2
  end
end
