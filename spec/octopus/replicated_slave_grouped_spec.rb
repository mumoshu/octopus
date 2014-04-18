require "spec_helper"

describe "when the database is replicated and has slave groups" do

  it "should pick the slave group based on current_slave_grup when you have a replicated model" do

    OctopusHelper.using_environment :replicated_slave_grouped do
      # The following two calls of `create!` both creates cats in :master(The database `octopus_shard_1`)
      # which is configured through RAILS_ENV and database.yml
      Cat.create!(:name => "Thiago1")
      Cat.create!(:name => "Thiago2")

      # See "replicated_slave_grouped" defined in shards.yml
      # We have:
      #   The database `octopus_shard_1` as :slave21 which is a member of the slave group :slaves2, and as :master
      #   The databse `octopus_shard_2` as :slave11 which is a member of the slave group :slaves1
      # When a select-count query is sent to `octopus_shard_1`, it should return 2 because we have create two cats in :master .
      # When a select-count query is sent to `octopus_shard_2`, it should return 0.

      # The query goes to `octopus_shard_1`
      Cat.using(:master).count.should == 2
      # The query goes to `octopus_shard_1`
      Cat.count.should == 2
      # The query goes to `octopus_shard_2`
      Cat.using(slave_group: :slaves1).count.should == 0
      # The query goes to `octopus_shard_1`
      Cat.using(slave_group: :slaves2).count.should == 2
    end
  end

  it "should distribute queries between slaves in a slave group in round-robin" do
    OctopusHelper.using_environment :replicated_slave_grouped do
      # The query goes to :master(`octopus_shard_1`)
      Cat.create!(:name => "Thiago1")
      # The query goes to :master(`octopus_shard_1`)
      Cat.create!(:name => "Thiago2")

      # The query goes to :slave32(`octopus_shard_2`)
      Cat.using(slave_group: :slaves3).count.should == 0
      # The query goes to :slave31(`octopus_shard_1`)
      Cat.using(slave_group: :slaves3).count.should == 2
      # The query goes to :slave32(`octopus_shard_2`)
      Cat.using(slave_group: :slaves3).count.should == 0
    end
  end
end
